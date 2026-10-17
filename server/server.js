const express = require('express');
const http = require('http');
const { WebSocketServer, WebSocket } = require('ws');
const cors = require('cors');

const app = express();
app.use(cors());

// Health check endpoints for Render and browsers
app.get('/', (req, res) => {
  res.send('Wizard Card Game Server is running!');
});

app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    roomsCount: Object.keys(rooms).length,
    clientsCount: clients.size,
    timestamp: new Date().toISOString()
  });
});

const server = http.createServer(app);
const wss = new WebSocketServer({ server });

// In-memory data store
// roomId -> { id, name, hostId, maxPlayers, status, players, gameState }
const rooms = {};

// Active connected clients: socket -> { id, name, roomId }
const clients = new Map();

const SUITS = ['Spades', 'Hearts', 'Diamonds', 'Clubs'];
const CARD_NAMES = {
  11: 'J',
  12: 'Q',
  13: 'K',
  14: 'A'
};

function generateDeck() {
  const deck = [];
  let idCounter = 1;
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
        name: `${displayVal} ${suitSymbol}`
      });
    }
  }
  // Shuffle deck
  for (let i = deck.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [deck[i], deck[j]] = [deck[j], deck[i]];
  }
  return deck;
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

function broadcastToRoom(roomId, event, data) {
  const room = rooms[roomId];
  if (!room) return;

  const playerIds = new Set(room.players.map(p => p.id));
  for (const [ws, info] of clients.entries()) {
    if (playerIds.has(info.id) && ws.readyState === WebSocket.OPEN) {
      sendTo(ws, event, data);
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

  console.log(`[Connected] ID: ${clientId}`);

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
    handleLeaveRoom(ws, clientInfo);
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

        // Update name in active room if currently in one
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
      const maxPlayers = (data.maxPlayers >= 2 && data.maxPlayers <= 8)
        ? data.maxPlayers
        : 4;

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
            hand: []
          }
        ],
        gameState: null
      };

      rooms[roomId] = newRoom;
      clientInfo.roomId = roomId;

      console.log(`[Room Created] ${roomId} ("${roomName}") by ${clientInfo.name}`);
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

      if (room.status !== 'WAITING') {
        return sendTo(ws, 'error', { message: 'Game has already started.' });
      }

      if (room.players.length >= room.maxPlayers) {
        return sendTo(ws, 'error', { message: 'Room is full.' });
      }

      const pName = (data.playerName && data.playerName.trim())
        ? data.playerName.trim()
        : clientInfo.name;
      clientInfo.name = pName;

      // Add player if not already in room
      const existing = room.players.find(p => p.id === clientInfo.id);
      if (!existing) {
        room.players.push({
          id: clientInfo.id,
          name: pName,
          score: 0,
          isHost: false,
          hand: []
        });
      }

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

      if (room.hostId !== clientInfo.id) {
        return sendTo(ws, 'error', { message: 'Only the host can start the game.' });
      }

      if (room.players.length < 2) {
        return sendTo(ws, 'error', { message: 'At least 2 players are required to start.' });
      }

      if (room.status !== 'WAITING') {
        return sendTo(ws, 'error', { message: 'Game already started.' });
      }

      // Generate deck and deal cards (5 cards per player)
      const deck = generateDeck();
      for (let i = 0; i < room.players.length; i++) {
        room.players[i].hand = deck.slice(i * 5, (i + 1) * 5);
        room.players[i].score = 0;
      }

      room.status = 'PLAYING';
      room.gameState = {
        currentTurnIndex: 0,
        playedCards: [],
        winner: null
      };

      console.log(`[Game Started] Room ${roomId} with ${room.players.length} players`);

      broadcastToRoom(roomId, 'game_started', room);
      broadcastToRoom(roomId, 'room_updated', room);
      broadcastAll('rooms_updated', getSanitizedRooms());
      break;
    }

    case 'play_card': {
      const roomId = clientInfo.roomId;
      if (!roomId || !rooms[roomId]) return;
      const room = rooms[roomId];

      if (room.status !== 'PLAYING' || !room.gameState) return;

      const currentTurnPlayer = room.players[room.gameState.currentTurnIndex];
      if (currentTurnPlayer.id !== clientInfo.id) {
        return sendTo(ws, 'error', { message: 'Not your turn.' });
      }

      const cardIndex = (data && data.cardIndex !== undefined) ? data.cardIndex : -1;
      if (cardIndex < 0 || cardIndex >= currentTurnPlayer.hand.length) {
        return sendTo(ws, 'error', { message: 'Invalid card selected.' });
      }

      // Extract played card from player's hand
      const playedCard = currentTurnPlayer.hand.splice(cardIndex, 1)[0];
      room.gameState.playedCards.push({
        playerId: clientInfo.id,
        playerName: currentTurnPlayer.name,
        card: playedCard
      });

      console.log(`[Card Played] ${currentTurnPlayer.name} played ${playedCard.name}`);

      // If everyone played 1 card for this trick
      if (room.gameState.playedCards.length === room.players.length) {
        // Find highest card value
        let highest = room.gameState.playedCards[0];
        for (const item of room.gameState.playedCards) {
          if (item.card.value > highest.card.value) {
            highest = item;
          }
        }

        // Winner gets points
        const winnerPlayer = room.players.find(p => p.id === highest.playerId);
        if (winnerPlayer) {
          winnerPlayer.score += 10;
        }

        // Next trick starts with the winner
        const winnerIdx = room.players.findIndex(p => p.id === highest.playerId);
        room.gameState.currentTurnIndex = winnerIdx >= 0 ? winnerIdx : 0;

        // Broadcast current trick state to show played cards
        broadcastToRoom(roomId, 'room_updated', room);

        // Clear played cards after delay
        setTimeout(() => {
          if (rooms[roomId] && rooms[roomId].gameState) {
            rooms[roomId].gameState.playedCards = [];

            // Check if all cards have been played -> Game Finished
            const totalCardsLeft = room.players.reduce((sum, p) => sum + p.hand.length, 0);
            if (totalCardsLeft === 0) {
              room.status = 'FINISHED';

              let topPlayer = room.players[0];
              for (const p of room.players) {
                if (p.score > topPlayer.score) topPlayer = p;
              }
              room.gameState.winner = topPlayer.name;

              console.log(`[Game Finished] Room ${roomId}. Winner: ${topPlayer.name}`);
              broadcastToRoom(roomId, 'game_finished', {
                winner: topPlayer.name,
                players: room.players.map(p => ({ name: p.name, score: p.score }))
              });
            }

            broadcastToRoom(roomId, 'room_updated', room);
          }
        }, 1200);

      } else {
        // Advance turn to next player
        room.gameState.currentTurnIndex = (room.gameState.currentTurnIndex + 1) % room.players.length;
        broadcastToRoom(roomId, 'room_updated', room);
      }
      break;
    }
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
    console.log(`[Room Deleted] ${roomId} is now empty.`);
  } else {
    // Reassign host if the host left
    if (room.hostId === clientInfo.id) {
      room.hostId = room.players[0].id;
      room.players[0].isHost = true;
      console.log(`[Host Reassigned] ${room.players[0].name} is now host of ${roomId}`);
    }
    broadcastToRoom(roomId, 'room_updated', room);
    broadcastToRoom(roomId, 'player_left', { id: clientInfo.id, name: clientInfo.name });
  }

  broadcastAll('rooms_updated', getSanitizedRooms());
}

// 25-second heartbeat ping to prevent cloud providers (like Render) from closing idle WebSockets
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
  console.log(`==========================================`);
  console.log(`  Wizard Game Server running on port ${PORT}`);
  console.log(`==========================================`);
});
