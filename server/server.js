const express = require('express');
const http = require('http');
const { WebSocketServer, WebSocket } = require('ws');
const cors = require('cors');

const app = express();
app.use(cors());

// Health check endpoints for Render and monitoring
app.get('/', (req, res) => {
  res.send('Wizard Official Card Game Server is running!');
});

app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    game: 'Wizard Multiplayer Card Game',
    roomsCount: Object.keys(rooms).length,
    clientsCount: clients.size,
    timestamp: new Date().toISOString()
  });
});

const server = http.createServer(app);
const wss = new WebSocketServer({ server });

// In-memory data store
// roomId -> GameRoom object
const rooms = {};

// Active connected clients: socket -> { id, name, roomId }
const clients = new Map();

// Suits and Card Definitions
const SUITS = ['Spades', 'Hearts', 'Diamonds', 'Clubs'];
const CARD_NAMES = {
  11: 'J',
  12: 'Q',
  13: 'K',
  14: 'A'
};

/**
 * Generates the official 60-card Wizard deck:
 * - 52 standard playing cards (4 suits x 13 values: 2 to 14 [Ace])
 * - 4 Wizards
 * - 4 Jesters
 */
function generateWizardDeck() {
  const deck = [];
  let idCounter = 1;

  // 1. 52 standard playing cards
  for (const suit of SUITS) {
    for (let val = 2; val <= 14; val++) {
      const displayVal = CARD_NAMES[val] || val.toString();
      let suitSymbol = '♠';
      if (suit === 'Hearts') suitSymbol = '♥';
      if (suit === 'Diamonds') suitSymbol = '♦';
      if (suit === 'Clubs') suitSymbol = '♣';

      deck.push({
        id: `card_${idCounter++}`,
        suit,
        value: val,
        name: `${displayVal} ${suitSymbol}`,
        type: 'NORMAL'
      });
    }
  }

  // 2. 4 Wizards (Value 99, wins over all normal and trump cards)
  for (let w = 1; w <= 4; w++) {
    deck.push({
      id: `wizard_${w}`,
      suit: 'Wizard',
      value: 99,
      name: 'Wizard 🧙‍♂️',
      type: 'WIZARD'
    });
  }

  // 3. 4 Jesters (Value 0, lowest card)
  for (let j = 1; j <= 4; j++) {
    deck.push({
      id: `jester_${j}`,
      suit: 'Jester',
      value: 0,
      name: 'Jester 🃏',
      type: 'JESTER'
    });
  }

  // Fisher-Yates Shuffle
  for (let i = deck.length - 1; i > 0; i--) {
    const r = Math.floor(Math.random() * (i + 1));
    [deck[i], deck[r]] = [deck[r], deck[i]];
  }

  return deck;
}

/**
 * Returns total rounds according to official rules (and 7-8 player adaptation):
 * 3 players -> 20 rounds
 * 4 players -> 15 rounds
 * 5 players -> 12 rounds
 * 6 players -> 10 rounds
 * 7 players -> 8 rounds (house adaptation)
 * 8 players -> 7 rounds (house adaptation)
 */
function getTotalRounds(playerCount) {
  switch (playerCount) {
    case 3: return 20;
    case 4: return 15;
    case 5: return 12;
    case 6: return 10;
    case 7: return 8;
    case 8: return 7;
    default: return Math.floor(60 / playerCount);
  }
}

function getSanitizedRooms() {
  return Object.values(rooms)
    .filter(r => r.status === 'WAITING' && r.players.length < r.maxPlayers)
    .map(r => ({
      id: r.id,
      name: r.name,
      hostId: r.hostId,
      maxPlayers: r.maxPlayers,
      playerCount: r.players.length,
      status: r.status,
      players: r.players.map(p => ({
        id: p.id,
        name: p.name,
        score: p.score,
        isHost: p.isHost
      }))
    }));
}

function sendTo(socket, event, data) {
  if (socket && socket.readyState === WebSocket.OPEN) {
    try {
      socket.send(JSON.stringify({ event, data: data ?? {} }));
    } catch (e) {
      console.error(`[Error sending to client]:`, e.message);
    }
  }
}

/**
 * Sends room state to all clients in the room, strictly ensuring
 * opponent unplayed cards remain private (Rule 8).
 */
function broadcastToRoom(roomId, event, rawRoom) {
  const room = rooms[roomId];
  if (!room) return;

  for (const [ws, info] of clients.entries()) {
    if (ws.readyState === WebSocket.OPEN && info.roomId === roomId) {
      // Create a customized view of the room where only info.id can see their private hand
      const sanitizedPlayers = room.players.map(p => {
        if (p.id === info.id) {
          return { ...p };
        } else {
          // Hide opponent unplayed cards from network packet
          return {
            ...p,
            hand: p.hand.map(c => ({ id: 'hidden', suit: 'Hidden', value: 0, name: 'Card', type: 'HIDDEN' }))
          };
        }
      });

      const clientRoomView = {
        ...room,
        players: sanitizedPlayers
      };

      sendTo(ws, event, clientRoomView);
    }
  }
}

function broadcastAll(event, data) {
  for (const [ws] of clients.entries()) {
    if (ws.readyState === WebSocket.OPEN) {
      sendTo(ws, event, data);
    }
  }
}

wss.on('connection', (ws) => {
  const clientId = 'player_' + Math.random().toString(36).substring(2, 9);
  const clientInfo = {
    id: clientId,
    name: `Player_${clientId.substring(7, 11)}`,
    roomId: null
  };
  clients.set(ws, clientInfo);

  console.log(`[Connected] Client ID: ${clientId}`);

  // Send initial room list on connection
  sendTo(ws, 'rooms_updated', getSanitizedRooms());

  ws.on('message', (raw) => {
    try {
      const message = JSON.parse(raw.toString());
      const event = message.event;
      const data = message.data || {};

      handleEvent(ws, clientInfo, event, data);
    } catch (err) {
      console.error(`[JSON Parse Error]:`, err.message);
    }
  });

  ws.on('close', () => {
    console.log(`[Disconnected] ID: ${clientInfo.id} (${clientInfo.name})`);
    handleDisconnect(ws, clientInfo);
    clients.delete(ws);
  });

  ws.on('error', (err) => {
    console.error(`[Socket Error] ${clientInfo.id}:`, err.message);
  });
});

function handleEvent(ws, clientInfo, event, data) {
  switch (event) {
    case 'set_player_name': {
      if (data && data.name) {
        clientInfo.name = data.name.trim();
        console.log(`[Player Name Set] ${clientInfo.id} -> ${clientInfo.name}`);

        if (clientInfo.roomId && rooms[clientInfo.roomId]) {
          const room = rooms[clientInfo.roomId];
          const p = room.players.find(x => x.id === clientInfo.id);
          if (p) p.name = clientInfo.name;
          broadcastToRoom(clientInfo.roomId, 'room_updated', room);
          broadcastAll('rooms_updated', getSanitizedRooms());
        }
      }
      break;
    }

    case 'get_rooms': {
      sendTo(ws, 'rooms_updated', getSanitizedRooms());
      break;
    }

    case 'create_room': {
      const roomId = `room_${Math.floor(100 + Math.random() * 900)}`;
      const roomName = (data.roomName && data.roomName.trim())
        ? data.roomName.trim()
        : `${clientInfo.name}'s Room`;
      
      // Enforce 3 to 8 players max limit
      let maxPlayers = parseInt(data.maxPlayers, 10);
      if (isNaN(maxPlayers) || maxPlayers < 3) maxPlayers = 3;
      if (maxPlayers > 8) maxPlayers = 8;

      const newRoom = {
        id: roomId,
        name: roomName,
        hostId: clientInfo.id,
        maxPlayers: maxPlayers,
        playerCount: 1,
        status: 'WAITING',
        players: [
          {
            id: clientInfo.id,
            name: clientInfo.name,
            score: 0,
            isHost: true,
            isDealer: false,
            isConnected: true,
            bid: null,
            tricksWon: 0,
            hand: []
          }
        ],
        gameState: null
      };

      rooms[roomId] = newRoom;
      clientInfo.roomId = roomId;

      console.log(`[Room Created] ${roomId} ("${roomName}", Max: ${maxPlayers}) by ${clientInfo.name}`);
      sendTo(ws, 'room_created', newRoom);
      broadcastAll('rooms_updated', getSanitizedRooms());
      break;
    }

    case 'join_room': {
      const roomId = data.roomId;
      const room = rooms[roomId];

      if (!room) {
        return sendTo(ws, 'error', { message: 'Room does not exist.' });
      }

      const pName = (data.playerName && data.playerName.trim())
        ? data.playerName.trim()
        : clientInfo.name;
      clientInfo.name = pName;

      // Check if this is a reconnecting player
      const existingPlayer = room.players.find(p => p.id === clientInfo.id || p.name === pName);
      if (existingPlayer) {
        existingPlayer.id = clientInfo.id;
        existingPlayer.isConnected = true;
        clientInfo.roomId = roomId;
        console.log(`[Player Reconnected] ${pName} reconnected to ${roomId}`);
        sendTo(ws, 'room_joined', room);
        broadcastToRoom(roomId, 'room_updated', room);
        return;
      }

      // Check if new players can join
      if (room.status !== 'WAITING') {
        return sendTo(ws, 'error', { message: 'Game has already started. No new players allowed.' });
      }

      if (room.players.length >= room.maxPlayers) {
        return sendTo(ws, 'error', { message: 'Room is full (Maximum 8 players).' });
      }

      room.players.push({
        id: clientInfo.id,
        name: pName,
        score: 0,
        isHost: false,
        isDealer: false,
        isConnected: true,
        bid: null,
        tricksWon: 0,
        hand: []
      });

      room.playerCount = room.players.length;
      clientInfo.roomId = roomId;

      console.log(`[Player Joined] ${pName} joined ${roomId} (${room.players.length}/${room.maxPlayers})`);

      sendTo(ws, 'room_joined', room);
      broadcastToRoom(roomId, 'room_updated', room);
      broadcastAll('rooms_updated', getSanitizedRooms());
      break;
    }

    case 'leave_room': {
      handleLeaveRoom(ws, clientInfo);
      break;
    }

    case 'start_game': {
      const roomId = clientInfo.roomId;
      if (!roomId || !rooms[roomId]) return;
      const room = rooms[roomId];

      // Rule 8: Only host can start
      if (room.hostId !== clientInfo.id) {
        return sendTo(ws, 'error', { message: 'Only the host can start the game.' });
      }

      // Rule 1 & 8: Min 3 players, Max 8 players
      if (room.players.length < 3) {
        return sendTo(ws, 'error', { message: 'Wizard requires a minimum of 3 players to start.' });
      }

      if (room.players.length > 8) {
        return sendTo(ws, 'error', { message: 'Room capacity exceeded (maximum 8 players).' });
      }

      if (room.status !== 'WAITING') {
        return sendTo(ws, 'error', { message: 'Game is already in progress.' });
      }

      // Initialize Wizard Game State
      const totalRounds = getTotalRounds(room.players.length);
      const firstDealerIndex = Math.floor(Math.random() * room.players.length);

      room.status = 'PLAYING';
      room.gameState = {
        round: 1,
        totalRounds: totalRounds,
        phase: 'BIDDING',
        trumpCard: null,
        trumpSuit: null,
        ledSuit: null,
        dealerIndex: firstDealerIndex,
        currentTurnIndex: (firstDealerIndex + 1) % room.players.length,
        playedCards: [],
        trickWinnerName: null,
        winner: null,
        roundScores: []
      };

      console.log(`[Game Started] Room ${roomId} with ${room.players.length} players. Total Rounds: ${totalRounds}`);

      // Setup Round 1
      startNewRound(room, 1);

      broadcastToRoom(roomId, 'game_started', room);
      broadcastToRoom(roomId, 'room_updated', room);
      broadcastAll('rooms_updated', getSanitizedRooms());
      break;
    }

    case 'choose_trump_suit': {
      // If a Wizard was revealed as trump, the dealer chooses the suit
      const roomId = clientInfo.roomId;
      if (!roomId || !rooms[roomId]) return;
      const room = rooms[roomId];

      if (room.status !== 'PLAYING' || !room.gameState) return;
      const dealer = room.players[room.gameState.dealerIndex];
      if (dealer.id !== clientInfo.id) {
        return sendTo(ws, 'error', { message: 'Only the dealer chooses the trump suit.' });
      }

      const suit = data.suit;
      if (SUITS.includes(suit)) {
        room.gameState.trumpSuit = suit;
        console.log(`[Dealer Chose Trump] ${dealer.name} chose ${suit} in room ${roomId}`);
        broadcastToRoom(roomId, 'room_updated', room);
      }
      break;
    }

    case 'submit_bid': {
      const roomId = clientInfo.roomId;
      if (!roomId || !rooms[roomId]) return;
      const room = rooms[roomId];

      if (room.status !== 'PLAYING' || !room.gameState || room.gameState.phase !== 'BIDDING') {
        return sendTo(ws, 'error', { message: 'Not in bidding phase.' });
      }

      const currentTurnPlayer = room.players[room.gameState.currentTurnIndex];
      if (currentTurnPlayer.id !== clientInfo.id) {
        return sendTo(ws, 'error', { message: 'Not your turn to bid.' });
      }

      const bid = parseInt(data.bid, 10);
      const currentRound = room.gameState.round;

      // Rule 4: Bid must be a whole number from 0 to current round cards
      if (isNaN(bid) || bid < 0 || bid > currentRound) {
        return sendTo(ws, 'error', { message: `Bid must be between 0 and ${currentRound}.` });
      }

      // Record bid
      currentTurnPlayer.bid = bid;
      console.log(`[Bid Submitted] ${currentTurnPlayer.name} bid ${bid} in Round ${currentRound}`);

      // Check if all players have bid
      const allBid = room.players.every(p => p.bid !== null && p.bid !== undefined);

      if (allBid) {
        // Transition to TRICK phase
        room.gameState.phase = 'TRICK';
        // Player to dealer's left leads the first trick
        room.gameState.currentTurnIndex = (room.gameState.dealerIndex + 1) % room.players.length;
        room.gameState.playedCards = [];
        room.gameState.ledSuit = null;
        console.log(`[Bidding Complete] Entering Trick Phase for Round ${currentRound}`);
      } else {
        // Advance turn clockwise to next bidder
        room.gameState.currentTurnIndex = (room.gameState.currentTurnIndex + 1) % room.players.length;
      }

      broadcastToRoom(roomId, 'room_updated', room);
      break;
    }

    case 'play_card': {
      const roomId = clientInfo.roomId;
      if (!roomId || !rooms[roomId]) return;
      const room = rooms[roomId];

      if (room.status !== 'PLAYING' || !room.gameState || room.gameState.phase !== 'TRICK') {
        return sendTo(ws, 'error', { message: 'Not currently in trick playing phase.' });
      }

      const currentTurnPlayer = room.players[room.gameState.currentTurnIndex];
      if (currentTurnPlayer.id !== clientInfo.id) {
        return sendTo(ws, 'error', { message: 'Not your turn to play.' });
      }

      // Locate card by ID or index
      let cardIndex = -1;
      if (data.cardId) {
        cardIndex = currentTurnPlayer.hand.findIndex(c => c.id === data.cardId);
      } else if (data.cardIndex !== undefined) {
        cardIndex = data.cardIndex;
      }

      if (cardIndex < 0 || cardIndex >= currentTurnPlayer.hand.length) {
        return sendTo(ws, 'error', { message: 'Invalid card selected.' });
      }

      const playedCard = currentTurnPlayer.hand[cardIndex];

      // Rule 5: MUST FOLLOW SUIT ENFORCEMENT
      // - First player leads any card.
      // - Wizards and Jesters can be played at any time.
      // - If led suit is established, and player does not play Wizard/Jester or led suit:
      //   Reject if player holds any card of led suit!
      const ledSuit = room.gameState.ledSuit;

      if (ledSuit && playedCard.type === 'NORMAL' && playedCard.suit !== ledSuit) {
        const hasLedSuit = currentTurnPlayer.hand.some(c => c.type === 'NORMAL' && c.suit === ledSuit);
        if (hasLedSuit) {
          return sendTo(ws, 'error', {
            message: `You must follow suit! You have a ${ledSuit} in your hand.`
          });
        }
      }

      // Remove card from hand
      currentTurnPlayer.hand.splice(cardIndex, 1);

      // Add to trick
      room.gameState.playedCards.push({
        playerId: clientInfo.id,
        playerName: currentTurnPlayer.name,
        card: playedCard
      });

      console.log(`[Card Played] ${currentTurnPlayer.name} played ${playedCard.name}`);

      // Rule 5: Establish Led Suit if not already established
      // - If first card is NORMAL: establishes led suit.
      // - If first card is WIZARD: any card can be played (no led suit).
      // - If first card is JESTER: first normal card played establishes led suit.
      if (!room.gameState.ledSuit) {
        if (room.gameState.playedCards.length === 1) {
          if (playedCard.type === 'NORMAL') {
            room.gameState.ledSuit = playedCard.suit;
          }
          // If first card was Wizard or Jester, ledSuit stays null
        } else {
          // Check if this is the first normal card establishing led suit after Jester lead
          const firstCard = room.gameState.playedCards[0].card;
          if (firstCard.type === 'JESTER' && playedCard.type === 'NORMAL') {
            room.gameState.ledSuit = playedCard.suit;
          }
        }
      }

      // Check if trick is complete (everyone played 1 card)
      if (room.gameState.playedCards.length === room.players.length) {
        // Resolve trick winner
        const winningTrickItem = determineTrickWinner(
          room.gameState.playedCards,
          room.gameState.trumpSuit,
          room.gameState.ledSuit
        );

        const winnerPlayer = room.players.find(p => p.id === winningTrickItem.playerId);
        if (winnerPlayer) {
          winnerPlayer.tricksWon += 1;
        }

        room.gameState.trickWinnerName = winningTrickItem.playerName;
        console.log(`[Trick Won] ${winningTrickItem.playerName} won the trick with ${winningTrickItem.card.name}`);

        // Broadcast current trick result with winner name
        broadcastToRoom(roomId, 'room_updated', room);

        // Clear table after 1500ms delay and proceed
        setTimeout(() => {
          if (!rooms[roomId] || !rooms[roomId].gameState) return;

          room.gameState.playedCards = [];
          room.gameState.ledSuit = null;
          room.gameState.trickWinnerName = null;

          // Winner leads the next trick
          const winnerIndex = room.players.findIndex(p => p.id === winningTrickItem.playerId);
          room.gameState.currentTurnIndex = winnerIndex >= 0 ? winnerIndex : 0;

          // Check if all cards in hand are exhausted -> ROUND OVER
          const totalCardsLeft = room.players.reduce((sum, p) => sum + p.hand.length, 0);
          if (totalCardsLeft === 0) {
            handleRoundOver(room);
          } else {
            broadcastToRoom(roomId, 'room_updated', room);
          }
        }, 1500);

      } else {
        // Advance clockwise to next player in trick
        room.gameState.currentTurnIndex = (room.gameState.currentTurnIndex + 1) % room.players.length;
        broadcastToRoom(roomId, 'room_updated', room);
      }
      break;
    }
  }
}

/**
 * Official Wizard Trick Winner Resolution (Rule 5):
 * 1. The first Wizard played wins.
 * 2. If no Wizard is played, the highest trump card wins.
 * 3. If no trump is played, the highest card of the led suit wins.
 * 4. If every card played is a Jester, the first Jester wins.
 */
function determineTrickWinner(playedCards, trumpSuit, ledSuit) {
  // 1. First Wizard wins
  for (const item of playedCards) {
    if (item.card.type === 'WIZARD') {
      return item;
    }
  }

  // 2. Highest Trump wins (if trumpSuit exists)
  if (trumpSuit) {
    let highestTrump = null;
    for (const item of playedCards) {
      if (item.card.type === 'NORMAL' && item.card.suit === trumpSuit) {
        if (!highestTrump || item.card.value > highestTrump.card.value) {
          highestTrump = item;
        }
      }
    }
    if (highestTrump) return highestTrump;
  }

  // 3. Highest card of led suit wins
  if (ledSuit) {
    let highestLed = null;
    for (const item of playedCards) {
      if (item.card.type === 'NORMAL' && item.card.suit === ledSuit) {
        if (!highestLed || item.card.value > highestLed.card.value) {
          highestLed = item;
        }
      }
    }
    if (highestLed) return highestLed;
  }

  // 4. If every card played was a Jester, the first Jester wins
  return playedCards[0];
}

/**
 * Handles round setup: deals round R cards, determines trump card and suit.
 */
function startNewRound(room, roundNumber) {
  const deck = generateWizardDeck();
  const playerCount = room.players.length;

  room.gameState.round = roundNumber;
  room.gameState.phase = 'BIDDING';
  room.gameState.playedCards = [];
  room.gameState.ledSuit = null;
  room.gameState.trickWinnerName = null;

  // Reset round player states
  for (let i = 0; i < playerCount; i++) {
    const p = room.players[i];
    p.hand = deck.slice(i * roundNumber, (i + 1) * roundNumber);
    p.bid = null;
    p.tricksWon = 0;
    p.isDealer = (i === room.gameState.dealerIndex);
  }

  // Determine Trump Card
  // Final round for 3-6 players deals all 60 cards -> NO TRUMP
  const totalRounds = room.gameState.totalRounds;
  const isFinalRound3to6 = (playerCount <= 6 && roundNumber === totalRounds);

  if (isFinalRound3to6) {
    room.gameState.trumpCard = null;
    room.gameState.trumpSuit = null;
    console.log(`[Round ${roundNumber}] Final Round (3-6 Players): No Trump.`);
  } else {
    // Reveal next card
    const trumpCardIndex = playerCount * roundNumber;
    const trumpCard = deck[trumpCardIndex];
    room.gameState.trumpCard = trumpCard;

    if (trumpCard.type === 'NORMAL') {
      room.gameState.trumpSuit = trumpCard.suit;
      console.log(`[Round ${roundNumber}] Trump Card: ${trumpCard.name} -> Trump is ${trumpCard.suit}`);
    } else if (trumpCard.type === 'JESTER') {
      room.gameState.trumpSuit = null;
      console.log(`[Round ${roundNumber}] Trump Card: Jester -> No Trump`);
    } else if (trumpCard.type === 'WIZARD') {
      // Dealer chooses trump suit (default to Spades until dealer selects)
      room.gameState.trumpSuit = 'Spades';
      console.log(`[Round ${roundNumber}] Trump Card: Wizard -> Dealer will choose trump suit`);
    }
  }

  // Bidding starts to dealer's left
  room.gameState.currentTurnIndex = (room.gameState.dealerIndex + 1) % playerCount;
}

/**
 * Calculates Round Scores according to Rule 6:
 * - Correct prediction: +20 points, plus +10 per trick won.
 * - Incorrect prediction: -10 per trick over or under bid.
 */
function handleRoundOver(room) {
  const roundScores = [];

  for (const p of room.players) {
    const bid = p.bid ?? 0;
    const tricks = p.tricksWon;
    let roundPoints = 0;

    if (tricks === bid) {
      roundPoints = 20 + (tricks * 10);
    } else {
      roundPoints = -10 * Math.abs(tricks - bid);
    }

    p.score += roundPoints;

    roundScores.push({
      playerId: p.id,
      playerName: p.name,
      bid,
      tricksWon: tricks,
      roundPoints,
      totalScore: p.score
    });
  }

  room.gameState.roundScores = roundScores;
  room.gameState.phase = 'ROUND_OVER';
  console.log(`[Round ${room.gameState.round} Finished] Scores updated.`);

  // Check if Game is Complete
  if (room.gameState.round >= room.gameState.totalRounds) {
    room.status = 'FINISHED';
    room.gameState.phase = 'GAME_OVER';

    // Sort players by total cumulative score descending
    const sorted = [...room.players].sort((a, b) => b.score - a.score);
    const topScore = sorted[0].score;
    const tiedWinners = sorted.filter(p => p.score === topScore);

    if (tiedWinners.length > 1) {
      room.gameState.winner = `Tie: ${tiedWinners.map(w => w.name).join(' & ')}`;
    } else {
      room.gameState.winner = sorted[0].name;
    }

    console.log(`[Game Finished] Room ${room.id}. Winner: ${room.gameState.winner}`);

    broadcastToRoom(room.id, 'game_finished', {
      winner: room.gameState.winner,
      standings: sorted.map((p, idx) => ({
        rank: idx + 1,
        name: p.name,
        score: p.score
      }))
    });

    broadcastToRoom(room.id, 'room_updated', room);
    broadcastAll('rooms_updated', getSanitizedRooms());
    return;
  }

  // Broadcast Round Over Summary
  broadcastToRoom(room.id, 'room_updated', room);

  // Automatically start next round after 3.5 seconds
  setTimeout(() => {
    if (!rooms[room.id] || rooms[room.id].status !== 'PLAYING') return;

    // Move dealer 1 seat clockwise
    room.gameState.dealerIndex = (room.gameState.dealerIndex + 1) % room.players.length;
    startNewRound(room, room.gameState.round + 1);

    broadcastToRoom(room.id, 'room_updated', room);
  }, 3500);
}

function handleDisconnect(ws, clientInfo) {
  const roomId = clientInfo.roomId;
  if (!roomId || !rooms[roomId]) return;

  const room = rooms[roomId];
  const player = room.players.find(p => p.id === clientInfo.id);

  if (room.status === 'PLAYING') {
    // Rule 1: A disconnected player's seat is reserved temporarily for reconnection
    if (player) {
      player.isConnected = false;
      console.log(`[Seat Reserved] ${player.name} disconnected, seat reserved in room ${roomId}`);
    }
    broadcastToRoom(roomId, 'room_updated', room);
  } else {
    // In waiting lobby, remove player immediately
    room.players = room.players.filter(p => p.id !== clientInfo.id);
    room.playerCount = room.players.length;

    if (room.players.length === 0) {
      delete rooms[roomId];
      console.log(`[Room Deleted] ${roomId} is empty.`);
    } else {
      // Transfer host if host left
      if (room.hostId === clientInfo.id) {
        room.hostId = room.players[0].id;
        room.players[0].isHost = true;
        console.log(`[Host Reassigned] ${room.players[0].name} is now host of ${roomId}`);
      }
      broadcastToRoom(roomId, 'room_updated', room);
    }
    broadcastAll('rooms_updated', getSanitizedRooms());
  }
}

function handleLeaveRoom(ws, clientInfo) {
  const roomId = clientInfo.roomId;
  if (!roomId || !rooms[roomId]) return;

  const room = rooms[roomId];
  room.players = room.players.filter(p => p.id !== clientInfo.id);
  room.playerCount = room.players.length;
  clientInfo.roomId = null;

  if (room.players.length === 0) {
    delete rooms[roomId];
    console.log(`[Room Deleted] ${roomId} is empty.`);
  } else {
    if (room.hostId === clientInfo.id) {
      room.hostId = room.players[0].id;
      room.players[0].isHost = true;
    }
    broadcastToRoom(roomId, 'room_updated', room);
  }

  broadcastAll('rooms_updated', getSanitizedRooms());
}

// 25-second ping heartbeat to prevent Render from disconnecting idle WebSockets
const heartbeat = setInterval(() => {
  for (const [ws] of clients.entries()) {
    if (ws.readyState === WebSocket.OPEN) {
      try {
        ws.ping();
      } catch (_) {}
    }
  }
}, 25000);

wss.on('close', () => {
  clearInterval(heartbeat);
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`=======================================================`);
  console.log(`  Wizard Official Card Game Server running on port ${PORT}`);
  console.log(`  Rules: 3-8 Players | 60 Cards | Standard Bids & Scores`);
  console.log(`=======================================================`);
});
