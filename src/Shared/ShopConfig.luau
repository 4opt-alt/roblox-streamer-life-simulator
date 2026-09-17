--!strict

export type ShopCategory = "Gear" | "Game" | "Food" | "License"

export type ShopItem = {
    Id: string,
    Name: string,
    Category: ShopCategory,
    Price: number,
    MoneyBonusPerTick: number,
    HypeBonusPerTick: number,
    EnergyRestore: number,
    Description: string,
    IconText: string,
}

local ShopConfig: { [string]: ShopItem } = {
    -- 1. Steam Stream Games (Essential for viewers to tune in!)
    GameBlockcraft = {
        Id = "GameBlockcraft",
        Category = "Game",
        Name = "Steam Game: BlockCraft Voxel",
        Price = 30,
        MoneyBonusPerTick = 2,
        HypeBonusPerTick = 1,
        EnergyRestore = 0,
        Description = "First game to stream! Viewers stop complaining and start following (+ $2/s & +1 Sub/s).",
        IconText = "🧱",
    },
    GameCyberShooter = {
        Id = "GameCyberShooter",
        Category = "Game",
        Name = "Steam Game: CyberShooter 2026",
        Price = 190,
        MoneyBonusPerTick = 10,
        HypeBonusPerTick = 4,
        EnergyRestore = 0,
        Description = "Competitive FPS gameplay! Huge viewer retention and donation boost (+ $10/s & +4 Subs/s).",
        IconText = "🔫",
    },
    GameHorrorNight = {
        Id = "GameHorrorNight",
        Category = "Game",
        Name = "Steam Game: Horror Night Paranormal",
        Price = 550,
        MoneyBonusPerTick = 28,
        HypeBonusPerTick = 10,
        EnergyRestore = 0,
        Description = "Jumpscare reactions go viral on clips! Massive viewer spikes (+ $28/s & +10 Subs/s).",
        IconText = "👻",
    },

    -- 2. Hardware & Streamer Equipment (CyberByte Tech Store)
    Webcam720p = {
        Id = "Webcam720p",
        Category = "Gear",
        Name = "720p Facecam Pro",
        Price = 60,
        MoneyBonusPerTick = 3,
        HypeBonusPerTick = 1,
        EnergyRestore = 0,
        Description = "Add facecam reactions to your stream! Boosts donations (+ $3/s & +1 Sub/s).",
        IconText = "📹",
    },
    StudioMic = {
        Id = "StudioMic",
        Category = "Gear",
        Name = "Broadcast Studio Microphone",
        Price = 140,
        MoneyBonusPerTick = 6,
        HypeBonusPerTick = 2,
        EnergyRestore = 0,
        Description = "Crisp crystal-clear voice! Viewers love the audio quality (+ $6/s & +2 Subs/s).",
        IconText = "🎙️",
    },
    DualMonitors = {
        Id = "DualMonitors",
        Category = "Gear",
        Name = "Dual 165Hz Curved Screens",
        Price = 420,
        MoneyBonusPerTick = 18,
        HypeBonusPerTick = 6,
        EnergyRestore = 0,
        Description = "Chat on one screen, gaming on the other! Pro streamer setup (+ $18/s & +6 Subs/s).",
        IconText = "🖥️",
    },
    GamingRig = {
        Id = "GamingRig",
        Category = "Gear",
        Name = "RTX 5090 Liquid Battlestation",
        Price = 1200,
        MoneyBonusPerTick = 50,
        HypeBonusPerTick = 18,
        EnergyRestore = 0,
        Description = "Maximum 240 FPS streaming performance! Top-tier dream machine (+ $50/s & +18 Subs/s).",
        IconText = "⚡",
    },

    -- 3. Food & Energy Boosts (Burger & Snacks Mart)
    EnergyDrink = {
        Id = "EnergyDrink",
        Category = "Food",
        Name = "MegaVolt Energy Drink",
        Price = 10,
        MoneyBonusPerTick = 0,
        HypeBonusPerTick = 0,
        EnergyRestore = 35,
        Description = "Instant caffeine surge! Restores +35% Energy to prevent stream fatigue.",
        IconText = "⚡",
    },
    BurgerCombo = {
        Id = "BurgerCombo",
        Category = "Food",
        Name = "Cheeseburger & Fries Combo",
        Price = 22,
        MoneyBonusPerTick = 0,
        HypeBonusPerTick = 0,
        EnergyRestore = 75,
        Description = "Hearty meal for long streaming grinds! Restores +75% Energy.",
        IconText = "🍔",
    },

    -- 4. Multi-Stream License
    MultiStreamLicense = {
        Id = "MultiStreamLicense",
        Category = "License",
        Name = "Cross-Platform License (YouTube + Twitch)",
        Price = 350,
        MoneyBonusPerTick = 0,
        HypeBonusPerTick = 0,
        EnergyRestore = 0,
        Description = "Permanently unlocks Multi-Stream mode! Combines audiences for +85% Money and +50% Subs!",
        IconText = "📡",
    },
}

return ShopConfig
