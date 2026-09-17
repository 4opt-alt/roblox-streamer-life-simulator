--!strict

export type PlatformInfo = {
    Id: string,
    Name: string,
    ColorHex: string,
    MoneyMultiplier: number,
    HypeMultiplier: number,
    Description: string,
    RequiresLicense: boolean,
    LicensePrice: number,
}

export type CategoryInfo = {
    Id: string,
    Name: string,
    Device: string,
    Description: string,
    Icon: string,
    ColorHex: string,
    MoneyMultiplier: number,
    HypeMultiplier: number,
    RequiresPC: boolean,
}

export type ConfigType = {
    IncomeIntervalSeconds: number,
    StarterMoney: number,
    StarterHype: number,
    BaseDonationChance: number,
    BaseSubChance: number,
    MaxEnergy: number,
    EnergyDrainSeconds: number,
    EnergyDrainPerSecond: number?,
    EnergyRestRecoverySeconds: number?,
    EventCycleDurationSeconds: number,
    EventBoostDurationSeconds: number,
    EventMoneyMultiplier: number,
    CommentIntervalMin: number,
    CommentIntervalMax: number,
    MaxChatHistory: number,
    MinChannelNameLength: number,
    MaxChannelNameLength: number,
    Platforms: { [string]: PlatformInfo },
    Categories: { [string]: CategoryInfo },
    ViewerComments: { string },
    IRLComments: { string }?,
    GamingComments: { string }?,
    JustChattingComments: { string }?,
    LowEnergyComments: { string },
    NoGameComments: { string },
    ProComments: { string },
    ViewerNames: { string },
    Rebirth: any?,
}

local StreamConfig: ConfigType = {
    -- Streamer progression economy
    IncomeIntervalSeconds = 1,
    StarterMoney = 15,          -- Starting pocket change: $15
    StarterHype = 0,            -- 0 Subscribers at start
    BaseDonationChance = 0.90,  -- 90% chance to earn money each second
    BaseSubChance = 0.95,       -- 95% chance to gain subscribers each second
    MaxEnergy = 100,
    EnergyDrainSeconds = 1,     -- Energy check interval
    EnergyDrainPerSecond = 1.5, -- -1.5% Energy per second of streaming (~65s stream)
    EnergyRestRecoverySeconds = 1.5, -- Rest recovery: +3% energy every 1.5s when not streaming

    -- Hourly Boost Event Settings
    EventCycleDurationSeconds = 3600,
    EventBoostDurationSeconds = 600,
    EventMoneyMultiplier = 1.5,

    -- Dynamic Viewer Comments
    CommentIntervalMin = 1.5,
    CommentIntervalMax = 3.5,
    MaxChatHistory = 40,

    -- Channel Name Rules
    MinChannelNameLength = 3,
    MaxChannelNameLength = 20,

    -- Streaming Platforms
    Platforms = {
        YouTube = {
            Id = "YouTube",
            Name = "YouTube Live",
            ColorHex = "#FF0000",
            MoneyMultiplier = 1.0,
            HypeMultiplier = 1.0,
            Description = "Balanced revenue and subscriber growth. Best for beginner streamers.",
            RequiresLicense = false,
            LicensePrice = 0,
        },
        Twitch = {
            Id = "Twitch",
            Name = "Twitch",
            ColorHex = "#9146FF",
            MoneyMultiplier = 1.35,
            HypeMultiplier = 1.0,
            Description = "Higher donation culture! +35% Money earnings per stream second.",
            RequiresLicense = false,
            LicensePrice = 0,
        },
        TikTok = {
            Id = "TikTok",
            Name = "TikTok Live",
            ColorHex = "#00F2FE",
            MoneyMultiplier = 1.0,
            HypeMultiplier = 1.60,
            Description = "Viral recommendation algorithm! +60% Subscriber gain per stream second.",
            RequiresLicense = false,
            LicensePrice = 0,
        },
        MultiStream = {
            Id = "MultiStream",
            Name = "Split Stream (YT+Twitch)",
            ColorHex = "#FFAA00",
            MoneyMultiplier = 1.85,
            HypeMultiplier = 1.50,
            Description = "Split broadcast to YouTube + Twitch simultaneously! +85% Money and +50% Subs bonus! (Robux Exclusive)",
            RequiresLicense = true,
            LicensePrice = 0, -- Robux Exclusive!
        },
    },

    -- Categories (IRL = Phone anywhere, Gaming & Just Chatting = PC Battlestation)
    Categories = {
        IRL = {
            Id = "IRL",
            Name = "📱 IRL",
            Device = "Phone",
            Description = "Mobile stream on phone! Roam anywhere in the city.",
            Icon = "📱",
            ColorHex = "#00F2FE",
            MoneyMultiplier = 1.0,
            HypeMultiplier = 1.35,
            RequiresPC = false,
        },
        Gaming = {
            Id = "Gaming",
            Name = "🎮 Gaming",
            Device = "PC",
            Description = "Stream PC games at your Battlestation desk! +Bonus from Steam games.",
            Icon = "🎮",
            ColorHex = "#9B51E0",
            MoneyMultiplier = 1.35,
            HypeMultiplier = 1.15,
            RequiresPC = true,
        },
        JustChatting = {
            Id = "JustChatting",
            Name = "🎙️ Just Chatting",
            Device = "PC",
            Description = "Talk show at your computer desk! High community donations and superchats.",
            Icon = "🎙️",
            ColorHex = "#FF9900",
            MoneyMultiplier = 1.45,
            HypeMultiplier = 1.10,
            RequiresPC = true,
        },
    },

    IRLComments = {
        "Where are you heading today?",
        "Show us the car!!",
        "Burger Mart mukbang stream??",
        "Nice weather out there!",
        "Watch the street lol",
        "IRL streams are so entertaining!",
    },

    GamingComments = {
        "POG play!!",
        "Insane clutch bro!",
        "What rank are you in this game?",
        "240 FPS looks buttery clean!",
        "Nice gameplay!",
        "Streamer cracked at games!",
    },

    JustChattingComments = {
        "Deep thoughts today!",
        "Facts, speak on it!",
        "LMAO so true!",
        "Read my superchat please!!",
        "Best podcast / talk show!",
        "Sending $5 for the great advice!",
    },

    -- Dynamic Comments based on Streamer Status
    ViewerComments = {
        "hello streamer!",
        "what are we doing today?",
        "clip that!!",
        "drop some hype in chat!",
        "W stream!",
        "greeting from Ukraine!",
        "let's gooooo!",
        "subbed!!",
    },

    NoGameComments = {
        "bro buy some games from CyberByte Tech lol",
        "streamer has 0 games installed ResidentSleeper",
        "play BlockCraft please!",
        "why we just sitting in an empty room?",
        "buy a Steam game bro",
    },

    LowEnergyComments = {
        "streamer looks so tired lmao",
        "bro go to Burger Mart and eat something!",
        "get an energy drink stat!",
        "he's gonna pass out on keyboard",
        "energy is on 5% lol",
    },

    ProComments = {
        "THIS SETUP IS INSANE!",
        "Take my donation! $10 well deserved!",
        "Best streamer on the platform!",
        "Top 1 Wall of Fame incoming!",
        "240 FPS looking buttery smooth!",
        "The graphics and mic are so crisp!",
    },

    ViewerNames = {
        "GamerX_99",
        "PixelNinja",
        "ShadowRider",
        "NeonValkyrie",
        "TurboSlayer",
        "CoolGuy_UA",
        "CyberWolf",
        "StarWatcher",
        "RoboFanatic",
        "GlitchMaster",
        "Vortex99",
        "EchoStream",
    },

    Rebirth = {
        BaseRequiredSubs = 500,
        BaseRequiredMoney = 250,
        MultiplierPerRebirth = 0.50, -- +50% permanent boost per rebirth
        StarterCashBonusPerRebirth = 50, -- +$50 extra starting money per rebirth
        MaxEnergyBonusPerRebirth = 10,   -- +10 max energy capacity per rebirth
    },
}

function StreamConfig.GetRebirthRequirements(currentRebirths: number): (number, number)
    local r = currentRebirths or 0
    local scale = math.pow(1.5, r)
    local reqSubs = math.floor(StreamConfig.Rebirth.BaseRequiredSubs * scale)
    local reqMoney = math.floor(StreamConfig.Rebirth.BaseRequiredMoney * scale)
    return reqSubs, reqMoney
end

return StreamConfig
