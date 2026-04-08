# Multiplayer Patterns Reference

Architecture and code patterns for adding multiplayer to Phaser 4 games. Phaser handles rendering and client-side logic only — multiplayer requires a separate game server.

---

## Architecture Overview

### Authoritative Server (Recommended for Competitive Games)

```
Client A ──────────────────────────────────► Game Server
  (sends inputs)                               (runs simulation,
                                               validates moves,
Client B ──────────────────────────────────►  broadcasts state)
  (sends inputs)         ◄──────────────────
                           (sends authoritative state to all clients)
```

- Server is the source of truth; clients trust server state
- Prevents cheating (clients cannot modify their own positions, health, etc.)
- Requires more server infrastructure but is the standard for real games
- Latency matters: clients receive state 50–200ms after it was computed on the server

### Peer-to-Peer (Simpler, Less Secure)

```
Client A ◄──────────────────────────────────► Client B
  (sends/receives state directly via WebRTC)
```

- No dedicated server required — works with static hosting
- One client acts as "host" and arbitrates conflicts
- Easier to cheat — any client can send false state
- Use for: local co-op prototypes, turn-based games, jam projects

### Phaser's Role

Phaser has no networking layer. Use it for:
- Rendering remote players and objects
- Running local physics/animation
- Interpolating positions between server updates
- Predicting local player movement (client-side prediction)

---

## WebSocket Integration

```typescript
// GameScene.ts — basic WebSocket multiplayer client

interface ServerMessage {
  type: 'player_joined' | 'player_left' | 'player_moved' | 'game_state' | 'pong';
  playerId?: string;
  player?: RemotePlayerData;
  x?: number;
  y?: number;
  state?: GameStateData;
  timestamp?: number;
}

interface RemotePlayerData {
  id: string;
  x: number;
  y: number;
  spriteKey: string;
}

interface GameStateData {
  players: RemotePlayerData[];
  entities: EntityData[];
}

export class GameScene extends Phaser.Scene {
  private socket!: WebSocket;
  private localPlayer!: Phaser.Physics.Arcade.Sprite;
  private remotePlayers = new Map<string, Phaser.Physics.Arcade.Sprite>();
  private lastSentTime = 0;
  private readonly SEND_RATE_MS = 50;  // 20 updates/second
  private reconnectAttempts = 0;

  create(): void {
    this.localPlayer = this.physics.add.sprite(400, 300, 'player');
    this.connectToServer();
  }

  private connectToServer(): void {
    this.socket = new WebSocket('wss://your-server.example.com/game');

    this.socket.onopen = () => {
      console.log('[MP] Connected to server');
      this.reconnectAttempts = 0;
      this.socket.send(JSON.stringify({ type: 'join', spriteKey: 'player' }));
    };

    this.socket.onmessage = (event: MessageEvent) => {
      try {
        const msg = JSON.parse(event.data as string) as ServerMessage;
        this.handleServerMessage(msg);
      } catch (e) {
        console.warn('[MP] Failed to parse message:', e);
      }
    };

    this.socket.onclose = (event) => {
      console.log(`[MP] Disconnected (code ${event.code})`);
      this.handleDisconnect();
    };

    this.socket.onerror = () => {
      console.error('[MP] WebSocket error');
    };
  }

  private handleServerMessage(msg: ServerMessage): void {
    switch (msg.type) {
      case 'player_joined':
        if (msg.player) this.addRemotePlayer(msg.player);
        break;

      case 'player_left':
        if (msg.playerId) this.removeRemotePlayer(msg.playerId);
        break;

      case 'player_moved':
        if (msg.playerId && msg.x !== undefined && msg.y !== undefined) {
          this.updateRemotePlayer(msg.playerId, msg.x, msg.y);
        }
        break;

      case 'game_state':
        if (msg.state) this.syncGameState(msg.state);
        break;

      case 'pong':
        // Calculate RTT if you sent a ping timestamp
        if (msg.timestamp) {
          const rtt = Date.now() - msg.timestamp;
          console.log(`[MP] RTT: ${rtt}ms`);
        }
        break;
    }
  }

  private addRemotePlayer(data: RemotePlayerData): void {
    if (this.remotePlayers.has(data.id)) return;
    const sprite = this.physics.add.sprite(data.x, data.y, data.spriteKey);
    sprite.setTint(0xff8888);  // Distinguish remote players visually
    this.remotePlayers.set(data.id, sprite);
  }

  private removeRemotePlayer(id: string): void {
    const sprite = this.remotePlayers.get(id);
    if (sprite) {
      sprite.destroy();
      this.remotePlayers.delete(id);
    }
  }

  private updateRemotePlayer(id: string, x: number, y: number): void {
    const sprite = this.remotePlayers.get(id);
    if (!sprite) return;
    // Option A: Teleport (simple, jittery)
    // sprite.setPosition(x, y);

    // Option B: Interpolate (smooth — see "Dead Reckoning" section below)
    this.tweens.add({ targets: sprite, x, y, duration: 50, ease: 'Linear' });
  }

  private syncGameState(state: GameStateData): void {
    // Full-state sync on join or reconnect
    state.players.forEach(p => {
      if (!this.remotePlayers.has(p.id)) this.addRemotePlayer(p);
      else this.updateRemotePlayer(p.id, p.x, p.y);
    });
  }

  private handleDisconnect(): void {
    this.reconnectAttempts++;
    const delay = Math.min(1000 * Math.pow(2, this.reconnectAttempts), 30000);
    console.log(`[MP] Reconnecting in ${delay}ms (attempt ${this.reconnectAttempts})`);
    this.time.delayedCall(delay, () => this.connectToServer());
  }

  update(time: number): void {
    // Apply local input
    this.handleLocalInput();

    // Send local state to server (throttled)
    if (time - this.lastSentTime > this.SEND_RATE_MS) {
      this.lastSentTime = time;
      this.sendLocalState();
    }
  }

  private handleLocalInput(): void {
    const cursors = this.input.keyboard!.createCursorKeys();
    const speed = 200;
    let vx = 0, vy = 0;
    if (cursors.left.isDown)  vx = -speed;
    if (cursors.right.isDown) vx =  speed;
    if (cursors.up.isDown)    vy = -speed;
    if (cursors.down.isDown)  vy =  speed;
    this.localPlayer.setVelocity(vx, vy);
  }

  private sendLocalState(): void {
    if (this.socket.readyState !== WebSocket.OPEN) return;
    this.socket.send(JSON.stringify({
      type: 'move',
      x: Math.round(this.localPlayer.x),
      y: Math.round(this.localPlayer.y),
    }));
  }

  shutdown(): void {
    if (this.socket?.readyState === WebSocket.OPEN) {
      this.socket.close(1000, 'Scene shutdown');
    }
  }
}
```

---

## Client-Side Prediction

Apply input immediately on the client without waiting for server confirmation. Reconcile with server state when it arrives.

```typescript
interface InputFrame {
  seq: number;
  dx: number;
  dy: number;
  timestamp: number;
}

class PredictivePlayer {
  private pendingInputs: InputFrame[] = [];
  private inputSequence = 0;
  private position = { x: 0, y: 0 };

  // Called every frame — apply input locally AND send to server
  applyInput(dx: number, dy: number, socket: WebSocket): void {
    const frame: InputFrame = {
      seq: ++this.inputSequence,
      dx,
      dy,
      timestamp: Date.now(),
    };

    // Apply immediately (prediction)
    this.position.x += dx;
    this.position.y += dy;
    this.pendingInputs.push(frame);

    // Send to server
    socket.send(JSON.stringify({ type: 'input', ...frame }));
  }

  // Called when server sends authoritative position + last confirmed input sequence
  reconcile(authX: number, authY: number, lastConfirmedSeq: number): void {
    // Start from authoritative position
    this.position = { x: authX, y: authY };

    // Remove confirmed inputs
    this.pendingInputs = this.pendingInputs.filter(f => f.seq > lastConfirmedSeq);

    // Re-apply unconfirmed inputs
    for (const frame of this.pendingInputs) {
      this.position.x += frame.dx;
      this.position.y += frame.dy;
    }
  }
}
```

**When to use prediction:**
- Action games (platformers, shooters) — latency is noticeable without it
- Skip prediction for turn-based games, puzzle games, or when server RTT < 50ms

---

## Dead Reckoning (Remote Player Interpolation)

Smoothly interpolate remote player positions between sparse server updates to eliminate jitter.

```typescript
interface RemoteSnapshot {
  x: number;
  y: number;
  timestamp: number;
}

class RemotePlayerInterpolator {
  private snapshots: RemoteSnapshot[] = [];
  private readonly bufferMs = 100;  // How far behind to render (interpolation buffer)

  pushSnapshot(x: number, y: number): void {
    this.snapshots.push({ x, y, timestamp: Date.now() });
    // Keep only recent history
    const cutoff = Date.now() - 1000;
    this.snapshots = this.snapshots.filter(s => s.timestamp > cutoff);
  }

  // Returns interpolated position for 'now - bufferMs' milliseconds ago
  getInterpolatedPosition(): { x: number; y: number } | null {
    const renderTime = Date.now() - this.bufferMs;
    if (this.snapshots.length < 2) return this.snapshots[0] ?? null;

    // Find the two snapshots surrounding renderTime
    for (let i = 0; i < this.snapshots.length - 1; i++) {
      const a = this.snapshots[i];
      const b = this.snapshots[i + 1];
      if (a.timestamp <= renderTime && renderTime <= b.timestamp) {
        const t = (renderTime - a.timestamp) / (b.timestamp - a.timestamp);
        return {
          x: a.x + (b.x - a.x) * t,
          y: a.y + (b.y - a.y) * t,
        };
      }
    }

    // Extrapolate using last known velocity
    const last = this.snapshots[this.snapshots.length - 1];
    return { x: last.x, y: last.y };
  }
}

// In GameScene.update():
// remotePlayer.interpolator.pushSnapshot(msg.x, msg.y);  // on server message
// const pos = remotePlayer.interpolator.getInterpolatedPosition();
// if (pos) remotePlayer.sprite.setPosition(pos.x, pos.y);
```

---

## Lobby and Room Systems

For games with matchmaking, rooms, or persistent sessions, use a dedicated library rather than building from scratch.

### Colyseus (Node.js Game Server)

Best for: real-time multiplayer with rooms, authoritative simulation, TypeScript support.

```bash
# Server
npm create colyseus-app@latest my-game-server
cd my-game-server && npm install && npm run dev

# Client (in Phaser project)
npm install colyseus.js
```

```typescript
// Client integration
import { Client } from 'colyseus.js';

const client = new Client('wss://your-colyseus-server.com');
const room = await client.joinOrCreate<MyRoomState>('game_room', { playerName: 'Alice' });

room.onStateChange((state) => {
  // state is automatically synchronized; update Phaser objects here
  state.players.forEach((player, sessionId) => {
    if (sessionId === room.sessionId) return; // skip local player
    updateRemotePlayer(sessionId, player.x, player.y);
  });
});

room.onMessage('game_event', (message) => {
  handleGameEvent(message);
});

// Send input
room.send('move', { x: player.x, y: player.y });
```

### Nakama (Heroic Labs)

Best for: full game backend (auth, leaderboards, social, matchmaking). Self-hosted or managed cloud.

### Photon PUN

Best for: Unity-style SDK with managed cloud. JavaScript SDK available.

---

## State Synchronization Patterns

### Delta Compression

Only send fields that changed, not the entire state object.

```typescript
interface PlayerStateDelta {
  x?: number;
  y?: number;
  health?: number;
  animFrame?: string;
}

class StateDiffer {
  private lastSent: Record<string, unknown> = {};

  diff(current: Record<string, unknown>): Record<string, unknown> {
    const delta: Record<string, unknown> = {};
    for (const key of Object.keys(current)) {
      if (current[key] !== this.lastSent[key]) {
        delta[key] = current[key];
      }
    }
    this.lastSent = { ...current };
    return delta;
  }
}

// Usage: only send changed fields
const delta = differ.diff({ x: player.x, y: player.y, health });
if (Object.keys(delta).length > 0) {
  socket.send(JSON.stringify({ type: 'state_delta', ...delta }));
}
```

### Update Rate Guidelines

| Game type | Updates/second | Interval (ms) |
|---|---|---|
| Action (platformer, shooter) | 20–30 | 33–50ms |
| Strategy / city builder | 5–10 | 100–200ms |
| Turn-based | On event only | N/A |

Higher update rates increase bandwidth and server CPU. 20 updates/second is sufficient for most action games — human perception above ~20fps is limited for remote objects.

---

## Peer-to-Peer with PeerJS (WebRTC, No Server)

For jam projects, local play, and prototypes that can't have a dedicated server.

```bash
npm install peerjs
```

```typescript
import Peer, { DataConnection } from 'peerjs';

class P2PSession {
  private peer: Peer;
  private conn: DataConnection | null = null;
  private onMessage: (data: unknown) => void;

  constructor(onMessage: (data: unknown) => void) {
    this.onMessage = onMessage;
    this.peer = new Peer();  // PeerJS cloud relay (free tier available)
    this.peer.on('open', id => console.log('Your peer ID:', id));
    this.peer.on('connection', conn => this.setupConnection(conn));
  }

  /** Host: share this.peer.id with guest via external channel (lobby, clipboard) */
  get localId(): string | undefined {
    return this.peer.id;
  }

  /** Guest: connect using host's peer ID */
  connect(hostId: string): void {
    const conn = this.peer.connect(hostId, { reliable: false });
    conn.on('open', () => this.setupConnection(conn));
  }

  private setupConnection(conn: DataConnection): void {
    this.conn = conn;
    conn.on('data', data => this.onMessage(data));
    conn.on('close', () => console.log('P2P connection closed'));
  }

  send(data: unknown): void {
    this.conn?.send(data);
  }

  destroy(): void {
    this.conn?.close();
    this.peer.destroy();
  }
}
```

**Important P2P limitations:**
- One player is "host" — if they disconnect, the session ends
- No anti-cheat — host controls game state
- NAT traversal can fail on some corporate/school networks
- Not suitable for commercial competitive games

---

## Important Limitations

| Constraint | Detail |
|---|---|
| No built-in networking | Phaser has zero networking APIs — all must be custom or via a library |
| Static hosting incompatibility | WebSockets require a persistent server — itch.io and GitHub Pages cannot host a game server |
| Latency is physics | Network lag is physical — minimum RTT = 2 × speed-of-light travel time. Prediction helps but does not eliminate it |
| WebSocket vs HTTP | Use WebSockets (or WebTransport) for real-time games; REST/HTTP is too slow for per-frame communication |
| Browser security | WebSockets from HTTPS pages must connect to `wss://` (not `ws://`) |
| CORS | WebSocket connections are not subject to CORS, but your HTTP server (for REST APIs) is |
