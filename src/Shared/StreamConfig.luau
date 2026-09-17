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
        MultiplierPerRebirth = 0.50, -- +50% permanent boost per rebirth
        StarterCashBonusPerRebirth = 100, -- +$100 extra starting money per rebirth
        MaxEnergyBonusPerRebirth = 15,   -- +15 max energy capacity per rebirth
    },

    RebirthTiers = {
        [1] = {
            Level = 1,
            RequiredSubs = 100_000,
            RequiredMoney = 15_000,
            ButtonName = "YouTube Silver Play Button",
            ButtonNameUA = "Срібна кнопка YouTube",
            MilestoneText = "100,000 Subscribers",
            ButtonIcon = "🥈",
            TitleTag = "[🥈 Silver Creator]",
            PlaqueColor = Color3.fromRGB(225, 230, 240),
            GlowColor = Color3.fromRGB(200, 215, 255),
            Material = Enum.Material.Metal,
        },
        [2] = {
            Level = 2,
            RequiredSubs = 500_000,
            RequiredMoney = 75_000,
            ButtonName = "YouTube Gold Play Button",
            ButtonNameUA = "Золота кнопка YouTube",
            MilestoneText = "500,000 Subscribers",
            ButtonIcon = "🥇",
            TitleTag = "[🥇 Gold Creator]",
            PlaqueColor = Color3.fromRGB(255, 215, 0),
            GlowColor = Color3.fromRGB(255, 200, 50),
            Material = Enum.Material.Metal,
        },
        [3] = {
            Level = 3,
            RequiredSubs = 1_000_000,
            RequiredMoney = 250_000,
            ButtonName = "YouTube Diamond Play Button",
            ButtonNameUA = "Діамантова кнопка YouTube",
            MilestoneText = "1,000,000 Subscribers",
            ButtonIcon = "💎",
            TitleTag = "[💎 Diamond Creator]",
            PlaqueColor = Color3.fromRGB(150, 235, 255),
            GlowColor = Color3.fromRGB(80, 220, 255),
            Material = Enum.Material.Glass,
        },
        [4] = {
            Level = 4,
            RequiredSubs = 5_000_000,
            RequiredMoney = 1_000_000,
            ButtonName = "YouTube Custom Ruby Play Button",
            ButtonNameUA = "Рубінова кнопка YouTube",
            MilestoneText = "5,000,000 Subscribers",
            ButtonIcon = "🔴",
            TitleTag = "[🔴 Ruby Legend]",
            PlaqueColor = Color3.fromRGB(255, 40, 80),
            GlowColor = Color3.fromRGB(255, 60, 90),
            Material = Enum.Material.Neon,
        },
        [5] = {
            Level = 5,
            RequiredSubs = 10_000_000,
            RequiredMoney = 5_000_000,
            ButtonName = "YouTube Red Diamond Play Button",
            ButtonNameUA = "Червоний Діамант YouTube",
            MilestoneText = "10,000,000 Subscribers",
            ButtonIcon = "👑",
            TitleTag = "[👑 YouTube Royalty]",
            PlaqueColor = Color3.fromRGB(220, 20, 60),
            GlowColor = Color3.fromRGB(255, 30, 70),
            Material = Enum.Material.Glass,
        },
    },
}

function StreamConfig.GetRebirthRequirements(currentRebirths: number): (number, number)
    local nextLevel = (currentRebirths or 0) + 1
    local tier = (StreamConfig :: any).RebirthTiers[nextLevel]
    if tier then
        return tier.RequiredSubs, tier.RequiredMoney
    else
        local overflow = nextLevel - 5
        local reqSubs = math.floor(10_000_000 * math.pow(2.5, overflow))
        local reqMoney = math.floor(5_000_000 * math.pow(2.0, overflow))
        return reqSubs, reqMoney
    end
end

function StreamConfig.GetRebirthReward(nextRebirthLevel: number): any
    local tier = (StreamConfig :: any).RebirthTiers[nextRebirthLevel]
    if tier then
        return tier
    end
    return {
        Level = nextRebirthLevel,
        RequiredSubs = 10_000_000,
        RequiredMoney = 5_000_000,
        ButtonName = `YouTube Milestone ${nextRebirthLevel} Award`,
        ButtonNameUA = `Трофей YouTube ${nextRebirthLevel}-го рівня`,
        MilestoneText = `Rebirth Level ${nextRebirthLevel}`,
        ButtonIcon = "👑",
        TitleTag = `[👑 Creator Lv.{nextRebirthLevel}]`,
        PlaqueColor = Color3.fromRGB(255, 215, 0),
        GlowColor = Color3.fromRGB(255, 220, 80),
        Material = Enum.Material.Neon,
    }
end

return StreamConfig
