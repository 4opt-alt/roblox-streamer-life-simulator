--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui

local StreamConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("StreamConfig") :: ModuleScript)

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
local toggleStreamRemote = remotesFolder:WaitForChild("ToggleStream") :: RemoteEvent
local buyItemRemote = remotesFolder:WaitForChild("BuyShopItem") :: RemoteEvent

-- Create PlatformSelect ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PlatformSelectGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
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
window.Size = UDim2.new(0, 500, 0, 480)
window.Position = UDim2.new(0.5, -250, 0.5, -240)
window.BackgroundColor3 = Color3.fromRGB(22, 25, 34)
window.BorderSizePixel = 0
window.ZIndex = 31
window.Parent = backdrop

local winCorner = Instance.new("UICorner")
winCorner.CornerRadius = UDim.new(0, 14)
winCorner.Parent = window

local winStroke = Instance.new("UIStroke")
winStroke.Color = Color3.fromRGB(255, 75, 75)
winStroke.Thickness = 2
winStroke.Parent = window

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 0, 36)
title.Position = UDim2.new(0, 20, 0, 12)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "📡 CHOOSE STREAM PLATFORM"
title.ZIndex = 32
title.Parent = window

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -60, 0, 20)
subtitle.Position = UDim2.new(0, 20, 0, 44)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 13
subtitle.TextColor3 = Color3.fromRGB(170, 175, 190)
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Text = "Each platform offers unique viewer algorithms and revenue models!"
subtitle.ZIndex = 32
subtitle.Parent = window

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 32, 0, 32)
closeBtn.Position = UDim2.new(1, -44, 0, 12)
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

-- Cards Container
local cardsContainer = Instance.new("ScrollingFrame")
cardsContainer.Size = UDim2.new(1, -30, 0, 310)
cardsContainer.Position = UDim2.new(0, 15, 0, 75)
cardsContainer.BackgroundTransparency = 1
cardsContainer.BorderSizePixel = 0
cardsContainer.ScrollBarThickness = 5
cardsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
cardsContainer.ZIndex = 32
cardsContainer.Parent = window

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 10)
layout.Parent = cardsContainer

local selectedPlatform = "YouTube"
local platformCards: { [string]: Frame } = {}

local platformOrder = { "YouTube", "Twitch", "TikTok", "MultiStream" }

local function updateSelectionVisuals()
    for platKey, card in platformCards do
        local stroke = card:FindFirstChildOfClass("UIStroke")
        if stroke then
            if platKey == selectedPlatform then
                stroke.Color = Color3.fromRGB(46, 204, 113)
                stroke.Thickness = 2.5
                card.BackgroundColor3 = Color3.fromRGB(35, 42, 55)
            else
                stroke.Color = Color3.fromRGB(50, 55, 70)
                stroke.Thickness = 1
                card.BackgroundColor3 = Color3.fromRGB(26, 30, 40)
            end
        end
    end
end

for order, platKey in platformOrder do
    local info = StreamConfig.Platforms[platKey]
    if not info then continue end

    local card = Instance.new("Frame")
    card.Name = `Card_{platKey}`
    card.LayoutOrder = order
    card.Size = UDim2.new(1, -10, 0, 68)
    card.BackgroundColor3 = Color3.fromRGB(26, 30, 40)
    card.ZIndex = 33
    card.Parent = cardsContainer

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 10)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Color3.fromRGB(50, 55, 70)
    cardStroke.Thickness = 1
    cardStroke.Parent = card

    -- Platform Icon / Tag
    local tag = Instance.new("TextLabel")
    tag.Size = UDim2.new(0, 120, 0, 26)
    tag.Position = UDim2.new(0, 12, 0, 8)
    tag.BackgroundColor3 = Color3.fromHex(info.ColorHex)
    tag.TextColor3 = Color3.fromRGB(255, 255, 255)
    tag.Font = Enum.Font.GothamBold
    tag.TextSize = 13
    tag.Text = info.Name
    tag.ZIndex = 34
    tag.Parent = card

    local tagCorner = Instance.new("UICorner")
    tagCorner.CornerRadius = UDim.new(0, 6)
    tagCorner.Parent = tag

    -- Multiplier stats
    local stats = Instance.new("TextLabel")
    stats.Size = UDim2.new(1, -260, 0, 26)
    stats.Position = UDim2.new(0, 140, 0, 8)
    stats.BackgroundTransparency = 1
    stats.Font = Enum.Font.GothamBold
    stats.TextSize = 13
    stats.TextColor3 = Color3.fromRGB(255, 215, 0)
    stats.TextXAlignment = Enum.TextXAlignment.Left
    stats.Text = `💵 {info.MoneyMultiplier}x Money | ⭐ {info.HypeMultiplier}x Hype`
    stats.ZIndex = 34
    stats.Parent = card

    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(1, -150, 0, 20)
    desc.Position = UDim2.new(0, 12, 0, 38)
    desc.BackgroundTransparency = 1
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 12
    desc.TextColor3 = Color3.fromRGB(160, 165, 180)
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.Text = info.Description
    desc.ZIndex = 34
    desc.Parent = card

    local function selectThisPlatform()
        if info.RequiresLicense then
            local hasLicense = LocalPlayer:GetAttribute("Owned_MultiStreamLicense") == true
            if not hasLicense then
                -- Do not select, let user use purchase buttons
                return
            end
        end
        selectedPlatform = platKey
        updateSelectionVisuals()
    end

    -- For MultiStream: ONLY Robux purchase option (Split stream is Robux-exclusive)
    if platKey == "MultiStream" then
        card.Size = UDim2.new(1, -10, 0, 72)

        local actionContainer = Instance.new("Frame")
        actionContainer.Name = "ActionContainer"
        actionContainer.Size = UDim2.new(0, 160, 1, -12)
        actionContainer.Position = UDim2.new(1, -170, 0, 6)
        actionContainer.BackgroundTransparency = 1
        actionContainer.ZIndex = 34
        actionContainer.Parent = card

        local btnRobux = Instance.new("TextButton")
        btnRobux.Name = "BtnRobux"
        btnRobux.Size = UDim2.new(1, 0, 0, 38)
        btnRobux.Position = UDim2.new(0, 0, 0.5, -19)
        btnRobux.BackgroundColor3 = Color3.fromRGB(230, 140, 10)
        btnRobux.TextColor3 = Color3.fromRGB(255, 255, 255)
        btnRobux.Font = Enum.Font.GothamBold
        btnRobux.TextSize = 13
        btnRobux.Text = "💎 49 R$ (Robux Only)"
        btnRobux.ZIndex = 35
        btnRobux.AutoButtonColor = false
        btnRobux.Parent = actionContainer

        local rCorner = Instance.new("UICorner")
        rCorner.CornerRadius = UDim.new(0, 8)
        rCorner.Parent = btnRobux

        local rStroke = Instance.new("UIStroke")
        rStroke.Color = Color3.fromRGB(255, 215, 0)
        rStroke.Thickness = 1.5
        rStroke.Parent = btnRobux

        btnRobux.MouseEnter:Connect(function()
            TweenService:Create(btnRobux, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(255, 165, 20)}):Play()
        end)
        btnRobux.MouseLeave:Connect(function()
            TweenService:Create(btnRobux, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(230, 140, 10)}):Play()
        end)

        local btnOwnedSelect = Instance.new("TextButton")
        btnOwnedSelect.Name = "BtnOwnedSelect"
        btnOwnedSelect.Size = UDim2.new(1, 0, 0, 38)
        btnOwnedSelect.Position = UDim2.new(0, 0, 0.5, -19)
        btnOwnedSelect.BackgroundColor3 = Color3.fromRGB(41, 128, 185)
        btnOwnedSelect.TextColor3 = Color3.fromRGB(255, 255, 255)
        btnOwnedSelect.Font = Enum.Font.GothamBold
        btnOwnedSelect.TextSize = 13
        btnOwnedSelect.Text = "✔ Select"
        btnOwnedSelect.Visible = false
        btnOwnedSelect.ZIndex = 35
        btnOwnedSelect.Parent = actionContainer

        local oCorner = Instance.new("UICorner")
        oCorner.CornerRadius = UDim.new(0, 8)
        oCorner.Parent = btnOwnedSelect

        local function updateMultiStreamButtons()
            local isOwned = LocalPlayer:GetAttribute("Owned_MultiStreamLicense") == true
            if isOwned then
                btnRobux.Visible = false
                btnOwnedSelect.Visible = true
            else
                btnRobux.Visible = true
                btnOwnedSelect.Visible = false
            end
        end

        btnRobux.MouseButton1Click:Connect(function()
            promptRobuxRemote:FireServer("MultiStreamLicense")
        end)

        btnOwnedSelect.MouseButton1Click:Connect(function()
            selectedPlatform = "MultiStream"
            updateSelectionVisuals()
        end)

        LocalPlayer:GetAttributeChangedSignal("Owned_MultiStreamLicense"):Connect(updateMultiStreamButtons)
        updateMultiStreamButtons()
    else
        -- Regular platform cards (YouTube, Twitch, TikTok)
        local selBtn = Instance.new("TextButton")
        selBtn.Size = UDim2.new(0, 95, 0, 34)
        selBtn.Position = UDim2.new(1, -105, 0.5, -17)
        selBtn.BackgroundColor3 = Color3.fromRGB(41, 128, 185)
        selBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        selBtn.Font = Enum.Font.GothamBold
        selBtn.TextSize = 13
        selBtn.Text = "Select"
        selBtn.ZIndex = 34
        selBtn.Parent = card

        local selCorner = Instance.new("UICorner")
        selCorner.CornerRadius = UDim.new(0, 6)
        selCorner.Parent = selBtn

        selBtn.MouseButton1Click:Connect(selectThisPlatform)

        -- Make invisible click detector over whole card for easy tapping
        local cardBtn = Instance.new("TextButton")
        cardBtn.Size = UDim2.new(1, -110, 1, 0)
        cardBtn.BackgroundTransparency = 1
        cardBtn.Text = ""
        cardBtn.ZIndex = 35
        cardBtn.Parent = card
        cardBtn.MouseButton1Click:Connect(selectThisPlatform)
    end

    platformCards[platKey] = card
end

-- Launch Stream Button
local launchBtn = Instance.new("TextButton")
launchBtn.Name = "LaunchStreamButton"
launchBtn.Size = UDim2.new(1, -30, 0, 50)
launchBtn.Position = UDim2.new(0, 15, 1, -65)
launchBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
launchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
launchBtn.Font = Enum.Font.GothamBold
launchBtn.TextSize = 18
launchBtn.Text = "🚀 LAUNCH STREAM NOW!"
launchBtn.ZIndex = 32
launchBtn.Parent = window

local launchCorner = Instance.new("UICorner")
launchCorner.CornerRadius = UDim.new(0, 10)
launchCorner.Parent = launchBtn

launchBtn.MouseButton1Click:Connect(function()
    backdrop.Visible = false
    toggleStreamRemote:FireServer(selectedPlatform)
end)

closeBtn.MouseButton1Click:Connect(function()
    backdrop.Visible = false
end)

-- Global helper to open platform modal
_G.OpenPlatformSelect = function()
    updateSelectionVisuals()
    backdrop.Visible = true
end

-- Automatically open Platform Select when sitting in the Streamer Gaming Chair!
local function bindSeated(char: Model)
    local humanoid = char:WaitForChild("Humanoid") :: Humanoid
    humanoid.Seated:Connect(function(active: boolean, seatPart: Instance?)
        if active and seatPart and seatPart.Name == "GamingChairSeat" then
            local isStreaming = LocalPlayer:GetAttribute("IsStreaming") == true
            if not isStreaming then
                _G.OpenPlatformSelect()
            end
        end
    end)
end

if LocalPlayer.Character then
    bindSeated(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(bindSeated)

-- ProximityPrompt in-world trigger for Desk and Chair
local ProximityPromptService = game:GetService("ProximityPromptService")
ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, player: Player)
    if player == LocalPlayer then
        if prompt.Name == "SitPrompt" or prompt.Name == "DeskPrompt" then
            local isStreaming = LocalPlayer:GetAttribute("IsStreaming") == true
            if not isStreaming then
                _G.OpenPlatformSelect()
            end
        end
    end
end)


