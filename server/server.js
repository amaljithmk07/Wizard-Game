const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');

const app = express();
app.use(cors());

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

// In-memory rooms store
// roomId -> { id, name, hostId, maxPlayers, status, players, gameState }
const rooms = {};

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
      status: r.status
    }));
}

io.on('connection', (socket) => {
  console.log(`[Socket Connected] ID: ${socket.id}`);
  let currentRoomId = null;
  let playerName = `Player_${socket.id.substring(0, 4)}`;

  socket.on('set_player_name', (data) => {
    if (data && data.name) {
      playerName = data.name.trim();
      socket.playerName = playerName;
      console.log(`[Player Name Set] ${socket.id} -> ${playerName}`);
    }
  });

  socket.on('get_rooms', () => {
    socket.emit('rooms_updated', getSanitizedRooms());
  });

  socket.on('create_room', (data) => {
    const roomId = `room_${Math.floor(100 + Math.random() * 900)}`;
    const roomName = (data && data.roomName && data.roomName.trim()) 
      ? data.roomName.trim() 
      : `${playerName}'s Room`;
    const maxPlayers = (data && data.maxPlayers >= 2 && data.maxPlayers <= 4) 
      ? data.maxPlayers 
      : 4;

    const newRoom = {
      id: roomId,
      name: roomName,
      hostId: socket.id,
      maxPlayers: maxPlayers,
      status: 'WAITING',
      players: [
        { id: socket.id, name: playerName, score: 0, hand: [] }
      ],
      gameState: null
    };

    rooms[roomId] = newRoom;
    currentRoomId = roomId;
    socket.join(roomId);

    console.log(`[Room Created] ${roomId} by ${playerName}`);
    socket.emit('room_created', newRoom);
    io.emit('rooms_updated', getSanitizedRooms());
  });

  socket.on('join_room', (data) => {
    const roomId = data ? data.roomId : null;
    const room = rooms[roomId];

    if (!room) {
      return socket.emit('error', { message: 'Room does not exist.' });
    }

    if (room.status !== 'WAITING') {
      return socket.emit('error', { message: 'Game has already started.' });
    }

    if (room.players.length >= room.maxPlayers) {
      return socket.emit('error', { message: 'Room is full.' });
    }

    // Add player to room
    room.players.push({
      id: socket.id,
      name: playerName,
      score: 0,
      hand: []
    });

    currentRoomId = roomId;
    socket.join(roomId);

    console.log(`[Player Joined] ${playerName} joined ${roomId}`);

    socket.emit('room_joined', room);
    io.to(roomId).emit('room_updated', room);
    io.emit('rooms_updated', getSanitizedRooms());
  });

  socket.on('leave_room', () => {
    handleLeaveRoom(socket);
  });

  socket.on('start_game', () => {
    if (!currentRoomId || !rooms[currentRoomId]) return;
    const room = rooms[currentRoomId];

    if (room.hostId !== socket.id) {
      return socket.emit('error', { message: 'Only the host can start the game.' });
    }

    if (room.players.length < 2) {
      return socket.emit('error', { message: 'At least 2 players are required to start.' });
    }

    if (room.status !== 'WAITING') {
      return socket.emit('error', { message: 'Game already started.' });
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

    console.log(`[Game Started] Room ${currentRoomId}`);

    io.to(currentRoomId).emit('game_started', room);
    io.to(currentRoomId).emit('room_updated', room);
    io.emit('rooms_updated', getSanitizedRooms());
  });

  socket.on('play_card', (data) => {
    if (!currentRoomId || !rooms[currentRoomId]) return;
    const room = rooms[currentRoomId];

    if (room.status !== 'PLAYING' || !room.gameState) return;

    const currentTurnPlayer = room.players[room.gameState.currentTurnIndex];
    if (currentTurnPlayer.id !== socket.id) {
      return socket.emit('error', { message: 'Not your turn.' });
    }

    const cardIndex = data ? data.cardIndex : -1;
    if (cardIndex < 0 || cardIndex >= currentTurnPlayer.hand.length) {
      return socket.emit('error', { message: 'Invalid card selected.' });
    }

    // Extract played card
    const playedCard = currentTurnPlayer.hand.splice(cardIndex, 1)[0];
    room.gameState.playedCards.push({
      playerId: socket.id,
      playerName: currentTurnPlayer.name,
      card: playedCard
    });

    console.log(`[Card Played] ${currentTurnPlayer.name} played ${playedCard.name}`);

    // If everyone played 1 card for the trick
    if (room.gameState.playedCards.length === room.players.length) {
      // Find highest card value
      let highestCardPlayed = room.gameState.playedCards[0];
      for (const item of room.gameState.playedCards) {
        if (item.card.value > highestCardPlayed.card.value) {
          highestCardPlayed = item;
        }
      }

      // Winner of the trick gets points
      const winnerPlayer = room.players.find(p => p.id === highestCardPlayed.playerId);
      if (winnerPlayer) {
        winnerPlayer.score += 10;
      }

      // Next turn starts at winner index
      const winnerIdx = room.players.findIndex(p => p.id === highestCardPlayed.playerId);
      room.gameState.currentTurnIndex = winnerIdx >= 0 ? winnerIdx : 0;

      // Broadcast trick result state briefly before clearing table
      io.to(currentRoomId).emit('room_updated', room);

      // Clear played cards after trick resolution
      setTimeout(() => {
        if (rooms[currentRoomId]) {
          rooms[currentRoomId].gameState.playedCards = [];

          // Check if hands are empty -> Game Finished
          const totalCardsLeft = room.players.reduce((sum, p) => sum + p.hand.length, 0);
          if (totalCardsLeft === 0) {
            room.status = 'FINISHED';
            // Find player with highest score
            let topPlayer = room.players[0];
            for (const p of room.players) {
              if (p.score > topPlayer.score) topPlayer = p;
            }
            room.gameState.winner = topPlayer.name;

            console.log(`[Game Finished] Room ${currentRoomId}. Winner: ${topPlayer.name}`);
            io.to(currentRoomId).emit('game_finished', {
              winner: topPlayer.name,
              players: room.players.map(p => ({ name: p.name, score: p.score }))
            });
          }

          io.to(currentRoomId).emit('room_updated', room);
        }
      }, 1200);

    } else {
      // Advance turn to next player
      room.gameState.currentTurnIndex = (room.gameState.currentTurnIndex + 1) % room.players.length;
      io.to(currentRoomId).emit('room_updated', room);
    }
  });

  socket.on('disconnect', () => {
    console.log(`[Socket Disconnected] ID: ${socket.id}`);
    handleLeaveRoom(socket);
  });

  function handleLeaveRoom(s) {
    if (!currentRoomId || !rooms[currentRoomId]) return;
    const roomId = currentRoomId;
    const room = rooms[roomId];

    room.players = room.players.filter(p => p.id !== s.id);
    s.leave(roomId);
    currentRoomId = null;

    if (room.players.length === 0) {
      delete rooms[roomId];
      console.log(`[Room Deleted] ${roomId} is empty.`);
    } else {
      // Reassign host if host left
      if (room.hostId === s.id) {
        room.hostId = room.players[0].id;
        console.log(`[Host Reassigned] ${room.players[0].name} is now host of ${roomId}`);
      }
      io.to(roomId).emit('room_updated', room);
      io.to(roomId).emit('player_left', { socketId: s.id, name: s.playerName });
    }

    io.emit('rooms_updated', getSanitizedRooms());
  }
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`==========================================`);
  console.log(`  Card Game Server running on port ${PORT}`);
  console.log(`==========================================`);
});
