--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui

local StreamConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("StreamConfig") :: ModuleScript)

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
local toggleStreamRemote = remotesFolder:WaitForChild("ToggleStream") :: RemoteEvent
local promptRobuxRemote = remotesFolder:WaitForChild("PromptRobuxPurchase") :: RemoteEvent

-- ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PlatformSelectGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 20
screenGui.Parent = PlayerGui

-- Backdrop
local backdrop = Instance.new("Frame")
backdrop.Name = "PlatformBackdrop"
backdrop.Size = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
backdrop.BackgroundTransparency = 0.55
backdrop.Visible = false
backdrop.ZIndex = 30
backdrop.Parent = screenGui

-- Window
local window = Instance.new("Frame")
window.Name = "PlatformWindow"
window.Size = UDim2.new(0, 560, 0, 520)
window.Position = UDim2.new(0.5, 0, 0.5, 0)
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
window.BorderSizePixel = 0
window.ZIndex = 31
window.Parent = backdrop

local winCorner = Instance.new("UICorner")
winCorner.CornerRadius = UDim.new(0, 16)
winCorner.Parent = window

local winStroke = Instance.new("UIStroke")
winStroke.Color = Color3.fromRGB(52, 152, 219)
winStroke.Thickness = 2
winStroke.Parent = window

-- Top Bar
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -70, 0, 32)
title.Position = UDim2.new(0, 20, 0, 14)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "📡 CHOOSE STREAM PLATFORMS"
title.ZIndex = 32
title.Parent = window

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 32, 0, 32)
closeBtn.Position = UDim2.new(1, -46, 0, 14)
closeBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.Text = "✕"
closeBtn.ZIndex = 32
closeBtn.Parent = window

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
    backdrop.Visible = false
end)

-- 1. Mode Banner (Single platform free vs Dual platform with Robux)
local modeBanner = Instance.new("Frame")
modeBanner.Name = "ModeBanner"
modeBanner.Size = UDim2.new(1, -40, 0, 52)
modeBanner.Position = UDim2.new(0, 20, 0, 52)
modeBanner.BackgroundColor3 = Color3.fromRGB(28, 32, 48)
modeBanner.BorderSizePixel = 0
modeBanner.ZIndex = 32
modeBanner.Parent = window

local mbCorner = Instance.new("UICorner"); mbCorner.CornerRadius = UDim.new(0, 10); mbCorner.Parent = modeBanner
local mbStroke = Instance.new("UIStroke"); mbStroke.Color = Color3.fromRGB(60, 75, 110); mbStroke.Thickness = 1.2; mbStroke.Parent = modeBanner

local modeTitle = Instance.new("TextLabel")
modeTitle.Size = UDim2.new(1, -170, 0, 22)
modeTitle.Position = UDim2.new(0, 12, 0, 6)
modeTitle.BackgroundTransparency = 1
modeTitle.Font = Enum.Font.GothamBold
modeTitle.TextSize = 13
modeTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
modeTitle.TextXAlignment = Enum.TextXAlignment.Left
modeTitle.Text = "📡 Standard Mode: 1 Platform Only"
modeTitle.ZIndex = 33
modeTitle.Parent = modeBanner

local modeDesc = Instance.new("TextLabel")
modeDesc.Size = UDim2.new(1, -170, 0, 18)
modeDesc.Position = UDim2.new(0, 12, 0, 28)
modeDesc.BackgroundTransparency = 1
modeDesc.Font = Enum.Font.Gotham
modeDesc.TextSize = 11
modeDesc.TextColor3 = Color3.fromRGB(170, 180, 205)
modeDesc.TextXAlignment = Enum.TextXAlignment.Left
modeDesc.Text = "Unlock Split Dual-Stream to broadcast to 2 platforms at once!"
modeDesc.ZIndex = 33
modeDesc.Parent = modeBanner

local splitUnlockBtn = Instance.new("TextButton")
splitUnlockBtn.Name = "SplitUnlockBtn"
splitUnlockBtn.Size = UDim2.new(0, 150, 0, 36)
splitUnlockBtn.Position = UDim2.new(1, -158, 0.5, -18)
splitUnlockBtn.BackgroundColor3 = Color3.fromRGB(230, 140, 10)
splitUnlockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
splitUnlockBtn.Font = Enum.Font.GothamBold
splitUnlockBtn.TextSize = 12
splitUnlockBtn.Text = "💎 49 R$ (Split Pass)"
splitUnlockBtn.ZIndex = 34
splitUnlockBtn.Parent = modeBanner
local suCorner = Instance.new("UICorner"); suCorner.CornerRadius = UDim.new(0, 8); suCorner.Parent = splitUnlockBtn
local suStroke = Instance.new("UIStroke"); suStroke.Color = Color3.fromRGB(255, 215, 0); suStroke.Thickness = 1.2; suStroke.Parent = splitUnlockBtn

splitUnlockBtn.MouseButton1Click:Connect(function()
    promptRobuxRemote:FireServer("MultiStreamLicense")
end)

local function updateModeBanner()
    local hasSplit = LocalPlayer:GetAttribute("Owned_MultiStreamLicense") == true
    if hasSplit then
        modeBanner.BackgroundColor3 = Color3.fromRGB(35, 25, 55)
        mbStroke.Color = Color3.fromRGB(210, 80, 255)
        modeTitle.TextColor3 = Color3.fromRGB(255, 120, 255)
        modeTitle.Text = "⭐ SPLIT DUAL-STREAM ACTIVE (2 Platforms Max)"
        modeDesc.Text = "You can stream to any 2 platforms simultaneously (+85% Cash & +50% Subs)!"
        splitUnlockBtn.BackgroundColor3 = Color3.fromRGB(30, 70, 40)
        splitUnlockBtn.Text = "✅ UNLOCKED"
        splitUnlockBtn.TextColor3 = Color3.fromRGB(100, 240, 120)
        suStroke.Color = Color3.fromRGB(46, 204, 113)
        splitUnlockBtn.Active = false
    else
        modeBanner.BackgroundColor3 = Color3.fromRGB(28, 32, 48)
        mbStroke.Color = Color3.fromRGB(60, 75, 110)
        modeTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
        modeTitle.Text = "📡 Standard Mode: 1 Platform Only"
        modeDesc.Text = "Unlock Split Dual-Stream to broadcast to 2 platforms at once!"
        splitUnlockBtn.BackgroundColor3 = Color3.fromRGB(230, 140, 10)
        splitUnlockBtn.Text = "💎 49 R$ (Split Pass)"
        splitUnlockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        suStroke.Color = Color3.fromRGB(255, 215, 0)
        splitUnlockBtn.Active = true
    end
end

LocalPlayer:GetAttributeChangedSignal("Owned_MultiStreamLicense"):Connect(updateModeBanner)

-- 2. Platform Selection State & Rows Container
local selectedPlatforms = { YouTube = true }

local platformsList = {
    { Id = "YouTube", Name = "YouTube Live", ColorHex = "#FF0000", Icon = "🔴", MoneyMult = "1.0x", HypeMult = "1.0x", Desc = "Balanced audience and revenue growth. Reliable starting platform." },
    { Id = "Twitch", Name = "Twitch", ColorHex = "#9146FF", Icon = "🟣", MoneyMult = "1.35x", HypeMult = "1.0x", Desc = "Generous live donation culture! +35% Money earnings per second." },
    { Id = "TikTok", Name = "TikTok Live", ColorHex = "#00F2FE", Icon = "🎵", MoneyMult = "1.0x", HypeMult = "1.60x", Desc = "Viral reach & rapid viewer spikes! +60% Subscriber gain per second." },
}

local cardsContainer = Instance.new("Frame")
cardsContainer.Name = "CardsContainer"
cardsContainer.Size = UDim2.new(1, -40, 0, 260)
cardsContainer.Position = UDim2.new(0, 20, 0, 114)
cardsContainer.BackgroundTransparency = 1
cardsContainer.ZIndex = 32
cardsContainer.Parent = window

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 10)
layout.Parent = cardsContainer

local platformRowCards: { [string]: Frame } = {}
local platformSelectBtns: { [string]: TextButton } = {}

-- 3. Dedicated Status Row for all platforms (Summary of current broadcast)
local summaryRow = Instance.new("Frame")
summaryRow.Name = "SummaryRow"
summaryRow.Size = UDim2.new(1, -40, 0, 40)
summaryRow.Position = UDim2.new(0, 20, 0, 385)
summaryRow.BackgroundColor3 = Color3.fromRGB(24, 28, 40)
summaryRow.BorderSizePixel = 0
summaryRow.ZIndex = 32
summaryRow.Parent = window

local sumCorner = Instance.new("UICorner"); sumCorner.CornerRadius = UDim.new(0, 8); sumCorner.Parent = summaryRow
local sumStroke = Instance.new("UIStroke"); sumStroke.Color = Color3.fromRGB(46, 204, 113); sumStroke.Thickness = 1.2; sumStroke.Parent = summaryRow

local summaryLabel = Instance.new("TextLabel")
summaryLabel.Name = "SummaryLabel"
summaryLabel.Size = UDim2.new(1, -20, 1, 0)
summaryLabel.Position = UDim2.new(0, 10, 0, 0)
summaryLabel.BackgroundTransparency = 1
summaryLabel.Font = Enum.Font.GothamBold
summaryLabel.TextSize = 12
summaryLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
summaryLabel.TextXAlignment = Enum.TextXAlignment.Left
summaryLabel.ZIndex = 33
summaryLabel.Parent = summaryRow

local function getSelectedCount(): number
    local count = 0
    for _, isSel in selectedPlatforms do
        if isSel then count += 1 end
    end
    return count
end

local function updateSummaryRow()
    local names = {}
    for _, p in platformsList do
        if selectedPlatforms[p.Id] then
            table.insert(names, `{p.Icon} {p.Name}`)
        end
    end

    local count = #names
    if count == 0 then
        summaryLabel.Text = "⚠️ No platform selected! Click a platform above to stream."
        summaryLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    elseif count == 1 then
        summaryLabel.Text = `📊 Active Broadcast: {names[1]} (1 Platform | Standard Income)`
        summaryLabel.TextColor3 = Color3.fromRGB(220, 240, 255)
        sumStroke.Color = Color3.fromRGB(52, 152, 219)
    else
        summaryLabel.Text = `⭐ SPLIT STREAM: {table.concat(names, " + ")} (+85% Cash & +50% Subs!)`
        summaryLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
        sumStroke.Color = Color3.fromRGB(255, 215, 0)
    end
end

local function refreshPlatformRows()
    for _, p in platformsList do
        local card = platformRowCards[p.Id]
        local btn = platformSelectBtns[p.Id]
        if card and btn then
            local isSel = selectedPlatforms[p.Id] == true
            local stroke = card:FindFirstChildOfClass("UIStroke")

            if isSel then
                card.BackgroundColor3 = Color3.fromRGB(30, 42, 58)
                if stroke then stroke.Color = Color3.fromRGB(46, 204, 113); stroke.Thickness = 2 end
                btn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
                btn.Text = "✔ SELECTED"
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                card.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
                if stroke then stroke.Color = Color3.fromRGB(50, 60, 80); stroke.Thickness = 1 end
                btn.BackgroundColor3 = Color3.fromRGB(40, 50, 70)
                btn.Text = "Select"
                btn.TextColor3 = Color3.fromRGB(180, 195, 220)
            end
        end
    end
    updateSummaryRow()
end

local function togglePlatform(platId: string)
    local hasSplit = LocalPlayer:GetAttribute("Owned_MultiStreamLicense") == true

    if not hasSplit then
        -- Without Robux Split Pass: strictly 1 platform only!
        selectedPlatforms = { [platId] = true }
    else
        -- With Robux Split Pass: can pick up to 2 platforms!
        if selectedPlatforms[platId] then
            -- Can only unselect if there is another one selected
            if getSelectedCount() > 1 then
                selectedPlatforms[platId] = nil
            end
        else
            if getSelectedCount() < 2 then
                selectedPlatforms[platId] = true
            else
                -- Replace the first one to keep strictly 2
                for k in selectedPlatforms do
                    selectedPlatforms[k] = nil
                    break
                end
                selectedPlatforms[platId] = true
            end
        end
    end

    refreshPlatformRows()
end

-- Render Individual Platform Rows
for idx, p in platformsList do
    local card = Instance.new("Frame")
    card.Name = `Row_{p.Id}`
    card.LayoutOrder = idx
    card.Size = UDim2.new(1, 0, 0, 74)
    card.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
    card.BorderSizePixel = 0
    card.ZIndex = 33
    card.Parent = cardsContainer

    local cCorner = Instance.new("UICorner"); cCorner.CornerRadius = UDim.new(0, 10); cCorner.Parent = card
    local cStroke = Instance.new("UIStroke"); cStroke.Color = Color3.fromRGB(50, 60, 80); cStroke.Thickness = 1; cStroke.Parent = card

    -- Icon + Name Badge
    local nameBadge = Instance.new("TextLabel")
    nameBadge.Size = UDim2.new(0, 135, 0, 26)
    nameBadge.Position = UDim2.new(0, 12, 0, 10)
    nameBadge.BackgroundColor3 = Color3.fromHex(p.ColorHex)
    nameBadge.Text = `{p.Icon} {p.Name}`
    nameBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameBadge.Font = Enum.Font.GothamBold
    nameBadge.TextSize = 12
    nameBadge.ZIndex = 34
    nameBadge.Parent = card
    local nbCorner = Instance.new("UICorner"); nbCorner.CornerRadius = UDim.new(0, 6); nbCorner.Parent = nameBadge

    -- Stats label
    local stats = Instance.new("TextLabel")
    stats.Size = UDim2.new(1, -275, 0, 26)
    stats.Position = UDim2.new(0, 155, 0, 10)
    stats.BackgroundTransparency = 1
    stats.Font = Enum.Font.GothamBold
    stats.TextSize = 12
    stats.TextColor3 = Color3.fromRGB(255, 215, 0)
    stats.TextXAlignment = Enum.TextXAlignment.Left
    stats.Text = `💵 {p.MoneyMult} Cash  |  ⭐ {p.HypeMult} Subs`
    stats.ZIndex = 34
    stats.Parent = card

    -- Description
    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(1, -145, 0, 22)
    desc.Position = UDim2.new(0, 12, 0, 42)
    desc.BackgroundTransparency = 1
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 11
    desc.TextColor3 = Color3.fromRGB(165, 175, 195)
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.Text = p.Desc
    desc.ZIndex = 34
    desc.Parent = card

    -- Select Toggle Button
    local selBtn = Instance.new("TextButton")
    selBtn.Name = "SelectBtn"
    selBtn.Size = UDim2.new(0, 105, 0, 38)
    selBtn.Position = UDim2.new(1, -115, 0.5, -19)
    selBtn.BackgroundColor3 = Color3.fromRGB(40, 50, 70)
    selBtn.TextColor3 = Color3.fromRGB(180, 195, 220)
    selBtn.Font = Enum.Font.GothamBold
    selBtn.TextSize = 12
    selBtn.Text = "Select"
    selBtn.ZIndex = 35
    selBtn.Parent = card
    local sbCorner = Instance.new("UICorner"); sbCorner.CornerRadius = UDim.new(0, 8); sbCorner.Parent = selBtn

    selBtn.MouseButton1Click:Connect(function()
        togglePlatform(p.Id)
    end)

    -- Also clicking card row toggles
    local clickArea = Instance.new("TextButton")
    clickArea.Size = UDim2.new(1, -120, 1, 0)
    clickArea.BackgroundTransparency = 1
    clickArea.Text = ""
    clickArea.ZIndex = 34
    clickArea.Parent = card
    clickArea.MouseButton1Click:Connect(function()
        togglePlatform(p.Id)
    end)

    platformRowCards[p.Id] = card
    platformSelectBtns[p.Id] = selBtn
end

-- 4. Big Launch Button
local launchBtn = Instance.new("TextButton")
launchBtn.Name = "LaunchStreamBtn"
launchBtn.Size = UDim2.new(1, -40, 0, 48)
launchBtn.Position = UDim2.new(0, 20, 1, -62)
launchBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
launchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
launchBtn.Font = Enum.Font.GothamBlack
launchBtn.TextSize = 16
launchBtn.Text = "🚀 LAUNCH STREAM NOW!"
launchBtn.ZIndex = 32
launchBtn.Parent = window

local lCorner = Instance.new("UICorner"); lCorner.CornerRadius = UDim.new(0, 10); lCorner.Parent = launchBtn

launchBtn.MouseButton1Click:Connect(function()
    local selectedList = {}
    for _, p in platformsList do
        if selectedPlatforms[p.Id] then
            table.insert(selectedList, p.Id)
        end
    end

    if #selectedList == 0 then
        table.insert(selectedList, "YouTube")
    end

    backdrop.Visible = false
    local platformArg = table.concat(selectedList, "+")
    toggleStreamRemote:FireServer(platformArg)
end)

updateModeBanner()
refreshPlatformRows()

LocalPlayer:GetAttributeChangedSignal("Owned_MultiStreamLicense"):Connect(function()
    updateModeBanner()
    -- If lost license somehow, ensure only 1 selected
    local hasSplit = LocalPlayer:GetAttribute("Owned_MultiStreamLicense") == true
    if not hasSplit and getSelectedCount() > 1 then
        for k in selectedPlatforms do
            selectedPlatforms = { [k] = true }
            break
        end
        refreshPlatformRows()
    end
end)

--------------------------------------------------------------------------------
-- Event Listener for Open Menu Requests
--------------------------------------------------------------------------------
local openSelectRemote = remotesFolder:FindFirstChild("OpenPlatformSelect") :: RemoteEvent?
if not openSelectRemote then
    openSelectRemote = Instance.new("RemoteEvent")
    openSelectRemote.Name = "OpenPlatformSelect"
    openSelectRemote.Parent = remotesFolder
end

openSelectRemote.OnClientEvent:Connect(function()
    updateModeBanner()
    refreshPlatformRows()
    backdrop.Visible = true
end)
