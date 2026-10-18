'use strict';

const express = require('express');
const http    = require('http');
const { WebSocketServer, WebSocket } = require('ws');
const cors    = require('cors');

// ─────────────────────────────────────────────────────────────────────────────
// Config
// ─────────────────────────────────────────────────────────────────────────────
const PORT               = process.env.PORT || 3000;
const MAX_MSG_BYTES      = 8 * 1024;          // 8 KB – reject oversized messages
const RATE_LIMIT_WINDOW  = 1000;              // ms
const RATE_LIMIT_MAX     = 20;               // events per window per client
const HEARTBEAT_INTERVAL = 25_000;           // ms – keep Render connections alive
const STALE_ROOM_TTL     = 30 * 60 * 1000;  // 30 min – GC finished/empty rooms
const NAME_MAX_LEN       = 32;
const ROOM_NAME_MAX_LEN  = 48;

// ─────────────────────────────────────────────────────────────────────────────
// Express + HTTP
// ─────────────────────────────────────────────────────────────────────────────
const app = express();
app.use(cors());
app.use(express.json({ limit: '16kb' }));

const server = http.createServer(app);

// ─────────────────────────────────────────────────────────────────────────────
// In-memory state
// ─────────────────────────────────────────────────────────────────────────────
const rooms = {};
const clients = new Map();

// ─────────────────────────────────────────────────────────────────────────────
// Card definitions
// ─────────────────────────────────────────────────────────────────────────────
const SUITS = ['Spades', 'Hearts', 'Diamonds', 'Clubs'];
const CARD_NAMES = { 11: 'J', 12: 'Q', 13: 'K', 14: 'A' };

// ─────────────────────────────────────────────────────────────────────────────
// Logging
// ─────────────────────────────────────────────────────────────────────────────
function log(level, msg, meta = {}) {
  const ts = new Date().toISOString();
  const metaStr = Object.keys(meta).length ? ' ' + JSON.stringify(meta) : '';
  const out = `[${ts}] [${level.toUpperCase()}] ${msg}${metaStr}`;
  if (level === 'error') console.error(out); else console.log(out);
}

// ─────────────────────────────────────────────────────────────────────────────
// HTTP endpoints
// ─────────────────────────────────────────────────────────────────────────────
app.get('/', (_req, res) => res.send('Wizard Official Card Game Server is running!'));

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', uptime: process.uptime(), rooms: Object.keys(rooms).length, clients: clients.size, ts: new Date().toISOString() });
});

app.get('/stats', (_req, res) => {
  const waiting  = Object.values(rooms).filter(r => r.status === 'WAITING').length;
  const playing  = Object.values(rooms).filter(r => r.status === 'PLAYING').length;
  const finished = Object.values(rooms).filter(r => r.status === 'FINISHED').length;
  res.json({ clients: clients.size, rooms: { total: Object.keys(rooms).length, waiting, playing, finished }, memory: process.memoryUsage() });
});

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────
function sanitize(str, maxLen = NAME_MAX_LEN) {
  if (typeof str !== 'string') return '';
  return str.trim().slice(0, maxLen).replace(/[<>&"']/g, '');
}

function newRoomId() {
  let id;
  do {
    // Generate clean 6-character room code, e.g. "WZ8421"
    id = 'WZ' + Math.floor(1000 + Math.random() * 9000);
  } while (rooms[id]);
  return id;
}

function newClientId() { return 'player_' + Math.random().toString(36).substring(2, 9); }

function getTotalRounds(n) { return ({ 3: 20, 4: 15, 5: 12, 6: 10, 7: 8, 8: 7 })[n] ?? Math.floor(60 / n); }

function getLobbyRooms() {
  return Object.values(rooms)
    .filter(r => r.status === 'WAITING' && r.players.length < r.maxPlayers)
    .map(r => ({ id: r.id, name: r.name, hostId: r.hostId, maxPlayers: r.maxPlayers, playerCount: r.players.length, status: r.status, players: r.players.map(p => ({ id: p.id, name: p.name, score: p.score, isHost: p.isHost })) }));
}

// ─────────────────────────────────────────────────────────────────────────────
// Send / Broadcast
// ─────────────────────────────────────────────────────────────────────────────
function sendTo(ws, event, data) {
  if (ws && ws.readyState === WebSocket.OPEN) {
    try { ws.send(JSON.stringify({ event, data: data ?? {} })); }
    catch (e) { log('error', 'sendTo failed', { event, err: e.message }); }
  }
}

function broadcastToRoom(roomId, event) {
  const room = rooms[roomId];
  if (!room) return;
  for (const [ws, info] of clients.entries()) {
    if (ws.readyState !== WebSocket.OPEN || info.roomId !== roomId) continue;
    const sanitizedPlayers = room.players.map(p =>
      p.id === info.id
        ? { ...p }
        : { ...p, hand: p.hand.map(() => ({ id: 'hidden', suit: 'Hidden', value: 0, name: 'Card', type: 'HIDDEN' })) }
    );
    sendTo(ws, event, { ...room, players: sanitizedPlayers });
  }
}

// Only send lobby updates to clients NOT inside a room (avoids O(n) fan-out to in-game players)
function broadcastLobbyUpdate() {
  const data = getLobbyRooms();
  for (const [ws, info] of clients.entries()) {
    if (ws.readyState === WebSocket.OPEN && !info.roomId) sendTo(ws, 'rooms_updated', data);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Deck generation
// ─────────────────────────────────────────────────────────────────────────────
function generateWizardDeck() {
  const deck = []; let n = 1;
  const sym = { Spades: '♠', Hearts: '♥', Diamonds: '♦', Clubs: '♣' };
  for (const suit of SUITS) for (let v = 2; v <= 14; v++) deck.push({ id: `card_${n++}`, suit, value: v, name: `${CARD_NAMES[v] ?? v} ${sym[suit]}`, type: 'NORMAL' });
  for (let w = 1; w <= 4; w++) deck.push({ id: `wizard_${w}`, suit: 'Wizard', value: 99, name: 'Wizard 🧙‍♂️', type: 'WIZARD' });
  for (let j = 1; j <= 4; j++) deck.push({ id: `jester_${j}`, suit: 'Jester', value: 0,  name: 'Jester 🃏',   type: 'JESTER' });
  for (let i = deck.length - 1; i > 0; i--) { const r = Math.floor(Math.random() * (i + 1)); [deck[i], deck[r]] = [deck[r], deck[i]]; }
  return deck;
}

// ─────────────────────────────────────────────────────────────────────────────
// Game logic
// ─────────────────────────────────────────────────────────────────────────────
function startNewRound(room, roundNumber) {
  const deck = generateWizardDeck();
  const pc   = room.players.length;
  room.gameState.round = roundNumber;
  room.gameState.phase = 'BIDDING';
  room.gameState.playedCards = [];
  room.gameState.ledSuit = null;
  room.gameState.trickWinnerName = null;

  for (let i = 0; i < pc; i++) {
    const p = room.players[i];
    p.hand = deck.slice(i * roundNumber, (i + 1) * roundNumber);
    p.bid = null; p.tricksWon = 0;
    p.isDealer = (i === room.gameState.dealerIndex);
  }

  const trumpIdx = pc * roundNumber;
  const isFinal  = (pc <= 6 && roundNumber === room.gameState.totalRounds);
  if (isFinal) {
    room.gameState.trumpCard = null; room.gameState.trumpSuit = null;
    log('info', `Round ${roundNumber} – Final: No Trump`);
  } else {
    const tc = deck[trumpIdx]; room.gameState.trumpCard = tc;
    if (tc.type === 'NORMAL')  room.gameState.trumpSuit = tc.suit;
    else if (tc.type === 'JESTER') room.gameState.trumpSuit = null;
    else room.gameState.trumpSuit = 'Spades'; // Wizard – dealer picks, default
    log('info', `Round ${roundNumber} – Trump: ${tc.name} → ${room.gameState.trumpSuit ?? 'None'}`);
  }
  room.gameState.currentTurnIndex = (room.gameState.dealerIndex + 1) % pc;
}

function determineTrickWinner(played, trumpSuit, ledSuit) {
  for (const item of played) if (item.card.type === 'WIZARD') return item;
  if (trumpSuit) {
    const t = played.filter(c => c.card.type === 'NORMAL' && c.card.suit === trumpSuit);
    if (t.length) return t.reduce((a, b) => b.card.value > a.card.value ? b : a);
  }
  if (ledSuit) {
    const l = played.filter(c => c.card.type === 'NORMAL' && c.card.suit === ledSuit);
    if (l.length) return l.reduce((a, b) => b.card.value > a.card.value ? b : a);
  }
  return played[0];
}

function handleRoundOver(room) {
  const scores = [];
  for (const p of room.players) {
    const bid = p.bid ?? 0; const w = p.tricksWon;
    const pts = w === bid ? 20 + w * 10 : -10 * Math.abs(w - bid);
    p.score += pts;
    scores.push({ playerId: p.id, playerName: p.name, bid, tricksWon: w, roundPoints: pts, totalScore: p.score });
  }
  room.gameState.roundScores = scores;
  room.gameState.phase = 'ROUND_OVER';
  log('info', `Round ${room.gameState.round} over`, { room: room.id });

  if (room.gameState.round >= room.gameState.totalRounds) {
    room.status = 'FINISHED';
    room.gameState.phase = 'GAME_OVER';
    room.gameState.finishedAt = Date.now();
    const sorted = [...room.players].sort((a, b) => b.score - a.score);
    const top = sorted[0].score;
    const tied = sorted.filter(p => p.score === top);
    room.gameState.winner = tied.length > 1 ? `Tie: ${tied.map(w => w.name).join(' & ')}` : sorted[0].name;
    log('info', `Game over`, { room: room.id, winner: room.gameState.winner });
    broadcastToRoom(room.id, 'game_finished');
    broadcastToRoom(room.id, 'room_updated');
    broadcastLobbyUpdate();
    return;
  }
  broadcastToRoom(room.id, 'room_updated');
  setTimeout(() => {
    if (!rooms[room.id] || rooms[room.id].status !== 'PLAYING') return;
    room.gameState.dealerIndex = (room.gameState.dealerIndex + 1) % room.players.length;
    startNewRound(room, room.gameState.round + 1);
    broadcastToRoom(room.id, 'room_updated');
  }, 3500);
}

// ─────────────────────────────────────────────────────────────────────────────
// Event router
// ─────────────────────────────────────────────────────────────────────────────
function handleEvent(ws, ci, event, data) {
  switch (event) {

    case 'set_player_name': {
      const name = sanitize(data?.name);
      if (!name) return;
      ci.name = name;
      if (ci.roomId && rooms[ci.roomId]) {
        const p = rooms[ci.roomId].players.find(x => x.id === ci.id);
        if (p) p.name = name;
        broadcastToRoom(ci.roomId, 'room_updated');
        broadcastLobbyUpdate();
      }
      break;
    }

    case 'get_rooms': sendTo(ws, 'rooms_updated', getLobbyRooms()); break;

    case 'create_room': {
      if (ci.roomId) return sendTo(ws, 'error', { message: 'You are already in a room. Leave first.' });
      const roomId = newRoomId();
      const roomName = sanitize(data?.roomName || `${ci.name}'s Room`, ROOM_NAME_MAX_LEN) || `${ci.name}'s Room`;
      let max = parseInt(data?.maxPlayers, 10);
      if (isNaN(max) || max < 3) max = 3;
      if (max > 8) max = 8;
      const room = {
        id: roomId, name: roomName, hostId: ci.id, maxPlayers: max,
        playerCount: 1, status: 'WAITING', createdAt: Date.now(),
        players: [{ id: ci.id, name: ci.name, score: 0, isHost: true, isDealer: false, isConnected: true, isReady: false, bid: null, tricksWon: 0, hand: [] }],
        gameState: null,
      };
      rooms[roomId] = room; ci.roomId = roomId;
      log('info', 'Room created', { roomId, host: ci.name, max });
      sendTo(ws, 'room_created', room);
      broadcastLobbyUpdate();
      break;
    }

    case 'join_room': {
      const rawId = data?.roomId ? String(data.roomId).trim() : '';
      if (!rawId) return sendTo(ws, 'error', { message: 'Please enter a Room Code.' });

      // Match exact, uppercase, or fuzzy (ignoring prefixes like "room_", dashes, spaces)
      let room = rooms[rawId] || rooms[rawId.toUpperCase()];
      if (!room) {
        const clean = rawId.toUpperCase().replace(/^ROOM[_-]?/, '').replace(/[^A-Z0-9]/g, '');
        const matchKey = Object.keys(rooms).find(k => {
          const kClean = k.toUpperCase().replace(/^ROOM[_-]?/, '').replace(/[^A-Z0-9]/g, '');
          return kClean === clean || k.toUpperCase() === rawId.toUpperCase();
        });
        if (matchKey) room = rooms[matchKey];
      }

      if (!room) return sendTo(ws, 'error', { message: `Room "${rawId}" not found. Please check the code.` });
      const roomId = room.id;
      const pName = sanitize(data?.playerName || ci.name) || ci.name;
      ci.name = pName;
      const existing = room.players.find(p => p.id === ci.id || (room.status === 'PLAYING' && p.name === pName));
      if (existing) {
        existing.id = ci.id; existing.isConnected = true; ci.roomId = roomId;
        sendTo(ws, 'room_joined', room); broadcastToRoom(roomId, 'room_updated'); return;
      }
      if (room.status !== 'WAITING') return sendTo(ws, 'error', { message: 'Game already started.' });
      if (room.players.length >= room.maxPlayers) return sendTo(ws, 'error', { message: 'Room is full.' });
      room.players.push({ id: ci.id, name: pName, score: 0, isHost: false, isDealer: false, isConnected: true, isReady: false, bid: null, tricksWon: 0, hand: [] });
      room.playerCount = room.players.length; ci.roomId = roomId;
      log('info', 'Player joined', { name: pName, roomId, count: `${room.players.length}/${room.maxPlayers}` });
      sendTo(ws, 'room_joined', room); broadcastToRoom(roomId, 'room_updated'); broadcastLobbyUpdate();
      break;
    }

    case 'set_ready':
    case 'toggle_ready': {
      const roomId = ci.roomId;
      if (!roomId || !rooms[roomId]) return;
      const room = rooms[roomId];
      const player = room.players.find(p => p.id === ci.id);
      if (!player) return;

      if (data && typeof data.isReady === 'boolean') {
        player.isReady = data.isReady;
      } else {
        player.isReady = !player.isReady;
      }
      log('info', 'Player ready state changed', { name: player.name, isReady: player.isReady, roomId });
      broadcastToRoom(roomId, 'room_updated');
      break;
    }

    case 'leave_room': handleLeaveRoom(ws, ci); break;

    case 'start_game': {
      const roomId = ci.roomId;
      if (!roomId || !rooms[roomId]) return;
      const room = rooms[roomId];
      if (room.hostId !== ci.id)      return sendTo(ws, 'error', { message: 'Only the host can start.' });
      if (room.players.length < 3)    return sendTo(ws, 'error', { message: 'Need at least 3 players.' });
      if (room.players.length > 8)    return sendTo(ws, 'error', { message: 'Maximum 8 players.' });
      if (room.status !== 'WAITING')  return sendTo(ws, 'error', { message: 'Game already started.' });
      const totalRounds = getTotalRounds(room.players.length);
      const dealer = Math.floor(Math.random() * room.players.length);
      room.status = 'PLAYING';
      room.gameState = { round: 1, totalRounds, phase: 'BIDDING', trumpCard: null, trumpSuit: null, ledSuit: null, dealerIndex: dealer, currentTurnIndex: (dealer + 1) % room.players.length, playedCards: [], trickWinnerName: null, winner: null, roundScores: [] };
      log('info', 'Game started', { roomId, players: room.players.length, totalRounds });
      startNewRound(room, 1);
      broadcastToRoom(roomId, 'game_started');
      broadcastToRoom(roomId, 'room_updated');
      broadcastLobbyUpdate();
      break;
    }

    case 'choose_trump_suit': {
      const roomId = ci.roomId;
      if (!roomId || !rooms[roomId]) return;
      const room = rooms[roomId];
      if (room.status !== 'PLAYING' || !room.gameState) return;
      const dealer = room.players[room.gameState.dealerIndex];
      if (dealer.id !== ci.id) return sendTo(ws, 'error', { message: 'Only the dealer picks trump.' });
      if (!SUITS.includes(data?.suit)) return sendTo(ws, 'error', { message: 'Invalid suit.' });
      room.gameState.trumpSuit = data.suit;
      log('info', 'Trump chosen', { suit: data.suit, dealer: dealer.name, roomId });
      broadcastToRoom(roomId, 'room_updated');
      break;
    }

    case 'submit_bid': {
      const roomId = ci.roomId;
      if (!roomId || !rooms[roomId]) return;
      const room = rooms[roomId];
      if (room.status !== 'PLAYING' || !room.gameState || room.gameState.phase !== 'BIDDING')
        return sendTo(ws, 'error', { message: 'Not in bidding phase.' });
      const tp = room.players[room.gameState.currentTurnIndex];
      if (tp.id !== ci.id) return sendTo(ws, 'error', { message: 'Not your turn to bid.' });
      const bid = parseInt(data?.bid, 10);
      if (isNaN(bid) || bid < 0 || bid > room.gameState.round)
        return sendTo(ws, 'error', { message: `Bid must be 0–${room.gameState.round}.` });
      tp.bid = bid;
      log('info', 'Bid', { player: tp.name, bid, round: room.gameState.round, roomId });
      const allBid = room.players.every(p => p.bid !== null && p.bid !== undefined);
      if (allBid) {
        room.gameState.phase = 'TRICK';
        room.gameState.currentTurnIndex = (room.gameState.dealerIndex + 1) % room.players.length;
        room.gameState.playedCards = []; room.gameState.ledSuit = null;
      } else {
        room.gameState.currentTurnIndex = (room.gameState.currentTurnIndex + 1) % room.players.length;
      }
      broadcastToRoom(roomId, 'room_updated');
      break;
    }

    case 'play_card': {
      const roomId = ci.roomId;
      if (!roomId || !rooms[roomId]) return;
      const room = rooms[roomId];
      if (room.status !== 'PLAYING' || !room.gameState || room.gameState.phase !== 'TRICK')
        return sendTo(ws, 'error', { message: 'Not in trick phase.' });
      const tp = room.players[room.gameState.currentTurnIndex];
      if (tp.id !== ci.id) return sendTo(ws, 'error', { message: 'Not your turn.' });

      let idx = -1;
      if (data?.cardId)          idx = tp.hand.findIndex(c => c.id === data.cardId);
      else if (data?.cardIndex != null) idx = parseInt(data.cardIndex, 10);
      if (idx < 0 || idx >= tp.hand.length) return sendTo(ws, 'error', { message: 'Invalid card.' });

      const card = tp.hand[idx];
      const led  = room.gameState.ledSuit;
      if (led && card.type === 'NORMAL' && card.suit !== led) {
        if (tp.hand.some(c => c.type === 'NORMAL' && c.suit === led))
          return sendTo(ws, 'error', { message: `Must follow suit – you have a ${led}.` });
      }

      tp.hand.splice(idx, 1);
      room.gameState.playedCards.push({ playerId: ci.id, playerName: tp.name, card });

      // Establish led suit
      if (!room.gameState.ledSuit) {
        if (room.gameState.playedCards.length === 1) {
          if (card.type === 'NORMAL') room.gameState.ledSuit = card.suit;
        } else {
          const first = room.gameState.playedCards[0].card;
          if (first.type === 'JESTER' && card.type === 'NORMAL') room.gameState.ledSuit = card.suit;
        }
      }

      log('info', 'Card played', { player: tp.name, card: card.name, roomId });

      if (room.gameState.playedCards.length === room.players.length) {
        const winner = determineTrickWinner(room.gameState.playedCards, room.gameState.trumpSuit, room.gameState.ledSuit);
        const wp = room.players.find(p => p.id === winner.playerId);
        if (wp) wp.tricksWon++;
        room.gameState.trickWinnerName = winner.playerName;
        log('info', 'Trick won', { winner: winner.playerName, roomId });
        broadcastToRoom(roomId, 'room_updated');

        setTimeout(() => {
          if (!rooms[roomId]?.gameState) return;
          room.gameState.playedCards = []; room.gameState.ledSuit = null; room.gameState.trickWinnerName = null;
          const wi = room.players.findIndex(p => p.id === winner.playerId);
          room.gameState.currentTurnIndex = wi >= 0 ? wi : 0;
          const left = room.players.reduce((s, p) => s + p.hand.length, 0);
          if (left === 0) handleRoundOver(room); else broadcastToRoom(roomId, 'room_updated');
        }, 1500);
      } else {
        room.gameState.currentTurnIndex = (room.gameState.currentTurnIndex + 1) % room.players.length;
        broadcastToRoom(roomId, 'room_updated');
      }
      break;
    }

    default:
      log('warn', 'Unknown event', { event, clientId: ci.id });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Disconnect / Leave
// ─────────────────────────────────────────────────────────────────────────────
function handleDisconnect(ws, ci) {
  const roomId = ci.roomId;
  if (!roomId || !rooms[roomId]) return;
  const room = rooms[roomId];
  const player = room.players.find(p => p.id === ci.id);

  if (room.status === 'PLAYING') {
    if (player) { player.isConnected = false; log('info', 'Seat reserved', { name: player.name, roomId }); }
    broadcastToRoom(roomId, 'room_updated');
  } else {
    room.players = room.players.filter(p => p.id !== ci.id);
    room.playerCount = room.players.length;
    if (room.players.length === 0) { delete rooms[roomId]; log('info', 'Room deleted (empty)', { roomId }); }
    else {
      if (room.hostId === ci.id) { room.hostId = room.players[0].id; room.players[0].isHost = true; }
      broadcastToRoom(roomId, 'room_updated');
    }
    broadcastLobbyUpdate();
  }
}

function handleLeaveRoom(ws, ci) {
  const roomId = ci.roomId;
  if (!roomId || !rooms[roomId]) return;
  const room = rooms[roomId];
  room.players = room.players.filter(p => p.id !== ci.id);
  room.playerCount = room.players.length; ci.roomId = null;
  if (room.players.length === 0) { delete rooms[roomId]; }
  else {
    if (room.hostId === ci.id) { room.hostId = room.players[0].id; room.players[0].isHost = true; }
    broadcastToRoom(roomId, 'room_updated');
  }
  broadcastLobbyUpdate();
}

// ─────────────────────────────────────────────────────────────────────────────
// WebSocket server with rate limiting + size guard
// ─────────────────────────────────────────────────────────────────────────────
const wss = new WebSocketServer({ server, maxPayload: MAX_MSG_BYTES });

wss.on('connection', (ws, req) => {
  const clientId = newClientId();
  const ci = { id: clientId, name: `Player_${clientId.substring(7, 11)}`, roomId: null, _msgCount: 0, _windowStart: Date.now() };
  clients.set(ws, ci);

  const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
  log('info', 'Client connected', { clientId, ip });
  sendTo(ws, 'rooms_updated', getLobbyRooms());

  ws.on('message', (raw) => {
    // Rate limit
    const now = Date.now();
    if (now - ci._windowStart > RATE_LIMIT_WINDOW) { ci._msgCount = 0; ci._windowStart = now; }
    if (++ci._msgCount > RATE_LIMIT_MAX) { log('warn', 'Rate limit hit', { clientId }); return sendTo(ws, 'error', { message: 'Too many requests. Slow down.' }); }

    let msg;
    try { msg = JSON.parse(raw.toString()); } catch { return; }
    const event = msg?.event;
    if (typeof event !== 'string' || !event) return;
    handleEvent(ws, ci, event, msg?.data ?? {});
  });

  ws.on('close', () => {
    log('info', 'Client disconnected', { clientId, name: ci.name });
    handleDisconnect(ws, ci);
    clients.delete(ws);
  });

  ws.on('error', (err) => log('error', 'WS error', { clientId, err: err.message }));
});

// ─────────────────────────────────────────────────────────────────────────────
// Heartbeat – keep Render connections alive
// ─────────────────────────────────────────────────────────────────────────────
const heartbeat = setInterval(() => {
  for (const [ws] of clients.entries()) { if (ws.readyState === WebSocket.OPEN) try { ws.ping(); } catch (_) {} }
}, HEARTBEAT_INTERVAL);

// ─────────────────────────────────────────────────────────────────────────────
// Stale room garbage collector (every 5 min)
// ─────────────────────────────────────────────────────────────────────────────
const staleRoomGC = setInterval(() => {
  const now = Date.now();
  for (const [id, room] of Object.entries(rooms)) {
    const age   = now - (room.gameState?.finishedAt ?? room.createdAt ?? 0);
    const stale = room.status === 'FINISHED' || room.players.every(p => !p.isConnected);
    if (stale && age > STALE_ROOM_TTL) { delete rooms[id]; log('info', 'GC: stale room removed', { roomId: id }); }
  }
}, 5 * 60 * 1000);

// ─────────────────────────────────────────────────────────────────────────────
// Graceful shutdown
// ─────────────────────────────────────────────────────────────────────────────
function gracefulShutdown(signal) {
  log('info', `${signal} – shutting down`);
  clearInterval(heartbeat); clearInterval(staleRoomGC);
  for (const [ws] of clients.entries()) { try { sendTo(ws, 'error', { message: 'Server restarting. Reconnect shortly.' }); ws.close(1001, 'shutdown'); } catch (_) {} }
  server.close(() => { log('info', 'Server closed'); process.exit(0); });
  setTimeout(() => process.exit(1), 5000);
}

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT',  () => gracefulShutdown('SIGINT'));
process.on('uncaughtException',  (e) => log('error', 'Uncaught exception',  { err: e.message, stack: e.stack }));
process.on('unhandledRejection', (r) => log('error', 'Unhandled rejection', { reason: String(r) }));

wss.on('close', () => { clearInterval(heartbeat); clearInterval(staleRoomGC); });

// ─────────────────────────────────────────────────────────────────────────────
// Start listening
// ─────────────────────────────────────────────────────────────────────────────
server.listen(PORT, () => {
  log('info', `Wizard Card Game Server started on port ${PORT}`);
  log('info', 'Rules: 3-8 Players | 60 Cards | Official Scoring');
});