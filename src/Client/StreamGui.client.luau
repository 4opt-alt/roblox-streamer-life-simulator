--!strict
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StreamConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("StreamConfig") :: ModuleScript)

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
local performRebirthRemote = remotesFolder:WaitForChild("PerformRebirth") :: RemoteEvent
local rebirthResultRemote = remotesFolder:WaitForChild("RebirthResult") :: RemoteEvent
local setStreamCategoryRemote = remotesFolder:WaitForChild("SetStreamCategory") :: RemoteEvent

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StreamGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

--------------------------------------------------------------------------------
-- 0. Hourly Boost Event Banner (Top-Center HUD)
--------------------------------------------------------------------------------
local eventBanner = Instance.new("Frame")
eventBanner.Name = "EventBanner"
eventBanner.Size = UDim2.new(0, 310, 0, 36)
eventBanner.Position = UDim2.new(0.5, -155, 0.02, 0)
eventBanner.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
eventBanner.BackgroundTransparency = 0.25
eventBanner.BorderSizePixel = 0
eventBanner.Parent = screenGui

local bannerCorner = Instance.new("UICorner")
bannerCorner.CornerRadius = UDim.new(0, 18)
bannerCorner.Parent = eventBanner

local bannerStroke = Instance.new("UIStroke")
bannerStroke.Name = "BannerStroke"
bannerStroke.Color = Color3.fromRGB(52, 152, 219)
bannerStroke.Thickness = 1.5
bannerStroke.Parent = eventBanner

local bannerText = Instance.new("TextLabel")
bannerText.Name = "BannerText"
bannerText.Size = UDim2.new(1, 0, 1, 0)
bannerText.BackgroundTransparency = 1
bannerText.Font = Enum.Font.GothamBold
bannerText.TextSize = 13
bannerText.TextColor3 = Color3.fromRGB(240, 245, 255)
bannerText.Text = "⏰ Hourly Boost: Loading..."
bannerText.Parent = eventBanner

-- Listen to Event State
task.spawn(function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local eventFolder = ReplicatedStorage:WaitForChild("EventState", 15) :: Folder?
    if not eventFolder then return end

    local isBoostActiveObj = eventFolder:WaitForChild("IsBoostActive") :: BoolValue
    local remainingSecObj = eventFolder:WaitForChild("RemainingSeconds") :: IntValue

    local function updateBanner()
        local isActive = isBoostActiveObj.Value
        local sec = remainingSecObj.Value
        local mins = math.floor(sec / 60)
        local secs = sec % 60
        local timeFormatted = string.format("%02d:%02d", mins, secs)

        if isActive then
            bannerStroke.Color = Color3.fromRGB(255, 170, 0)
            eventBanner.BackgroundColor3 = Color3.fromRGB(45, 25, 15)
            bannerText.TextColor3 = Color3.fromRGB(255, 220, 100)
            bannerText.Text = `🔥 1.5x BOOST ACTIVE! ({timeFormatted})`
        else
            bannerStroke.Color = Color3.fromRGB(52, 152, 219)
            eventBanner.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
            bannerText.TextColor3 = Color3.fromRGB(220, 225, 235)
            bannerText.Text = `⏰ Next 1.5x Boost in: {timeFormatted}`
        end
    end

    isBoostActiveObj.Changed:Connect(updateBanner)
    remainingSecObj.Changed:Connect(updateBanner)
    updateBanner()
end)

--------------------------------------------------------------------------------
-- 0.5. Stream Category Selector (📱 IRL on Phone vs 🎮 Gaming / 🎙️ Talk on PC)
--------------------------------------------------------------------------------
local categoryHintLabel = Instance.new("TextLabel")
categoryHintLabel.Name = "CategoryHintLabel"
categoryHintLabel.Size = UDim2.new(0, 420, 0, 18)
categoryHintLabel.Position = UDim2.new(0.5, -210, 0.785, 0)
categoryHintLabel.BackgroundTransparency = 1
categoryHintLabel.Font = Enum.Font.GothamMedium
categoryHintLabel.TextSize = 11
categoryHintLabel.TextColor3 = Color3.fromRGB(200, 215, 240)
categoryHintLabel.Text = "🎮 PC Gaming: Stream at your Computer Battlestation! (+Steam Games Bonus)"
categoryHintLabel.Parent = screenGui

local categoryBar = Instance.new("Frame")
categoryBar.Name = "CategoryBar"
categoryBar.Size = UDim2.new(0, 400, 0, 34)
categoryBar.Position = UDim2.new(0.5, -200, 0.818, 0)
categoryBar.BackgroundTransparency = 1
categoryBar.Parent = screenGui

local catLayout = Instance.new("UIListLayout")
catLayout.FillDirection = Enum.FillDirection.Horizontal
catLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
catLayout.VerticalAlignment = Enum.VerticalAlignment.Center
catLayout.Padding = UDim.new(0, 8)
catLayout.Parent = categoryBar

local function createCategoryBtn(id: string, text: string)
    local btn = Instance.new("TextButton")
    btn.Name = `CatBtn_{id}`
    btn.Size = UDim2.new(0, 124, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(25, 28, 38)
    btn.TextColor3 = Color3.fromRGB(180, 195, 220)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Text = text
    btn.Parent = categoryBar

    local cCorner = Instance.new("UICorner"); cCorner.CornerRadius = UDim.new(0, 8); cCorner.Parent = btn
    local cStroke = Instance.new("UIStroke"); cStroke.Color = Color3.fromRGB(50, 60, 80); cStroke.Thickness = 1.2; cStroke.Parent = btn

    return btn, cStroke
end

local btnIRL, strokeIRL = createCategoryBtn("IRL", "📱 IRL (Phone)")
local btnGaming, strokeGaming = createCategoryBtn("Gaming", "🎮 Gaming (PC)")
local btnChatting, strokeChatting = createCategoryBtn("JustChatting", "🎙️ Chatting (PC)")

local currentCategory = "Gaming"

local function updateCategoryUI()
    local cat = (LocalPlayer:GetAttribute("StreamCategory") :: string?) or currentCategory
    currentCategory = cat

    -- Reset all
    btnIRL.BackgroundColor3 = Color3.fromRGB(22, 26, 36)
    btnIRL.TextColor3 = Color3.fromRGB(160, 175, 200)
    strokeIRL.Color = Color3.fromRGB(45, 55, 75)
    strokeIRL.Thickness = 1

    btnGaming.BackgroundColor3 = Color3.fromRGB(22, 26, 36)
    btnGaming.TextColor3 = Color3.fromRGB(160, 175, 200)
    strokeGaming.Color = Color3.fromRGB(45, 55, 75)
    strokeGaming.Thickness = 1

    btnChatting.BackgroundColor3 = Color3.fromRGB(22, 26, 36)
    btnChatting.TextColor3 = Color3.fromRGB(160, 175, 200)
    strokeChatting.Color = Color3.fromRGB(45, 55, 75)
    strokeChatting.Thickness = 1

    if cat == "IRL" then
        btnIRL.BackgroundColor3 = Color3.fromRGB(0, 80, 100)
        btnIRL.TextColor3 = Color3.fromRGB(0, 242, 254)
        strokeIRL.Color = Color3.fromRGB(0, 242, 254)
        strokeIRL.Thickness = 2
        categoryHintLabel.Text = "📱 IRL Mode: Mobile stream on phone anywhere! Walk, drive, explore shops."
        categoryHintLabel.TextColor3 = Color3.fromRGB(0, 242, 254)
    elseif cat == "JustChatting" then
        btnChatting.BackgroundColor3 = Color3.fromRGB(70, 45, 10)
        btnChatting.TextColor3 = Color3.fromRGB(255, 180, 50)
        strokeChatting.Color = Color3.fromRGB(255, 160, 20)
        strokeChatting.Thickness = 2
        categoryHintLabel.Text = "🎙️ Just Chatting: Studio talk show on PC! High chat donations & superchats."
        categoryHintLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
    else
        btnGaming.BackgroundColor3 = Color3.fromRGB(55, 25, 80)
        btnGaming.TextColor3 = Color3.fromRGB(210, 140, 255)
        strokeGaming.Color = Color3.fromRGB(180, 90, 255)
        strokeGaming.Thickness = 2
        categoryHintLabel.Text = "🎮 PC Gaming: Stream at your Computer Battlestation! +Bonus from Steam games."
        categoryHintLabel.TextColor3 = Color3.fromRGB(210, 160, 255)
    end
end

local function onCategoryClick(catKey: string)
    currentCategory = catKey
    LocalPlayer:SetAttribute("StreamCategory", catKey)
    setStreamCategoryRemote:FireServer(catKey)
    updateCategoryUI()
end

btnIRL.MouseButton1Click:Connect(function() onCategoryClick("IRL") end)
btnGaming.MouseButton1Click:Connect(function() onCategoryClick("Gaming") end)
btnChatting.MouseButton1Click:Connect(function() onCategoryClick("JustChatting") end)

LocalPlayer:GetAttributeChangedSignal("StreamCategory"):Connect(updateCategoryUI)
updateCategoryUI()

--------------------------------------------------------------------------------
-- 1. Stream Control Button
--------------------------------------------------------------------------------
local streamButton = Instance.new("TextButton")
streamButton.Name = "StreamButton"
streamButton.Size = UDim2.new(0, 200, 0, 50)
streamButton.Position = UDim2.new(0.5, -100, 0.88, 0)
streamButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
streamButton.TextColor3 = Color3.fromRGB(255, 255, 255)
streamButton.Font = Enum.Font.GothamBold
streamButton.TextSize = 18
streamButton.Text = "▶ Start Stream"
streamButton.AutoButtonColor = false
streamButton.Parent = screenGui

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 12)
buttonCorner.Parent = streamButton

local buttonStroke = Instance.new("UIStroke")
buttonStroke.Color = Color3.fromRGB(255, 255, 255)
buttonStroke.Transparency = 0.8
buttonStroke.Thickness = 1.5
buttonStroke.Parent = streamButton

-- Click animation
streamButton.MouseButton1Down:Connect(function()
    TweenService:Create(streamButton, TweenInfo.new(0.1), {
        Size = UDim2.new(0, 190, 0, 46),
        Position = UDim2.new(0.5, -95, 0.88, 2),
    }):Play()
end)

streamButton.MouseButton1Up:Connect(function()
    TweenService:Create(streamButton, TweenInfo.new(0.1), {
        Size = UDim2.new(0, 200, 0, 50),
        Position = UDim2.new(0.5, -100, 0.88, 0),
    }):Play()
end)

--------------------------------------------------------------------------------
-- 2. Rebirth HUD Bar & Rebirth Modal Window
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 2. Modern Unified Streamer Hub (All-in-One Left Dashboard Panel)
--------------------------------------------------------------------------------
local streamerHub = Instance.new("Frame")
streamerHub.Name = "StreamerHub"
streamerHub.Size = UDim2.new(0, 320, 0, 340)
streamerHub.Position = UDim2.new(0.015, 0, 0.44, 0)
streamerHub.BackgroundColor3 = Color3.fromRGB(15, 18, 26)
streamerHub.BackgroundTransparency = 0.12
streamerHub.BorderSizePixel = 0
streamerHub.Parent = screenGui

local hubCorner = Instance.new("UICorner"); hubCorner.CornerRadius = UDim.new(0, 12); hubCorner.Parent = streamerHub
local hubStroke = Instance.new("UIStroke"); hubStroke.Color = Color3.fromRGB(48, 58, 80); hubStroke.Thickness = 1.2; hubStroke.Parent = streamerHub

-- Row 1: Channel Title + Quick Edit + Rebirth Badge
local channelBar = Instance.new("Frame")
channelBar.Name = "ChannelBar"
channelBar.Size = UDim2.new(1, -16, 0, 32)
channelBar.Position = UDim2.new(0, 8, 0, 8)
channelBar.BackgroundColor3 = Color3.fromRGB(22, 27, 38)
channelBar.BorderSizePixel = 0
channelBar.Parent = streamerHub

local cbCorner = Instance.new("UICorner"); cbCorner.CornerRadius = UDim.new(0, 8); cbCorner.Parent = channelBar
local cbStroke = Instance.new("UIStroke"); cbStroke.Color = Color3.fromRGB(45, 55, 75); cbStroke.Thickness = 1; cbStroke.Parent = channelBar

local channelTitleLabel = Instance.new("TextLabel")
channelTitleLabel.Name = "ChannelTitleLabel"
channelTitleLabel.Size = UDim2.new(1, -125, 1, 0)
channelTitleLabel.Position = UDim2.new(0, 8, 0, 0)
channelTitleLabel.BackgroundTransparency = 1
channelTitleLabel.Font = Enum.Font.GothamBold
channelTitleLabel.TextSize = 13
channelTitleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
channelTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
channelTitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
channelTitleLabel.Text = "📺 Channel: Loading..."
channelTitleLabel.Parent = channelBar

local editChannelButton = Instance.new("TextButton")
editChannelButton.Name = "EditChannelButton"
editChannelButton.Size = UDim2.new(0, 24, 0, 24)
editChannelButton.Position = UDim2.new(1, -120, 0.5, -12)
editChannelButton.BackgroundColor3 = Color3.fromRGB(35, 45, 65)
editChannelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
editChannelButton.Font = Enum.Font.GothamBold
editChannelButton.TextSize = 12
editChannelButton.Text = "✏️"
editChannelButton.Parent = channelBar
local ecCorner = Instance.new("UICorner"); ecCorner.CornerRadius = UDim.new(0, 6); ecCorner.Parent = editChannelButton

local rebirthHudBtn = Instance.new("TextButton")
rebirthHudBtn.Name = "RebirthHudBtn"
rebirthHudBtn.Size = UDim2.new(0, 90, 0, 24)
rebirthHudBtn.Position = UDim2.new(1, -92, 0.5, -12)
rebirthHudBtn.BackgroundColor3 = Color3.fromRGB(95, 40, 150)
rebirthHudBtn.TextColor3 = Color3.fromRGB(255, 235, 120)
rebirthHudBtn.Font = Enum.Font.GothamBold
rebirthHudBtn.TextSize = 11
rebirthHudBtn.Text = "🔄 REBIRTH (Lv. 0)"
rebirthHudBtn.Parent = channelBar
local rhbCorner = Instance.new("UICorner"); rhbCorner.CornerRadius = UDim.new(0, 6); rhbCorner.Parent = rebirthHudBtn
local rhbStroke = Instance.new("UIStroke"); rhbStroke.Color = Color3.fromRGB(255, 215, 0); rhbStroke.Thickness = 1.2; rhbStroke.Parent = rebirthHudBtn

-- Row 2: Contract Badge & Live Platform Indicators
local platformsRowBar = Instance.new("Frame")
platformsRowBar.Name = "PlatformsRowBar"
platformsRowBar.Size = UDim2.new(1, -16, 0, 24)
platformsRowBar.Position = UDim2.new(0, 8, 0, 44)
platformsRowBar.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
platformsRowBar.BorderSizePixel = 0
platformsRowBar.Parent = streamerHub

local prCorner = Instance.new("UICorner"); prCorner.CornerRadius = UDim.new(0, 6); prCorner.Parent = platformsRowBar
local prStroke = Instance.new("UIStroke"); prStroke.Color = Color3.fromRGB(42, 50, 68); prStroke.Thickness = 1; prStroke.Parent = platformsRowBar

local contractHudBtn = Instance.new("TextButton")
contractHudBtn.Name = "ContractHudBtn"
contractHudBtn.Size = UDim2.new(0, 125, 1, 0)
contractHudBtn.Position = UDim2.new(0, 6, 0, 0)
contractHudBtn.BackgroundTransparency = 1
contractHudBtn.Font = Enum.Font.GothamBold
contractHudBtn.TextSize = 10
contractHudBtn.TextColor3 = Color3.fromRGB(180, 210, 255)
contractHudBtn.TextXAlignment = Enum.TextXAlignment.Left
contractHudBtn.Text = "📡 Contract: None ⚠️"
contractHudBtn.Parent = platformsRowBar

local function updateContractBadge()
    local locked = LocalPlayer:GetAttribute("LockedPlatform")
    if locked and locked ~= "" then
        contractHudBtn.Text = `📡 {locked:gsub("+", "+")} 🔒`
        contractHudBtn.TextColor3 = Color3.fromRGB(120, 240, 160)
    else
        contractHudBtn.Text = "📡 Pick Platform ⚠️"
        contractHudBtn.TextColor3 = Color3.fromRGB(255, 200, 80)
    end
end

LocalPlayer:GetAttributeChangedSignal("LockedPlatform"):Connect(updateContractBadge)
updateContractBadge()

contractHudBtn.MouseButton1Click:Connect(function()
    if _G.OpenPlatformSelect then
        _G.OpenPlatformSelect(false)
    end
end)

local pillsFrame = Instance.new("Frame")
pillsFrame.Size = UDim2.new(0, 168, 1, 0)
pillsFrame.Position = UDim2.new(1, -170, 0, 0)
pillsFrame.BackgroundTransparency = 1
pillsFrame.Parent = platformsRowBar

local prLayout = Instance.new("UIListLayout")
prLayout.FillDirection = Enum.FillDirection.Horizontal
prLayout.Padding = UDim.new(0, 4)
prLayout.VerticalAlignment = Enum.VerticalAlignment.Center
prLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
prLayout.Parent = pillsFrame

local ytPill = Instance.new("TextLabel")
ytPill.Name = "YtPill"
ytPill.Size = UDim2.new(0, 52, 0, 18)
ytPill.BackgroundColor3 = Color3.fromRGB(26, 30, 42)
ytPill.Font = Enum.Font.GothamBold
ytPill.TextSize = 9
ytPill.TextColor3 = Color3.fromRGB(140, 150, 170)
ytPill.Text = "🔴 YT ○"
ytPill.Parent = pillsFrame
local ypCorner = Instance.new("UICorner"); ypCorner.CornerRadius = UDim.new(0, 4); ypCorner.Parent = ytPill

local twitchPill = Instance.new("TextLabel")
twitchPill.Name = "TwitchPill"
twitchPill.Size = UDim2.new(0, 52, 0, 18)
twitchPill.BackgroundColor3 = Color3.fromRGB(26, 30, 42)
twitchPill.Font = Enum.Font.GothamBold
twitchPill.TextSize = 9
twitchPill.TextColor3 = Color3.fromRGB(140, 150, 170)
twitchPill.Text = "🟣 TW ○"
twitchPill.Parent = pillsFrame
local tpCorner = Instance.new("UICorner"); tpCorner.CornerRadius = UDim.new(0, 4); tpCorner.Parent = twitchPill

local tiktokPill = Instance.new("TextLabel")
tiktokPill.Name = "TiktokPill"
tiktokPill.Size = UDim2.new(0, 52, 0, 18)
tiktokPill.BackgroundColor3 = Color3.fromRGB(26, 30, 42)
tiktokPill.Font = Enum.Font.GothamBold
tiktokPill.TextSize = 9
tiktokPill.TextColor3 = Color3.fromRGB(140, 150, 170)
tiktokPill.Text = "🎵 TT ○"
tiktokPill.Parent = pillsFrame
local tkCorner = Instance.new("UICorner"); tkCorner.CornerRadius = UDim.new(0, 4); tkCorner.Parent = tiktokPill

local function updatePlatformsRow()
    local isYT = LocalPlayer:GetAttribute("IsStreamingYouTube") == true
    local isTwitch = LocalPlayer:GetAttribute("IsStreamingTwitch") == true
    local isTikTok = LocalPlayer:GetAttribute("IsStreamingTikTok") == true

    if isYT then
        ytPill.BackgroundColor3 = Color3.fromRGB(180, 20, 20)
        ytPill.TextColor3 = Color3.fromRGB(255, 255, 255)
        ytPill.Text = "🔴 YT ●"
    else
        ytPill.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
        ytPill.TextColor3 = Color3.fromRGB(120, 130, 150)
        ytPill.Text = "🔴 YT ○"
    end

    if isTwitch then
        twitchPill.BackgroundColor3 = Color3.fromRGB(130, 40, 220)
        twitchPill.TextColor3 = Color3.fromRGB(255, 255, 255)
        twitchPill.Text = "🟣 TW ●"
    else
        twitchPill.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
        twitchPill.TextColor3 = Color3.fromRGB(120, 130, 150)
        twitchPill.Text = "🟣 TW ○"
    end

    if isTikTok then
        tiktokPill.BackgroundColor3 = Color3.fromRGB(0, 160, 180)
        tiktokPill.TextColor3 = Color3.fromRGB(255, 255, 255)
        tiktokPill.Text = "🎵 TT ●"
    else
        tiktokPill.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
        tiktokPill.TextColor3 = Color3.fromRGB(120, 130, 150)
        tiktokPill.Text = "🎵 TT ○"
    end
end

LocalPlayer:GetAttributeChangedSignal("IsStreamingYouTube"):Connect(updatePlatformsRow)
LocalPlayer:GetAttributeChangedSignal("IsStreamingTwitch"):Connect(updatePlatformsRow)
LocalPlayer:GetAttributeChangedSignal("IsStreamingTikTok"):Connect(updatePlatformsRow)
updatePlatformsRow()

-- Row 3: Setup Quality Rank + Compact Energy Meter
local setupBadge = Instance.new("Frame")
setupBadge.Name = "SetupBadge"
setupBadge.Size = UDim2.new(1, -16, 0, 22)
setupBadge.Position = UDim2.new(0, 8, 0, 72)
setupBadge.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
setupBadge.BorderSizePixel = 0
setupBadge.Parent = streamerHub

local sCorner = Instance.new("UICorner"); sCorner.CornerRadius = UDim.new(0, 6); sCorner.Parent = setupBadge
local sStroke = Instance.new("UIStroke"); sStroke.Color = Color3.fromRGB(42, 50, 68); sStroke.Thickness = 1; sStroke.Parent = setupBadge

local setupLabel = Instance.new("TextLabel")
setupLabel.Name = "SetupLabel"
setupLabel.Size = UDim2.new(0.58, 0, 1, 0)
setupLabel.Position = UDim2.new(0, 6, 0, 0)
setupLabel.BackgroundTransparency = 1
setupLabel.Font = Enum.Font.GothamBold
setupLabel.TextSize = 10
setupLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
setupLabel.TextXAlignment = Enum.TextXAlignment.Left
setupLabel.Text = "⭐ Potato (0G, 0Eq)"
setupLabel.Parent = setupBadge

local function updateSetupBadge()
    local rank = LocalPlayer:GetAttribute("StreamRankTitle") or "Potato Setup"
    local games = LocalPlayer:GetAttribute("GamesOwnedCount") or 0
    local gear = LocalPlayer:GetAttribute("GearOwnedCount") or 0
    local shortRank = rank:gsub(" Setup", ""):gsub(" Battlestation", ""):gsub(" Creator", "")
    setupLabel.Text = `⭐ {shortRank} ({games}G, {gear}Eq)`
end

LocalPlayer:GetAttributeChangedSignal("StreamRankTitle"):Connect(updateSetupBadge)
LocalPlayer:GetAttributeChangedSignal("GamesOwnedCount"):Connect(updateSetupBadge)
LocalPlayer:GetAttributeChangedSignal("GearOwnedCount"):Connect(updateSetupBadge)
updateSetupBadge()

local energyBar = Instance.new("Frame")
energyBar.Name = "EnergyBar"
energyBar.Size = UDim2.new(0.38, 0, 0, 14)
energyBar.Position = UDim2.new(1, -118, 0.5, -7)
energyBar.BackgroundColor3 = Color3.fromRGB(15, 18, 25)
energyBar.BorderSizePixel = 0
energyBar.Parent = setupBadge
local eCorner = Instance.new("UICorner"); eCorner.CornerRadius = UDim.new(0, 5); eCorner.Parent = energyBar
local eStroke = Instance.new("UIStroke"); eStroke.Color = Color3.fromRGB(46, 204, 113); eStroke.Thickness = 1; eStroke.Parent = energyBar

local energyFill = Instance.new("Frame")
energyFill.Name = "EnergyFill"
energyFill.Size = UDim2.new(1, 0, 1, 0)
energyFill.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
energyFill.BorderSizePixel = 0
energyFill.Parent = energyBar
local efCorner = Instance.new("UICorner"); efCorner.CornerRadius = UDim.new(0, 5); efCorner.Parent = energyFill

local energyLabel = Instance.new("TextLabel")
energyLabel.Name = "EnergyLabel"
energyLabel.Size = UDim2.new(1, 0, 1, 0)
energyLabel.BackgroundTransparency = 1
energyLabel.Font = Enum.Font.GothamBold
energyLabel.TextSize = 9
energyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
energyLabel.Text = "⚡ 100%"
energyLabel.ZIndex = 2
energyLabel.Parent = energyBar

local function updateEnergy()
    local energy = (LocalPlayer:GetAttribute("Energy") :: number?) or 100
    local pct = math.clamp(energy / 100, 0, 1)

    TweenService:Create(energyFill, TweenInfo.new(0.3), {
        Size = UDim2.new(pct, 0, 1, 0),
    }):Play()

    if energy > 50 then
        energyFill.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        eStroke.Color = Color3.fromRGB(46, 204, 113)
        energyLabel.Text = `⚡ {energy}%`
    elseif energy >= 25 then
        energyFill.BackgroundColor3 = Color3.fromRGB(243, 156, 18)
        eStroke.Color = Color3.fromRGB(243, 156, 18)
        energyLabel.Text = `⚡ {energy}%`
    else
        energyFill.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
        eStroke.Color = Color3.fromRGB(231, 76, 60)
        energyLabel.Text = `⚡ {energy}% ⚠️`
    end
end

LocalPlayer:GetAttributeChangedSignal("Energy"):Connect(updateEnergy)
updateEnergy()

-- Row 4: Integrated Live Chat Panel
local chatContainer = Instance.new("Frame")
chatContainer.Name = "ChatContainer"
chatContainer.Size = UDim2.new(1, -16, 1, -104)
chatContainer.Position = UDim2.new(0, 8, 0, 98)
chatContainer.BackgroundColor3 = Color3.fromRGB(16, 19, 27)
chatContainer.BackgroundTransparency = 0.2
chatContainer.BorderSizePixel = 0
chatContainer.Parent = streamerHub

local containerCorner = Instance.new("UICorner"); containerCorner.CornerRadius = UDim.new(0, 8); containerCorner.Parent = chatContainer
local containerStroke = Instance.new("UIStroke"); containerStroke.Color = Color3.fromRGB(38, 46, 62); containerStroke.Thickness = 1; containerStroke.Parent = chatContainer

local chatHeader = Instance.new("TextLabel")
chatHeader.Name = "ChatHeader"
chatHeader.Size = UDim2.new(1, 0, 0, 24)
chatHeader.Position = UDim2.new(0, 0, 0, 0)
chatHeader.BackgroundColor3 = Color3.fromRGB(22, 27, 38)
chatHeader.BackgroundTransparency = 0.2
chatHeader.TextColor3 = Color3.fromRGB(210, 220, 235)
chatHeader.Font = Enum.Font.GothamBold
chatHeader.TextSize = 11
chatHeader.Text = "  💬 Live Chat (Offline)"
chatHeader.TextXAlignment = Enum.TextXAlignment.Left
chatHeader.Parent = chatContainer
local headerCorner = Instance.new("UICorner"); headerCorner.CornerRadius = UDim.new(0, 8); headerCorner.Parent = chatHeader

local scrollingFrame = Instance.new("ScrollingFrame")
scrollingFrame.Name = "ChatScrollingFrame"
scrollingFrame.Size = UDim2.new(1, -8, 1, -28)
scrollingFrame.Position = UDim2.new(0, 4, 0, 26)
scrollingFrame.BackgroundTransparency = 1
scrollingFrame.BorderSizePixel = 0
scrollingFrame.ScrollBarThickness = 4
scrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 95, 120)
scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollingFrame.Parent = chatContainer

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 4)
listLayout.Parent = scrollingFrame

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 4)
padding.PaddingRight = UDim.new(0, 4)
padding.PaddingTop = UDim.new(0, 4)
padding.PaddingBottom = UDim.new(0, 4)
padding.Parent = scrollingFrame

--------------------------------------------------------------------------------
-- REBIRTH MODAL WINDOW (Детальний інтерфейс ребірсу)
--------------------------------------------------------------------------------
local rebirthBackdrop = Instance.new("Frame")
rebirthBackdrop.Name = "RebirthBackdrop"
rebirthBackdrop.Size = UDim2.new(1, 0, 1, 0)
rebirthBackdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
rebirthBackdrop.BackgroundTransparency = 0.6
rebirthBackdrop.Visible = false
rebirthBackdrop.ZIndex = 60
rebirthBackdrop.Parent = screenGui

local rebirthWindow = Instance.new("Frame")
rebirthWindow.Name = "RebirthWindow"
rebirthWindow.Size = UDim2.new(0, 560, 0, 520)
rebirthWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
rebirthWindow.AnchorPoint = Vector2.new(0.5, 0.5)
rebirthWindow.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
rebirthWindow.BorderSizePixel = 0
rebirthWindow.ZIndex = 61
rebirthWindow.Parent = rebirthBackdrop

local rwCorner = Instance.new("UICorner"); rwCorner.CornerRadius = UDim.new(0, 16); rwCorner.Parent = rebirthWindow
local rwStroke = Instance.new("UIStroke"); rwStroke.Color = Color3.fromRGB(255, 215, 0); rwStroke.Thickness = 2; rwStroke.Parent = rebirthWindow

-- Title Bar
local rwTitle = Instance.new("TextLabel")
rwTitle.Size = UDim2.new(1, -70, 0, 30)
rwTitle.Position = UDim2.new(0, 20, 0, 14)
rwTitle.BackgroundTransparency = 1
rwTitle.Font = Enum.Font.GothamBold
rwTitle.TextSize = 20
rwTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
rwTitle.TextXAlignment = Enum.TextXAlignment.Left
rwTitle.Text = "🔄 REBIRTH SYSTEM | РЕБІРС КАНАЛУ"
rwTitle.ZIndex = 62
rwTitle.Parent = rebirthWindow

local rwCloseBtn = Instance.new("TextButton")
rwCloseBtn.Size = UDim2.new(0, 32, 0, 32)
rwCloseBtn.Position = UDim2.new(1, -46, 0, 14)
rwCloseBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
rwCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
rwCloseBtn.Font = Enum.Font.GothamBold
rwCloseBtn.TextSize = 16
rwCloseBtn.Text = "✕"
rwCloseBtn.ZIndex = 62
rwCloseBtn.Parent = rebirthWindow
local rwcCorner = Instance.new("UICorner"); rwcCorner.CornerRadius = UDim.new(0, 8); rwcCorner.Parent = rwCloseBtn
rwCloseBtn.MouseButton1Click:Connect(function()
    rebirthBackdrop.Visible = false
end)

-- 1. Status Bar Card
local statusCard = Instance.new("Frame")
statusCard.Size = UDim2.new(1, -40, 0, 44)
statusCard.Position = UDim2.new(0, 20, 0, 50)
statusCard.BackgroundColor3 = Color3.fromRGB(35, 25, 55)
statusCard.BorderSizePixel = 0
statusCard.ZIndex = 62
statusCard.Parent = rebirthWindow
local scCorner = Instance.new("UICorner"); scCorner.CornerRadius = UDim.new(0, 8); scCorner.Parent = statusCard
local scStroke = Instance.new("UIStroke"); scStroke.Color = Color3.fromRGB(170, 80, 240); scStroke.Thickness = 1.2; scStroke.Parent = statusCard

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 1, 0)
statusLabel.Position = UDim2.new(0, 10, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 13
statusLabel.TextColor3 = Color3.fromRGB(255, 235, 140)
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Text = "⭐ Current: Rebirth Level 0  |  ⚡ Permanent Boost: +0%"
statusLabel.ZIndex = 63
statusLabel.Parent = statusCard

-- 2. Requirements & Progress Card
local reqCard = Instance.new("Frame")
reqCard.Size = UDim2.new(1, -40, 0, 68)
reqCard.Position = UDim2.new(0, 20, 0, 102)
reqCard.BackgroundColor3 = Color3.fromRGB(24, 28, 40)
reqCard.BorderSizePixel = 0
reqCard.ZIndex = 62
reqCard.Parent = rebirthWindow
local rcCorner = Instance.new("UICorner"); rcCorner.CornerRadius = UDim.new(0, 8); rcCorner.Parent = reqCard
local rcStroke = Instance.new("UIStroke"); rcStroke.Color = Color3.fromRGB(52, 152, 219); rcStroke.Thickness = 1.2; rcStroke.Parent = reqCard

local reqTitle = Instance.new("TextLabel")
reqTitle.Size = UDim2.new(1, -20, 0, 20)
reqTitle.Position = UDim2.new(0, 10, 0, 6)
reqTitle.BackgroundTransparency = 1
reqTitle.Font = Enum.Font.GothamBold
reqTitle.TextSize = 12
reqTitle.TextColor3 = Color3.fromRGB(220, 235, 255)
reqTitle.TextXAlignment = Enum.TextXAlignment.Left
reqTitle.Text = "📋 Requirements for Next Rebirth:"
reqTitle.ZIndex = 63
reqTitle.Parent = reqCard

local reqDetails = Instance.new("TextLabel")
reqDetails.Size = UDim2.new(1, -20, 0, 18)
reqDetails.Position = UDim2.new(0, 10, 0, 26)
reqDetails.BackgroundTransparency = 1
reqDetails.Font = Enum.Font.Gotham
reqDetails.TextSize = 11
reqDetails.TextColor3 = Color3.fromRGB(180, 195, 220)
reqDetails.TextXAlignment = Enum.TextXAlignment.Left
reqDetails.Text = "⭐ Subs: 0 / 500  |  💵 Cash: $0 / $250"
reqDetails.ZIndex = 63
reqDetails.Parent = reqCard

local reqProgBg = Instance.new("Frame")
reqProgBg.Size = UDim2.new(1, -20, 0, 12)
reqProgBg.Position = UDim2.new(0, 10, 0, 48)
reqProgBg.BackgroundColor3 = Color3.fromRGB(15, 18, 25)
reqProgBg.BorderSizePixel = 0
reqProgBg.ZIndex = 63
reqProgBg.Parent = reqCard
local rpbCorner = Instance.new("UICorner"); rpbCorner.CornerRadius = UDim.new(0, 6); rpbCorner.Parent = reqProgBg

local reqProgFill = Instance.new("Frame")
reqProgFill.Size = UDim2.new(0, 0, 1, 0)
reqProgFill.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
reqProgFill.BorderSizePixel = 0
reqProgFill.ZIndex = 64
reqProgFill.Parent = reqProgBg
local rpfCorner = Instance.new("UICorner"); rpfCorner.CornerRadius = UDim.new(0, 6); rpfCorner.Parent = reqProgFill

-- 3. Rewards Card (ЩО ТИ ОТРИМАЄШ)
local rewardsCard = Instance.new("Frame")
rewardsCard.Size = UDim2.new(1, -40, 0, 150)
rewardsCard.Position = UDim2.new(0, 20, 0, 178)
rewardsCard.BackgroundColor3 = Color3.fromRGB(24, 30, 24)
rewardsCard.BorderSizePixel = 0
rewardsCard.ZIndex = 62
rewardsCard.Parent = rebirthWindow
local rwcCorner2 = Instance.new("UICorner"); rwcCorner2.CornerRadius = UDim.new(0, 8); rwcCorner2.Parent = rewardsCard
local rwcStroke2 = Instance.new("UIStroke"); rwcStroke2.Color = Color3.fromRGB(46, 204, 113); rwcStroke2.Thickness = 1.2; rwcStroke2.Parent = rewardsCard

local rewTitle = Instance.new("TextLabel")
rewTitle.Size = UDim2.new(1, -20, 0, 24)
rewTitle.Position = UDim2.new(0, 10, 0, 6)
rewTitle.BackgroundTransparency = 1
rewTitle.Font = Enum.Font.GothamBold
rewTitle.TextSize = 13
rewTitle.TextColor3 = Color3.fromRGB(100, 240, 120)
rewTitle.TextXAlignment = Enum.TextXAlignment.Left
rewTitle.Text = "🎁 WHAT YOU GET FOR REBIRTH (ЩО ТИ ОТРИМАЄШ):"
rewTitle.ZIndex = 63
rewTitle.Parent = rewardsCard

local rewList = Instance.new("TextLabel")
rewList.Size = UDim2.new(1, -20, 0, 114)
rewList.Position = UDim2.new(0, 10, 0, 30)
rewList.BackgroundTransparency = 1
rewList.Font = Enum.Font.Gotham
rewList.TextSize = 11
rewList.TextColor3 = Color3.fromRGB(220, 240, 220)
rewList.TextXAlignment = Enum.TextXAlignment.Left
rewList.TextYAlignment = Enum.TextYAlignment.Top
rewList.TextWrapped = true
rewList.LineHeight = 1.15
rewList.Text = "• 🚀 +50% Permanent Multiplier to ALL Cash & Subscribers (Stacks infinitely!)\n• 🔓 UNLOCK PLATFORM CONTRACT: Switch to YouTube, Twitch, TikTok, or dual Split!\n• 👑 Prestige Overhead & Chat Title: [Rebirth 1], [Rebirth 2]...\n• ⚡ +10 Max Energy Capacity (Stream longer without tiring)\n• 💵 +$50 Permanent Starter Cash Bonus on every life!"
rewList.ZIndex = 63
rewList.Parent = rewardsCard

-- 4. Resets Warning Card (ЩО СКИДАЄТЬСЯ)
local resetCard = Instance.new("Frame")
resetCard.Size = UDim2.new(1, -40, 0, 95)
resetCard.Position = UDim2.new(0, 20, 0, 336)
resetCard.BackgroundColor3 = Color3.fromRGB(36, 24, 24)
resetCard.BorderSizePixel = 0
resetCard.ZIndex = 62
resetCard.Parent = rebirthWindow
local rstCorner = Instance.new("UICorner"); rstCorner.CornerRadius = UDim.new(0, 8); rstCorner.Parent = resetCard
local rstStroke = Instance.new("UIStroke"); rstStroke.Color = Color3.fromRGB(231, 76, 60); rstStroke.Thickness = 1.2; rstStroke.Parent = resetCard

local rstTitle = Instance.new("TextLabel")
rstTitle.Size = UDim2.new(1, -20, 0, 22)
rstTitle.Position = UDim2.new(0, 10, 0, 6)
rstTitle.BackgroundTransparency = 1
rstTitle.Font = Enum.Font.GothamBold
rstTitle.TextSize = 12
rstTitle.TextColor3 = Color3.fromRGB(255, 120, 120)
rstTitle.TextXAlignment = Enum.TextXAlignment.Left
rstTitle.Text = "⚠️ WHAT WILL RESET (ЩО СКИДАЄТЬСЯ):"
rstTitle.ZIndex = 63
rstTitle.Parent = resetCard

local rstList = Instance.new("TextLabel")
rstList.Size = UDim2.new(1, -20, 0, 62)
rstList.Position = UDim2.new(0, 10, 0, 28)
rstList.BackgroundTransparency = 1
rstList.Font = Enum.Font.Gotham
rstList.TextSize = 11
rstList.TextColor3 = Color3.fromRGB(240, 210, 210)
rstList.TextXAlignment = Enum.TextXAlignment.Left
rstList.TextYAlignment = Enum.TextYAlignment.Top
rstList.TextWrapped = true
rstList.Text = "• Current Subscribers reset to 0 (New channel era begins!)\n• Current Cash resets to Starter Cash ($15 + rebirth bonus)\n• Platform contract is unlocked for your new selection!\n• (Robux gamepasses, vehicles, and Rebirth boosts are PERMANENT and NEVER reset!)"
rstList.ZIndex = 63
rstList.Parent = resetCard

-- 5. Big Rebirth Action Button
local rebirthActionBtn = Instance.new("TextButton")
rebirthActionBtn.Name = "RebirthActionBtn"
rebirthActionBtn.Size = UDim2.new(1, -40, 0, 48)
rebirthActionBtn.Position = UDim2.new(0, 20, 1, -58)
rebirthActionBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
rebirthActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
rebirthActionBtn.Font = Enum.Font.GothamBlack
rebirthActionBtn.TextSize = 15
rebirthActionBtn.Text = "✨ PERFORM REBIRTH (+50% PERMANENT BOOST!)"
rebirthActionBtn.ZIndex = 63
rebirthActionBtn.Parent = rebirthWindow
local rabCorner = Instance.new("UICorner"); rabCorner.CornerRadius = UDim.new(0, 10); rabCorner.Parent = rebirthActionBtn

local function updateRebirthModal()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    local hypeVal = leaderstats and leaderstats:FindFirstChild("Hype") :: IntValue?
    local moneyVal = leaderstats and leaderstats:FindFirstChild("Money") :: IntValue?
    local rebirthsVal = leaderstats and leaderstats:FindFirstChild("Rebirths") :: IntValue?

    local currentSubs = hypeVal and hypeVal.Value or 0
    local currentCash = moneyVal and moneyVal.Value or 0
    local currentRebirths = rebirthsVal and rebirthsVal.Value or ((LocalPlayer:GetAttribute("Rebirths") :: number?) or 0)

    rebirthHudBtn.Text = `🔄 REBIRTH (Lv. {currentRebirths})`
    statusLabel.Text = `⭐ Current: Rebirth Level {currentRebirths}  |  ⚡ Permanent Boost: +{currentRebirths * 50}%`

    local reqSubs, reqMoney = StreamConfig.GetRebirthRequirements(currentRebirths)
    reqDetails.Text = `⭐ Subs: {currentSubs} / {reqSubs}  |  💵 Cash: ${currentCash} / ${reqMoney}`

    local subPct = math.clamp(currentSubs / reqSubs, 0, 1)
    local cashPct = math.clamp(currentCash / reqMoney, 0, 1)
    local overallPct = math.min(subPct, cashPct)

    TweenService:Create(reqProgFill, TweenInfo.new(0.2), {
        Size = UDim2.new(overallPct, 0, 1, 0)
    }):Play()

    if currentSubs >= reqSubs and currentCash >= reqMoney then
        rebirthActionBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        rebirthActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        rebirthActionBtn.Text = `✨ PERFORM REBIRTH NOW (+50% BOOST!)`
        rebirthActionBtn.Active = true
    else
        rebirthActionBtn.BackgroundColor3 = Color3.fromRGB(60, 70, 85)
        rebirthActionBtn.TextColor3 = Color3.fromRGB(160, 175, 195)
        rebirthActionBtn.Text = `🔒 LOCKED (Need {reqSubs} Subs & ${reqMoney} Cash - {math.floor(overallPct * 100)}%)`
        rebirthActionBtn.Active = false
    end
end

rebirthHudBtn.MouseButton1Click:Connect(function()
    updateRebirthModal()
    rebirthBackdrop.Visible = true
end)

rebirthActionBtn.MouseButton1Click:Connect(function()
    performRebirthRemote:FireServer()
    rebirthBackdrop.Visible = false
end)

rebirthResultRemote.OnClientEvent:Connect(function(statusType: string, info: any)
    updateRebirthModal()
    updateContractBadge()
end)

LocalPlayer:GetAttributeChangedSignal("Rebirths"):Connect(updateRebirthModal)
task.delay(1, updateRebirthModal)



--------------------------------------------------------------------------------
-- 4. Channel Naming Modal Window
--------------------------------------------------------------------------------
local modalBackdrop = Instance.new("Frame")
modalBackdrop.Name = "ChannelModalBackdrop"
modalBackdrop.Size = UDim2.new(1, 0, 1, 0)
modalBackdrop.Position = UDim2.new(0, 0, 0, 0)
modalBackdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
modalBackdrop.BackgroundTransparency = 0.5
modalBackdrop.Visible = false
modalBackdrop.ZIndex = 10
modalBackdrop.Parent = screenGui

local modalBox = Instance.new("Frame")
modalBox.Name = "ModalBox"
modalBox.Size = UDim2.new(0, 380, 0, 230)
modalBox.Position = UDim2.new(0.5, -190, 0.5, -115)
modalBox.BackgroundColor3 = Color3.fromRGB(26, 29, 38)
modalBox.BorderSizePixel = 0
modalBox.ZIndex = 11
modalBox.Parent = modalBackdrop

local modalCorner = Instance.new("UICorner")
modalCorner.CornerRadius = UDim.new(0, 14)
modalCorner.Parent = modalBox

local modalStroke = Instance.new("UIStroke")
modalStroke.Color = Color3.fromRGB(52, 152, 219)
modalStroke.Thickness = 1.5
modalStroke.Parent = modalBox

local modalTitle = Instance.new("TextLabel")
modalTitle.Name = "ModalTitle"
modalTitle.Size = UDim2.new(1, 0, 0, 40)
modalTitle.Position = UDim2.new(0, 0, 0, 10)
modalTitle.BackgroundTransparency = 1
modalTitle.Font = Enum.Font.GothamBold
modalTitle.TextSize = 18
modalTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
modalTitle.Text = "📺 Name Your Stream Channel!"
modalTitle.ZIndex = 12
modalTitle.Parent = modalBox

local modalSubtitle = Instance.new("TextLabel")
modalSubtitle.Name = "ModalSubtitle"
modalSubtitle.Size = UDim2.new(1, -40, 0, 30)
modalSubtitle.Position = UDim2.new(0, 20, 0, 50)
modalSubtitle.BackgroundTransparency = 1
modalSubtitle.Font = Enum.Font.Gotham
modalSubtitle.TextSize = 13
modalSubtitle.TextColor3 = Color3.fromRGB(180, 185, 200)
modalSubtitle.Text = "Enter a cool name for your streams (3–20 characters):"
modalSubtitle.TextWrapped = true
modalSubtitle.ZIndex = 12
modalSubtitle.Parent = modalBox

local channelInputBox = Instance.new("TextBox")
channelInputBox.Name = "ChannelInputBox"
channelInputBox.Size = UDim2.new(1, -50, 0, 44)
channelInputBox.Position = UDim2.new(0, 25, 0, 95)
channelInputBox.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
channelInputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
channelInputBox.PlaceholderColor3 = Color3.fromRGB(110, 115, 130)
channelInputBox.PlaceholderText = "e.g. ProGamer_TV"
channelInputBox.Font = Enum.Font.GothamMedium
channelInputBox.TextSize = 15
channelInputBox.ClearTextOnFocus = false
channelInputBox.ZIndex = 12
channelInputBox.Parent = modalBox

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 8)
inputCorner.Parent = channelInputBox

local inputStroke = Instance.new("UIStroke")
inputStroke.Color = Color3.fromRGB(60, 65, 80)
inputStroke.Thickness = 1
inputStroke.Parent = channelInputBox

-- Save button
local saveButton = Instance.new("TextButton")
saveButton.Name = "SaveChannelButton"
saveButton.Size = UDim2.new(0, 150, 0, 40)
saveButton.Position = UDim2.new(0.5, -160, 0, 160)
saveButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
saveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
saveButton.Font = Enum.Font.GothamBold
saveButton.TextSize = 14
saveButton.Text = "✅ Save"
saveButton.ZIndex = 12
saveButton.Parent = modalBox

local saveCorner = Instance.new("UICorner")
saveCorner.CornerRadius = UDim.new(0, 8)
saveCorner.Parent = saveButton

-- Close button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseModalButton"
closeButton.Size = UDim2.new(0, 150, 0, 40)
closeButton.Position = UDim2.new(0.5, 10, 0, 160)
closeButton.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 14
closeButton.Text = "✖ Close"
closeButton.ZIndex = 12
closeButton.Parent = modalBox

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

--------------------------------------------------------------------------------
-- 5. Quick Welcome Guide Banner (Fades after 12s or click)
--------------------------------------------------------------------------------
local welcomeBanner = Instance.new("Frame")
welcomeBanner.Name = "WelcomeGuide"
welcomeBanner.Size = UDim2.new(0, 480, 0, 80)
welcomeBanner.Position = UDim2.new(0.5, -240, 0.08, 0)
welcomeBanner.BackgroundColor3 = Color3.fromRGB(16, 20, 28)
welcomeBanner.BackgroundTransparency = 0.15
welcomeBanner.BorderSizePixel = 0
welcomeBanner.ZIndex = 50
welcomeBanner.Parent = screenGui

local wbCorner = Instance.new("UICorner")
wbCorner.CornerRadius = UDim.new(0, 12)
wbCorner.Parent = welcomeBanner

local wbStroke = Instance.new("UIStroke")
wbStroke.Color = Color3.fromRGB(255, 170, 0)
wbStroke.Thickness = 2
wbStroke.Parent = welcomeBanner

local wbTitle = Instance.new("TextLabel")
wbTitle.Size = UDim2.new(1, -20, 0, 24)
wbTitle.Position = UDim2.new(0, 10, 0, 6)
wbTitle.BackgroundTransparency = 1
wbTitle.Font = Enum.Font.GothamBold
wbTitle.TextSize = 14
wbTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
wbTitle.TextXAlignment = Enum.TextXAlignment.Left
wbTitle.Text = "🎮 STREAMER LIFE SIMULATOR — QUICK GUIDE"
wbTitle.ZIndex = 51
wbTitle.Parent = welcomeBanner

local wbDesc = Instance.new("TextLabel")
wbDesc.Size = UDim2.new(1, -20, 0, 44)
wbDesc.Position = UDim2.new(0, 10, 0, 30)
wbDesc.BackgroundTransparency = 1
wbDesc.Font = Enum.Font.Gotham
wbDesc.TextSize = 11
wbDesc.TextColor3 = Color3.fromRGB(230, 235, 245)
wbDesc.TextXAlignment = Enum.TextXAlignment.Left
wbDesc.TextYAlignment = Enum.TextYAlignment.Top
wbDesc.TextWrapped = true
wbDesc.Text = "• Sit at your Desk or click '▶ Start Stream' to pick YouTube, Twitch, TikTok, or Multi-Stream!\n• Drive your Starter Sedan down the avenue to CyberByte Tech or Burger Mart!\n• Make smart event choices every 30s to skyrocket your Subscribers!"
wbDesc.ZIndex = 51
wbDesc.Parent = welcomeBanner

task.delay(14, function()
    if welcomeBanner and welcomeBanner.Parent then
        TweenService:Create(welcomeBanner, TweenInfo.new(0.8), {
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, -240, 0.02, 0),
        }):Play()
        task.wait(0.9)
        welcomeBanner:Destroy()
    end
end)

