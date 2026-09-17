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
local lockPlatformRemote = remotesFolder:WaitForChild("LockPlatform") :: RemoteEvent
local promptPlatformSelectRemote = remotesFolder:WaitForChild("PromptPlatformSelect") :: RemoteEvent
local rebirthResultRemote = remotesFolder:WaitForChild("RebirthResult") :: RemoteEvent

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

-- 1. Platforms Configuration & Selection State
local selectedPlatforms: { [string]: boolean } = { YouTube = true }

local platformsList = {
    { Id = "YouTube", Name = "YouTube Live", ColorHex = "#FF0000", Icon = "🔴", MoneyMult = "1.0x", HypeMult = "1.0x", Desc = "Balanced audience and revenue growth. Reliable starting platform." },
    { Id = "Twitch", Name = "Twitch", ColorHex = "#9146FF", Icon = "🟣", MoneyMult = "1.35x", HypeMult = "1.0x", Desc = "Generous live donation culture! +35% Money earnings per second." },
    { Id = "TikTok", Name = "TikTok Live", ColorHex = "#00F2FE", Icon = "🎵", MoneyMult = "1.0x", HypeMult = "1.60x", Desc = "Viral reach & rapid viewer spikes! +60% Subscriber gain per second." },
}

local function getSelectedCount(): number
    local count = 0
    for _, isSel in selectedPlatforms do
        if isSel then count += 1 end
    end
    return count
end

local function syncWithLock(): boolean
    local locked = LocalPlayer:GetAttribute("LockedPlatform")
    if locked and locked ~= "" then
        selectedPlatforms = {}
        for plat in string.gmatch(locked, "[^+]+") do
            selectedPlatforms[plat] = true
        end
        return true
    end
    return false
end

-- 2. Mode Banner (Single platform free vs Dual platform with Robux)
local modeBanner = Instance.new("Frame")
modeBanner.Name = "ModeBanner"
modeBanner.Size = UDim2.new(1, -40, 0, 62)
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
modeDesc.Size = UDim2.new(1, -170, 0, 30)
modeDesc.Position = UDim2.new(0, 12, 0, 28)
modeDesc.BackgroundTransparency = 1
modeDesc.Font = Enum.Font.Gotham
modeDesc.TextSize = 11
modeDesc.TextColor3 = Color3.fromRGB(170, 180, 205)
modeDesc.TextXAlignment = Enum.TextXAlignment.Left
modeDesc.TextWrapped = true
modeDesc.Text = "Unlock Split Dual-Stream to broadcast to 2 platforms at once!"
modeDesc.ZIndex = 33
modeDesc.Parent = modeBanner

local splitUnlockBtn = Instance.new("TextButton")
splitUnlockBtn.Name = "SplitUnlockBtn"
splitUnlockBtn.Size = UDim2.new(0, 155, 0, 38)
splitUnlockBtn.Position = UDim2.new(1, -163, 0.5, -19)
splitUnlockBtn.BackgroundColor3 = Color3.fromRGB(230, 140, 10)
splitUnlockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
splitUnlockBtn.Font = Enum.Font.GothamBold
splitUnlockBtn.TextSize = 12
splitUnlockBtn.Text = "💎 49 R$ (Split Pass)"
splitUnlockBtn.ZIndex = 34
splitUnlockBtn.Parent = modeBanner
local suCorner = Instance.new("UICorner"); suCorner.CornerRadius = UDim.new(0, 8); suCorner.Parent = splitUnlockBtn
local suStroke = Instance.new("UIStroke"); suStroke.Color = Color3.fromRGB(255, 215, 0); suStroke.Thickness = 1.2; suStroke.Parent = splitUnlockBtn

-- 3. Containers and Buttons
local cardsContainer = Instance.new("Frame")
cardsContainer.Name = "CardsContainer"
cardsContainer.Size = UDim2.new(1, -40, 0, 246)
cardsContainer.Position = UDim2.new(0, 20, 0, 122)
cardsContainer.BackgroundTransparency = 1
cardsContainer.ZIndex = 32
cardsContainer.Parent = window

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 10)
layout.Parent = cardsContainer

local platformRowCards: { [string]: Frame } = {}
local platformSelectBtns: { [string]: TextButton } = {}
local platformClickAreas: { [string]: TextButton } = {}

-- Summary Row
local summaryRow = Instance.new("Frame")
summaryRow.Name = "SummaryRow"
summaryRow.Size = UDim2.new(1, -40, 0, 42)
summaryRow.Position = UDim2.new(0, 20, 0, 376)
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

-- Bottom Confirm & Lock Button
local launchBtn = Instance.new("TextButton")
launchBtn.Name = "LaunchStreamBtn"
launchBtn.Size = UDim2.new(1, -40, 0, 46)
launchBtn.Position = UDim2.new(0, 20, 1, -58)
launchBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
launchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
launchBtn.Font = Enum.Font.GothamBlack
launchBtn.TextSize = 15
launchBtn.Text = "🔒 CONFIRM & LOCK PLATFORM (UNTIL REBIRTH)"
launchBtn.ZIndex = 32
launchBtn.Parent = window

local lCorner = Instance.new("UICorner"); lCorner.CornerRadius = UDim.new(0, 10); lCorner.Parent = launchBtn

-- Forward declarations
local refreshPlatformRows: () -> ()
local updateSummaryRow: () -> ()
local updateLockState: () -> ()
local updateModeBanner: () -> ()

local function cycleDualPair()
    local locked = LocalPlayer:GetAttribute("LockedPlatform")
    if locked and locked ~= "" then return end
    local hasSplit = LocalPlayer:GetAttribute("Owned_MultiStreamLicense") == true
    if not hasSplit then return end

    if selectedPlatforms["YouTube"] and selectedPlatforms["Twitch"] and not selectedPlatforms["TikTok"] then
        selectedPlatforms = { Twitch = true, TikTok = true }
    elseif selectedPlatforms["Twitch"] and selectedPlatforms["TikTok"] and not selectedPlatforms["YouTube"] then
        selectedPlatforms = { YouTube = true, TikTok = true }
    else
        selectedPlatforms = { YouTube = true, Twitch = true }
    end

    refreshPlatformRows()
    updateSummaryRow()
    updateLockState()

    -- Subtle bounce animation on button click
    splitUnlockBtn.Size = UDim2.new(0, 163, 0, 42)
    splitUnlockBtn.Position = UDim2.new(1, -167, 0.5, -21)
    TweenService:Create(splitUnlockBtn, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 155, 0, 38),
        Position = UDim2.new(1, -163, 0.5, -19)
    }):Play()
end

splitUnlockBtn.MouseButton1Click:Connect(function()
    local hasSplit = LocalPlayer:GetAttribute("Owned_MultiStreamLicense") == true
    if hasSplit then
        cycleDualPair()
    else
        promptRobuxRemote:FireServer("MultiStreamLicense")
    end
end)

function updateModeBanner()
    local locked = LocalPlayer:GetAttribute("LockedPlatform")
    local isLocked = locked and locked ~= ""
    local hasSplit = LocalPlayer:GetAttribute("Owned_MultiStreamLicense") == true

    if isLocked then
        modeBanner.BackgroundColor3 = Color3.fromRGB(24, 30, 44)
        mbStroke.Color = Color3.fromRGB(52, 152, 219)
        modeTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
        modeTitle.Text = `🔒 CONTRACT LOCKED: {locked:gsub("+", " + ")}`
        modeDesc.Text = "Platform choice is LOCKED until Rebirth! Swapping platforms is disabled in this life."
        splitUnlockBtn.Visible = false
    elseif hasSplit then
        -- Auto-select 2nd platform if player currently only has 1
        if getSelectedCount() < 2 then
            if selectedPlatforms["YouTube"] then
                selectedPlatforms["Twitch"] = true
            else
                selectedPlatforms["YouTube"] = true
            end
        end

        modeBanner.BackgroundColor3 = Color3.fromRGB(35, 25, 55)
        mbStroke.Color = Color3.fromRGB(210, 80, 255)
        modeTitle.TextColor3 = Color3.fromRGB(255, 120, 255)
        modeTitle.Text = "⭐ DUAL-STREAM ACTIVE (2 Platforms Max)"
        modeDesc.Text = "🔥 Стрім на 2 платформи (+85% Cash & +50% Subs)! Оберіть 2 платформи нижче або тисніть AUTO-PAIR."
        splitUnlockBtn.Visible = true
        splitUnlockBtn.BackgroundColor3 = Color3.fromRGB(24, 75, 45)
        splitUnlockBtn.Text = "⚡ AUTO-PAIR 2"
        splitUnlockBtn.TextColor3 = Color3.fromRGB(120, 255, 150)
        suStroke.Color = Color3.fromRGB(46, 204, 113)
        splitUnlockBtn.Active = true
    else
        modeBanner.BackgroundColor3 = Color3.fromRGB(28, 32, 48)
        mbStroke.Color = Color3.fromRGB(60, 75, 110)
        modeTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
        modeTitle.Text = "📡 Standard Mode: 1 Platform Only"
        modeDesc.Text = "Unlock Split Dual-Stream to broadcast to 2 platforms at once!"
        splitUnlockBtn.Visible = true
        splitUnlockBtn.BackgroundColor3 = Color3.fromRGB(230, 140, 10)
        splitUnlockBtn.Text = "💎 49 R$ (Split Pass)"
        splitUnlockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        suStroke.Color = Color3.fromRGB(255, 215, 0)
        splitUnlockBtn.Active = true
    end
end

function updateSummaryRow()
    local locked = LocalPlayer:GetAttribute("LockedPlatform")
    local isLocked = locked and locked ~= ""

    local names = {}
    for _, p in platformsList do
        if selectedPlatforms[p.Id] then
            table.insert(names, `{p.Icon} {p.Name}`)
        end
    end

    local count = #names
    if isLocked then
        summaryLabel.Text = `🔒 Locked Contract: {table.concat(names, " + ")} (Perform Rebirth to choose another!)`
        summaryLabel.TextColor3 = Color3.fromRGB(130, 215, 255)
        sumStroke.Color = Color3.fromRGB(52, 152, 219)
    elseif count == 0 then
        summaryLabel.Text = "⚠️ No platform selected! Click a platform above to stream."
        summaryLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        sumStroke.Color = Color3.fromRGB(231, 76, 60)
    elseif count == 1 then
        summaryLabel.Text = `📊 Selected Platform: {names[1]} (Click Confirm & Lock below)`
        summaryLabel.TextColor3 = Color3.fromRGB(220, 240, 255)
        sumStroke.Color = Color3.fromRGB(52, 152, 219)
    else
        summaryLabel.Text = `⭐ DUAL-STREAM: {table.concat(names, " + ")} (+85% Cash & +50% Subs!)`
        summaryLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
        sumStroke.Color = Color3.fromRGB(255, 215, 0)
    end
end

function updateLockState()
    local locked = LocalPlayer:GetAttribute("LockedPlatform")
    local hasSplit = LocalPlayer:GetAttribute("Owned_MultiStreamLicense") == true
    local selCount = getSelectedCount()

    if locked and locked ~= "" then
        launchBtn.BackgroundColor3 = Color3.fromRGB(55, 65, 80)
        launchBtn.Text = `🔒 CONTRACT ACTIVE: {locked:gsub("+", " + ")} (REBIRTH TO SWITCH)`
        launchBtn.TextColor3 = Color3.fromRGB(180, 190, 210)
        launchBtn.AutoButtonColor = false
    else
        launchBtn.AutoButtonColor = true
        if hasSplit and selCount >= 2 then
            launchBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
            launchBtn.Text = "🔒 CONFIRM & LOCK DUAL-STREAM (UNTIL REBIRTH)"
            launchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        elseif hasSplit and selCount == 1 then
            launchBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
            launchBtn.Text = "🔒 CONFIRM 1 PLATFORM (OR ADD 2ND ABOVE)"
            launchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            launchBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
            launchBtn.Text = "🔒 CONFIRM & LOCK PLATFORM (UNTIL REBIRTH)"
            launchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end
end

function refreshPlatformRows()
    local locked = LocalPlayer:GetAttribute("LockedPlatform")
    local isLocked = locked and locked ~= ""
    if isLocked then
        syncWithLock()
    end

    local hasSplit = LocalPlayer:GetAttribute("Owned_MultiStreamLicense") == true
    local selCount = getSelectedCount()

    for _, p in platformsList do
        local card = platformRowCards[p.Id]
        local btn = platformSelectBtns[p.Id]
        local clickArea = platformClickAreas[p.Id]
        if card and btn then
            local isSel = selectedPlatforms[p.Id] == true
            local stroke = card:FindFirstChildOfClass("UIStroke")

            if isLocked then
                if clickArea then clickArea.Active = false end
                btn.Active = false
                btn.AutoButtonColor = false

                if isSel then
                    card.BackgroundColor3 = Color3.fromRGB(25, 38, 48)
                    if stroke then stroke.Color = Color3.fromRGB(46, 204, 113); stroke.Thickness = 2 end
                    btn.BackgroundColor3 = Color3.fromRGB(35, 75, 55)
                    btn.Text = "✔ ACTIVE CONTRACT"
                    btn.TextColor3 = Color3.fromRGB(100, 240, 130)
                else
                    card.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
                    if stroke then stroke.Color = Color3.fromRGB(35, 40, 50); stroke.Thickness = 1 end
                    btn.BackgroundColor3 = Color3.fromRGB(28, 30, 38)
                    btn.Text = "🔒 Locked"
                    btn.TextColor3 = Color3.fromRGB(100, 110, 125)
                end
            else
                if clickArea then clickArea.Active = true end
                btn.Active = true
                btn.AutoButtonColor = true

                if isSel then
                    card.BackgroundColor3 = Color3.fromRGB(26, 44, 48)
                    if stroke then stroke.Color = Color3.fromRGB(46, 204, 113); stroke.Thickness = 2 end
                    btn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
                    if hasSplit then
                        btn.Text = (selCount == 2) and "✔ SELECTED (2/2)" or "✔ SELECTED (1/2)"
                    else
                        btn.Text = "✔ SELECTED"
                    end
                    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                else
                    card.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
                    if stroke then stroke.Color = Color3.fromRGB(50, 60, 80); stroke.Thickness = 1 end
                    if hasSplit and selCount < 2 then
                        btn.BackgroundColor3 = Color3.fromRGB(35, 95, 145)
                        btn.Text = "+ ADD (2nd)"
                        btn.TextColor3 = Color3.fromRGB(210, 240, 255)
                    elseif hasSplit and selCount >= 2 then
                        btn.BackgroundColor3 = Color3.fromRGB(45, 55, 75)
                        btn.Text = "⇄ Switch"
                        btn.TextColor3 = Color3.fromRGB(180, 195, 220)
                    else
                        btn.BackgroundColor3 = Color3.fromRGB(40, 50, 70)
                        btn.Text = "Select"
                        btn.TextColor3 = Color3.fromRGB(180, 195, 220)
                    end
                end
            end
        end
    end
    updateSummaryRow()
    updateLockState()
end

local function togglePlatform(platId: string)
    local locked = LocalPlayer:GetAttribute("LockedPlatform")
    if locked and locked ~= "" then
        return
    end

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


--------------------------------------------------------------------------------
-- Open Menu Listener & Global Function
--------------------------------------------------------------------------------
local function openMenu(isRebirth: boolean?)
    local locked = LocalPlayer:GetAttribute("LockedPlatform")
    if isRebirth or not locked or locked == "" then
        if not selectedPlatforms or not next(selectedPlatforms) then
            selectedPlatforms = { YouTube = true }
        end
    else
        syncWithLock()
    end
    updateModeBanner()
    refreshPlatformRows()
    updateLockState()
    if isRebirth then
        modeTitle.Text = "🎉 REBIRTH COMPLETE! CHOOSE NEW CONTRACT"
        modeTitle.TextColor3 = Color3.fromRGB(46, 204, 113)
        modeDesc.Text = "Pick your streaming platform for your new rebirth era (+50% permanent boost active)!"
    end
    backdrop.Visible = true
end

_G.OpenPlatformSelect = openMenu

promptPlatformSelectRemote.OnClientEvent:Connect(function(isRebirth: boolean?)
    openMenu(isRebirth)
end)

local openSelectRemote = remotesFolder:FindFirstChild("OpenPlatformSelect") :: RemoteEvent?
if openSelectRemote then
    openSelectRemote.OnClientEvent:Connect(function()
        openMenu(false)
    end)
end
