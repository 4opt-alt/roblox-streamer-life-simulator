# Roblox Streamer Life Simulator 🎮

An advanced, feature-packed **Streamer Life Simulator** built for **Roblox Studio**, featuring multi-platform broadcasting, interactive stream events, a survival stamina economy, drivable vehicles, and an open-world city.

🌐 **GitHub Repository**: [https://github.com/4opt-alt/roblox-streamer-life-simulator](https://github.com/4opt-alt/roblox-streamer-life-simulator)

---

## ✨ Features

### 1. 📺 Platform Selection & Multi-Stream Combo
- **YouTube Live**: Balanced starter platform with steady money and subscriber gains.
- **Twitch**: Generous donor culture with a **+35% money boost**.
- **TikTok Live**: Viral algorithmic reach with a **+60% subscriber boost**.
- **Multi-Stream Combo (YouTube + Twitch)**: Cross-platform broadcasting granting **+85% money & +50% subscribers**. Unlockable in-game for ** Cash** or via donation for **49 Robux**.

### 2. ⚡ Dynamic Stream Events (Interactive Decisions)
- Occurs every 30–45s (first event in 10–14s) with interactive choice cards and a 9-second progress timer.
- **Proportional Subscriber Scaling**:
  - At **1,000 Subscribers**: +100 on good decisions / -50 on poor decisions.
  - At **50 Subscribers**: +5 on good decisions / -3 on poor decisions.
- Scenarios include: *Toxic Hater, Clutch Moment, Streamer Dare, Game Crash, Raid*.

### 3. 🍔 Survival Economy & Stamina System
- Realistic early-game struggle: start with , where every dollar counts.
- Energy drain during broadcasts; player suffers fatigue penalties under 25% energy and collapses at 0%.
- Recharge by driving to **Burger Mart** for energy drinks and food combos.
- Upgrade your career at **Tech Store**: purchase microphones, webcams, multi-monitor setups, and high-tier games.

### 4. 🚗 Micro Open-World City & Drivable Vehicle
- Drivable red sedan with **[E] Drive Car** ProximityPrompt, realistic physics, flip car keybind **[F]**, and a live speedometer HUD (km/h).
- Physical city shops with interactive counter prompts: **Tech Store** & **Burger Mart**.
- **3D Wall of Fame** leaderboard podium in English displaying top streamers.
- **3D Screen Waypoints** with real-time distance tracking (Studio, Car, Shops, Leaderboard).

---

## 📁 Project Structure

`	ext
roblox-streamer-game/
├── default.project.json
├── build_rbxlx.py              # Place generator & automatic GitHub sync
├── sync_to_github.bat          # 1-Click desktop sync tool
├── sync_to_github.ps1          # PowerShell sync automation
├── StreamerGame.rbxlx          # Complete ready-to-play Roblox Studio place
└── src/
    ├── Client/
    │   ├── CityWaypoints.client.luau      # 3D navigation markers
    │   ├── PlatformSelectGui.client.luau  # Platform choice modal & Robux purchase
    │   ├── ShopGui.client.luau            # Physical store UI
    │   ├── StreamController.client.luau   # Reactive comment algorithms
    │   ├── StreamEventGui.client.luau     # Event choice timer cards
    │   ├── StreamGui.client.luau          # Main streaming HUD & stamina bar
    │   └── VehicleGui.client.luau         # Car speedometer & driving controls
    ├── Server/
    │   ├── EventManager.server.luau       # Event bus
    │   ├── LeaderboardManager.server.luau # 3D Wall of Fame podium
    │   ├── Leaderstats.server.luau        # Starter stats & data init
    │   ├── ShopManager.server.luau        # Store transactions & MarketplaceService Robux handler
    │   ├── StreamManager.server.luau      # Authoritative stream simulation loop
    │   └── VehicleManager.server.luau     # Car physics & seat replication
    └── Shared/
        ├── ShopConfig.luau                # Shop items, games & hardware prices
        ├── StreamConfig.luau              # Platform multipliers & stamina settings
        └── StreamEventsConfig.luau        # Dynamic event scenarios & formula
`

---

## 🔄 Automatic GitHub Sync

Whenever changes are made, the repository can be automatically updated:
1. **Via Build Script**: Running python build_rbxlx.py automatically stages, commits, and pushes all updates to GitHub.
2. **Via 1-Click Desktop Shortcut**: Double-click Sync_StreamerGame_GitHub.bat on your Desktop to instantly push any manual file changes.

---

## 🚀 How to Play in Roblox Studio

1. Open StreamerGame.rbxlx directly in **Roblox Studio**.
2. Click **Play (F5)**!
