--!strict

export type EventChoice = {
    Id: string,
    Text: string,
    SuccessChance: number,          -- 0.0 to 1.0
    SuccessHypeMultiplier: number,  -- e.g. 0.10 = +10% of total subs
    FailHypeMultiplier: number,     -- e.g. -0.05 = -5% of total subs
    MoneyReward: number,
    SuccessMessage: string,
    FailMessage: string,
}

export type StreamEvent = {
    Id: string,
    Title: string,
    Situation: string,
    TimeoutSeconds: number,
    Choices: { EventChoice },
}

local StreamEventsConfig: { StreamEvent } = {
    {
        Id = "ToxicHater",
        Title = "⚠️ Toxic Hater in Chat!",
        Situation = "A toxic viewer writes: 'YOU SUCK AT THIS GAME, UNINSTALL AND GO WORK AT BURGER MART!'",
        TimeoutSeconds = 9,
        Choices = {
            {
                Id = "RoastHater",
                Text = "🔥 Roast them with a sharp joke (+10% / -5% Subs)",
                SuccessChance = 0.75,
                SuccessHypeMultiplier = 0.10, -- 1000 subs -> +100 | 50 subs -> +5
                FailHypeMultiplier = -0.05,   -- 1000 subs -> -50  | 50 subs -> -3
                MoneyReward = 15,
                SuccessMessage = "Chat explodes with laughter: 'SAVAGE W'!",
                FailMessage = "Your joke sounded awkward... Chat spammed 'L'!",
            },
            {
                Id = "IgnoreAndBan",
                Text = "🛡️ Ignore & Silently Ban (+4% Subs Safe)",
                SuccessChance = 1.0,
                SuccessHypeMultiplier = 0.04, -- 1000 subs -> +40 | 50 subs -> +2
                FailHypeMultiplier = 0,
                MoneyReward = 5,
                SuccessMessage = "Clean chat preserved! Viewers respect your calm.",
                FailMessage = "",
            },
        },
    },
    {
        Id = "TrickshotMoment",
        Title = "🎯 High-Stakes Clutch Moment!",
        Situation = "You're in a 1v1 standoff in the final circle! Chat is holding their breath!",
        TimeoutSeconds = 9,
        Choices = {
            {
                Id = "GoFor360",
                Text = "⚡ Attempt a crazy 360 no-scope (+15% / -6% Subs)",
                SuccessChance = 0.65,
                SuccessHypeMultiplier = 0.15, -- 1000 subs -> +150 | 50 subs -> +8
                FailHypeMultiplier = -0.06,   -- 1000 subs -> -60  | 50 subs -> -3
                MoneyReward = 25,
                SuccessMessage = "UNBELIEVABLE CLUTCH! Clip went viral everywhere!",
                FailMessage = "You whiffed completely and fell off the ledge. Oof!",
            },
            {
                Id = "PlaySafe",
                Text = "🛡️ Play corners and take the safe win (+6% Subs)",
                SuccessChance = 1.0,
                SuccessHypeMultiplier = 0.06,
                FailHypeMultiplier = 0,
                MoneyReward = 10,
                SuccessMessage = "Smart tactical victory! Chat celebrates the win.",
                FailMessage = "",
            },
        },
    },
    {
        Id = "DonationPushups",
        Title = "💰 Spicy Donation Pushups Dare!",
        Situation = "A generous viewer donates and writes: 'Do 20 pushups on cam right now or no balls!'",
        TimeoutSeconds = 9,
        Choices = {
            {
                Id = "DoPushups",
                Text = "💪 Drop down and pump out 20 pushups! (+10% / -5% Subs)",
                SuccessChance = 0.85,
                SuccessHypeMultiplier = 0.10,
                FailHypeMultiplier = -0.05,
                MoneyReward = 35,
                SuccessMessage = "Impressive form! The donor dropped an extra \$35 tip!",
                FailMessage = "You gave up at rep 6... Chat is laughing at you!",
            },
            {
                Id = "PolitePass",
                Text = "☕ 'Thanks, but we're here to game!' (+3% Subs)",
                SuccessChance = 1.0,
                SuccessHypeMultiplier = 0.03,
                FailHypeMultiplier = 0,
                MoneyReward = 8,
                SuccessMessage = "Streamer stayed on grind. Small donation received.",
                FailMessage = "",
            },
        },
    },
    {
        Id = "GameCrash",
        Title = "⚡ Game Suddenly Crashed!",
        Situation = "Right during intense gameplay, your screen goes black and the game freezes!",
        TimeoutSeconds = 9,
        Choices = {
            {
                Id = "EntertainChat",
                Text = "🎙️ Tell a hilarious story while rebooting (+10% / -5% Subs)",
                SuccessChance = 0.80,
                SuccessHypeMultiplier = 0.10,
                FailHypeMultiplier = -0.05,
                MoneyReward = 12,
                SuccessMessage = "Story was so funny nobody even noticed the crash!",
                FailMessage = "Story dragged on and viewers started clicking away...",
            },
            {
                Id = "BlamePC",
                Text = "💻 Rage at PC and swear to upgrade at CyberByte (+5% / -8% Subs)",
                SuccessChance = 0.40,
                SuccessHypeMultiplier = 0.05,
                FailHypeMultiplier = -0.08,
                MoneyReward = 0,
                SuccessMessage = "Your desk slam was turned into a viral meme!",
                FailMessage = "Viewers left due to too much salt in chat!",
            },
        },
    },
    {
        Id = "StreamRaid",
        Title = "🚀 Surprise Stream Raid!",
        Situation = "A famous partner streamer just raided your channel with a wave of viewers!",
        TimeoutSeconds = 9,
        Choices = {
            {
                Id = "HypeSpeech",
                Text = "🎉 Give an energetic welcome speech! (+18% / -5% Subs)",
                SuccessChance = 0.85,
                SuccessHypeMultiplier = 0.18,
                FailHypeMultiplier = -0.05,
                MoneyReward = 30,
                SuccessMessage = "Raiders loved the energy and smashed that follow button!",
                FailMessage = "You panicked and stumbled over words... Raiders left.",
            },
            {
                Id = "PlayCool",
                Text = "😎 Stay chill and casually thank them (+8% Subs)",
                SuccessChance = 1.0,
                SuccessHypeMultiplier = 0.08,
                FailHypeMultiplier = 0,
                MoneyReward = 15,
                SuccessMessage = "Smooth and confident! Respect from the raiding community.",
                FailMessage = "",
            },
        },
    },
}

return StreamEventsConfig
