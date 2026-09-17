# Roblox Streamer Game System

Complete Streamer Game system for Roblox Studio featuring interactive currency (Money & Hype), live viewer chat, phone equipment in hand, 3D streamer room interior, channel naming system, and anti-exploit server architecture.

---

## 📁 Project Structure

```text
roblox-streamer-game/
├── default.project.json
├── StreamerGame.rbxlx          # Ready-to-play Roblox Studio Place file
└── src/
    ├── Server/
    │   ├── Leaderstats.server.luau     # Sets up leaderstats (Money, Hype)
    │   └── StreamManager.server.luau   # Authoritative stream loop, rate limiting, phone tool & overhead
    ├── Shared/
    │   └── StreamConfig.luau           # Balance settings, viewer comments & usernames
    └── Client/
        ├── StreamGui.client.luau       # UI (Stream button, chat panel, channel modal)
        └── StreamController.client.luau# Client networking, fake comments & auto-scroll
```

---

## 🚀 How to Launch & Play

### Option A: Direct Place File (Recommended & Instant)
1. Double-click the ready-to-play file on your Desktop:
   **`StreamerGame.rbxlx`**
2. It will open directly in **Roblox Studio**.
3. Press **Play (F5)**!

---

### Option B: Using Rojo
1. Open a terminal in this directory:
   ```bash
   rojo serve
   ```
2. In Roblox Studio, open the **Plugins** tab -> click **Rojo** -> click **Connect**.
3. All files will live-sync automatically.
4. Press **Play (F5)**!

---

## 🛡️ Anti-Cheat & Security
- The client NEVER passes money amounts, subscriber numbers, or game calculations to the server.
- The server is the sole source of truth: it authoritatively manages the timer loop, updates leaderstats, and enforces rate-limiting debounces (`TOGGLE_COOLDOWN`).
- Channel names are validated and filtered through Roblox's official `TextService:FilterStringAsync` API.
