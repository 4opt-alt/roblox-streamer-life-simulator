--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ShopConfig = require(Shared:WaitForChild("ShopConfig") :: ModuleScript)

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local promptRobuxRemote = remotesFolder:WaitForChild("PromptRobuxPurchase") :: RemoteEvent
local shopResultRemote = remotesFolder:WaitForChild("ShopItemPurchased") :: RemoteEvent
local broadcastSuperChatRemote = remotesFolder:WaitForChild("BroadcastSuperChat") :: RemoteEvent

--------------------------------------------------------------------------------
-- GUI Initialization
--------------------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RobuxStoreGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 15
screenGui.Parent = playerGui

--------------------------------------------------------------------------------
-- 1. Floating Robux Store Button (Top Right)
--------------------------------------------------------------------------------
local openBtn = Instance.new("TextButton")
openBtn.Name = "OpenRobuxStoreBtn"
openBtn.Size = UDim2.new(0, 160, 0, 42)
openBtn.Position = UDim2.new(1, -175, 0, 60)
openBtn.BackgroundColor3 = Color3.fromRGB(24, 28, 42)
openBtn.Text = "💎 ROBUX STORE"
openBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
openBtn.Font = Enum.Font.GothamBold
openBtn.TextSize = 14
openBtn.AutoButtonColor = false
openBtn.Parent = screenGui

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 10)
btnCorner.Parent = openBtn

local btnStroke = Instance.new("UIStroke")
btnStroke.Color = Color3.fromRGB(255, 215, 0)
btnStroke.Thickness = 1.8
btnStroke.Parent = openBtn

local btnGradient = Instance.new("UIGradient")
btnGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 230, 120)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 170, 0)),
})
btnGradient.Parent = btnStroke

openBtn.MouseEnter:Connect(function()
    TweenService:Create(openBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 48, 70)}):Play()
end)
openBtn.MouseLeave:Connect(function()
    TweenService:Create(openBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(24, 28, 42)}):Play()
end)

--------------------------------------------------------------------------------
-- 2. Active Boosts HUD (Under the open button)
--------------------------------------------------------------------------------
local activeBuffsFrame = Instance.new("Frame")
activeBuffsFrame.Name = "ActiveBuffsFrame"
activeBuffsFrame.Size = UDim2.new(0, 200, 0, 95)
activeBuffsFrame.Position = UDim2.new(1, -215, 0, 110)
activeBuffsFrame.BackgroundTransparency = 1
activeBuffsFrame.Parent = screenGui

local buffLayout = Instance.new("UIListLayout")
buffLayout.SortOrder = Enum.SortOrder.LayoutOrder
buffLayout.Padding = UDim.new(0, 6)
buffLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
buffLayout.Parent = activeBuffsFrame

local viralBadge = Instance.new("TextLabel")
viralBadge.Name = "ViralBoostBadge"
viralBadge.Size = UDim2.new(0, 190, 0, 26)
viralBadge.BackgroundColor3 = Color3.fromRGB(35, 15, 60)
viralBadge.Text = "🚀 2X VIRAL BOOST: --:--"
viralBadge.TextColor3 = Color3.fromRGB(255, 120, 255)
viralBadge.Font = Enum.Font.GothamBold
viralBadge.TextSize = 11
viralBadge.Visible = false
viralBadge.Parent = activeBuffsFrame
local vCorner = Instance.new("UICorner"); vCorner.CornerRadius = UDim.new(0, 6); vCorner.Parent = viralBadge
local vStroke = Instance.new("UIStroke"); vStroke.Color = Color3.fromRGB(210, 80, 255); vStroke.Thickness = 1; vStroke.Parent = viralBadge

local energyBadge = Instance.new("TextLabel")
energyBadge.Name = "EnergyBoostBadge"
energyBadge.Size = UDim2.new(0, 190, 0, 26)
energyBadge.BackgroundColor3 = Color3.fromRGB(15, 45, 60)
energyBadge.Text = "⚡ INFINITE STAMINA: --:--"
energyBadge.TextColor3 = Color3.fromRGB(100, 240, 255)
energyBadge.Font = Enum.Font.GothamBold
energyBadge.TextSize = 11
energyBadge.Visible = false
energyBadge.Parent = activeBuffsFrame
local eCorner = Instance.new("UICorner"); eCorner.CornerRadius = UDim.new(0, 6); eCorner.Parent = energyBadge
local eStroke = Instance.new("UIStroke"); eStroke.Color = Color3.fromRGB(0, 210, 255); eStroke.Thickness = 1; eStroke.Parent = energyBadge

local vipBadge = Instance.new("TextLabel")
vipBadge.Name = "VipBadge"
vipBadge.Size = UDim2.new(0, 190, 0, 26)
vipBadge.BackgroundColor3 = Color3.fromRGB(50, 40, 10)
vipBadge.Text = "👑 VIP CREATOR ACTIVE"
vipBadge.TextColor3 = Color3.fromRGB(255, 215, 0)
vipBadge.Font = Enum.Font.GothamBold
vipBadge.TextSize = 11
vipBadge.Visible = false
vipBadge.Parent = activeBuffsFrame
local vipCorner = Instance.new("UICorner"); vipCorner.CornerRadius = UDim.new(0, 6); vipCorner.Parent = vipBadge
local vipStroke = Instance.new("UIStroke"); vipStroke.Color = Color3.fromRGB(255, 215, 0); vipStroke.Thickness = 1; vipStroke.Parent = vipBadge

-- Update timer loop for active badges
task.spawn(function()
    while true do
        task.wait(1)
        local now = os.time()
        
        -- VIP check
        local isVIP = player:GetAttribute("IsVIP") == true
        vipBadge.Visible = isVIP

        -- Viral boost check
        local viralExp = (player:GetAttribute("ViralBoostExpiry") :: number?) or 0
        if viralExp > now then
            local rem = viralExp - now
            local mins = math.floor(rem / 60)
            local secs = rem % 60
            viralBadge.Text = string.format("🚀 2X VIRAL BOOST: %02d:%02d", mins, secs)
            viralBadge.Visible = true
        else
            viralBadge.Visible = false
        end

        -- Infinite energy check
        local energyExp = (player:GetAttribute("InfiniteEnergyExpiry") :: number?) or 0
        if energyExp > now then
            local rem = energyExp - now
            local mins = math.floor(rem / 60)
            local secs = rem % 60
            energyBadge.Text = string.format("⚡ INFINITE STAMINA: %02d:%02d", mins, secs)
            energyBadge.Visible = true
        else
            energyBadge.Visible = false
        end
    end
end)

--------------------------------------------------------------------------------
-- 3. Robux Store Modal
--------------------------------------------------------------------------------
local modal = Instance.new("Frame")
modal.Name = "RobuxStoreModal"
modal.Size = UDim2.new(0, 720, 0, 520)
modal.Position = UDim2.new(0.5, 0, 0.5, 0)
modal.AnchorPoint = Vector2.new(0.5, 0.5)
modal.BackgroundColor3 = Color3.fromRGB(16, 20, 30)
modal.BorderSizePixel = 0
modal.Visible = false
modal.Parent = screenGui

local mCorner = Instance.new("UICorner")
mCorner.CornerRadius = UDim.new(0, 16)
mCorner.Parent = modal

local mStroke = Instance.new("UIStroke")
mStroke.Color = Color3.fromRGB(255, 215, 0)
mStroke.Thickness = 2
mStroke.Parent = modal

-- Top Bar
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 60)
topBar.BackgroundColor3 = Color3.fromRGB(22, 28, 44)
topBar.BorderSizePixel = 0
topBar.Parent = modal
local tbCorner = Instance.new("UICorner"); tbCorner.CornerRadius = UDim.new(0, 16); tbCorner.Parent = topBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(0, 450, 1, 0)
titleLabel.Position = UDim2.new(0, 20, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "💎 ROBUX STORE & VIP PASSES"
titleLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 20
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = topBar

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.Position = UDim2.new(1, -48, 0, 12)
closeBtn.BackgroundColor3 = Color3.fromRGB(45, 20, 25)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.Parent = topBar
local cbCorner = Instance.new("UICorner"); cbCorner.CornerRadius = UDim.new(0, 8); cbCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
    modal.Visible = false
end)

openBtn.MouseButton1Click:Connect(function()
    modal.Visible = not modal.Visible
end)

-- Category Filter Bar
local filterBar = Instance.new("Frame")
filterBar.Name = "FilterBar"
filterBar.Size = UDim2.new(1, -40, 0, 36)
filterBar.Position = UDim2.new(0, 20, 0, 70)
filterBar.BackgroundTransparency = 1
filterBar.Parent = modal

local filterLayout = Instance.new("UIListLayout")
filterLayout.FillDirection = Enum.FillDirection.Horizontal
filterLayout.SortOrder = Enum.SortOrder.LayoutOrder
filterLayout.Padding = UDim.new(0, 10)
filterLayout.Parent = filterBar

local categories = {
    { Id = "All", Label = "⭐ All Products" },
    { Id = "VIP", Label = "👑 VIP & Status" },
    { Id = "Boost", Label = "⚡ Boosts & Energy" },
    { Id = "Cash", Label = "💵 Cash Packs" },
}

local selectedCategory = "All"
local categoryButtons: { [string]: TextButton } = {}

-- Scrollable Container for Cards
local scroll = Instance.new("ScrollingFrame")
scroll.Name = "CardsScroll"
scroll.Size = UDim2.new(1, -40, 1, -125)
scroll.Position = UDim2.new(0, 20, 0, 115)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 95, 130)
scroll.Parent = modal

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 325, 0, 155)
gridLayout.CellPadding = UDim2.new(0, 14, 0, 14)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = scroll

local function renderProducts()
    for _, child in scroll:GetChildren() do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local robuxProducts = (ShopConfig :: any).RobuxProducts
    if not robuxProducts then return end

    for prodId, prod in robuxProducts do
        if selectedCategory ~= "All" and prod.Category ~= selectedCategory then
            continue
        end

        local card = Instance.new("Frame")
        card.Name = "Card_" .. prodId
        card.BackgroundColor3 = Color3.fromRGB(24, 30, 46)
        card.BorderSizePixel = 0
        card.Parent = scroll

        local cCorner = Instance.new("UICorner")
        cCorner.CornerRadius = UDim.new(0, 12)
        cCorner.Parent = card

        local cStroke = Instance.new("UIStroke")
        cStroke.Color = Color3.fromRGB(50, 65, 95)
        cStroke.Thickness = 1.2
        cStroke.Parent = card

        -- Badge in corner
        if prod.BadgeText and prod.BadgeText ~= "" then
            local badge = Instance.new("TextLabel")
            badge.Name = "Badge"
            badge.Size = UDim2.new(0, 110, 0, 20)
            badge.Position = UDim2.new(1, -115, 0, 8)
            badge.BackgroundColor3 = Color3.fromRGB(180, 130, 20)
            badge.Text = prod.BadgeText
            badge.TextColor3 = Color3.fromRGB(255, 255, 255)
            badge.Font = Enum.Font.GothamBold
            badge.TextSize = 10
            badge.Parent = card
            local bCorner = Instance.new("UICorner"); bCorner.CornerRadius = UDim.new(0, 6); bCorner.Parent = badge
        end

        -- Icon
        local icon = Instance.new("TextLabel")
        icon.Name = "Icon"
        icon.Size = UDim2.new(0, 42, 0, 42)
        icon.Position = UDim2.new(0, 12, 0, 10)
        icon.BackgroundColor3 = Color3.fromRGB(35, 42, 65)
        icon.Text = prod.IconText or "💎"
        icon.TextSize = 22
        icon.Parent = card
        local iCorner = Instance.new("UICorner"); iCorner.CornerRadius = UDim.new(0, 8); iCorner.Parent = icon

        -- Name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "NameLabel"
        nameLabel.Size = UDim2.new(1, -170, 0, 24)
        nameLabel.Position = UDim2.new(0, 62, 0, 10)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = prod.Name
        nameLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 13
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.Parent = card

        -- Description
        local descLabel = Instance.new("TextLabel")
        descLabel.Name = "DescLabel"
        descLabel.Size = UDim2.new(1, -24, 0, 48)
        descLabel.Position = UDim2.new(0, 12, 0, 56)
        descLabel.BackgroundTransparency = 1
        descLabel.Text = prod.Description
        descLabel.TextColor3 = Color3.fromRGB(160, 175, 205)
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextSize = 11
        descLabel.TextWrapped = true
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.TextYAlignment = Enum.TextYAlignment.Top
        descLabel.Parent = card

        -- Buy Button
        local buyBtn = Instance.new("TextButton")
        buyBtn.Name = "BuyBtn"
        buyBtn.Size = UDim2.new(1, -24, 0, 34)
        buyBtn.Position = UDim2.new(0, 12, 1, -42)
        buyBtn.Parent = card
        local bbCorner = Instance.new("UICorner"); bbCorner.CornerRadius = UDim.new(0, 8); bbCorner.Parent = buyBtn

        local isOwned = false
        if prod.Type == "GamePass" then
            if prodId == "Pass_VIP" and player:GetAttribute("IsVIP") == true then
                isOwned = true
            elseif prodId == "MultiStreamLicense" and player:GetAttribute("Owned_MultiStreamLicense") == true then
                isOwned = true
            end
        end

        if isOwned then
            buyBtn.BackgroundColor3 = Color3.fromRGB(30, 70, 40)
            buyBtn.Text = "✅ OWNED"
            buyBtn.TextColor3 = Color3.fromRGB(100, 240, 120)
            buyBtn.Font = Enum.Font.GothamBold
            buyBtn.TextSize = 13
            buyBtn.Active = false
        else
            buyBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 90)
            buyBtn.Text = string.format("💎 Buy for %d R$", prod.PriceRobux)
            buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            buyBtn.Font = Enum.Font.GothamBold
            buyBtn.TextSize = 13
            buyBtn.AutoButtonColor = false

            buyBtn.MouseEnter:Connect(function()
                TweenService:Create(buyBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(0, 205, 110)}):Play()
            end)
            buyBtn.MouseLeave:Connect(function()
                TweenService:Create(buyBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(0, 170, 90)}):Play()
            end)

            buyBtn.MouseButton1Click:Connect(function()
                promptRobuxRemote:FireServer(prodId)
            end)
        end
    end

    local rows = math.ceil(#scroll:GetChildren() / 2)
    scroll.CanvasSize = UDim2.new(0, 0, 0, rows * 170)
end

-- Create category tabs
for _, cat in categories do
    local cBtn = Instance.new("TextButton")
    cBtn.Name = "Tab_" .. cat.Id
    cBtn.Size = UDim2.new(0, 130, 1, 0)
    cBtn.BackgroundColor3 = (cat.Id == selectedCategory) and Color3.fromRGB(45, 60, 95) or Color3.fromRGB(24, 30, 45)
    cBtn.Text = cat.Label
    cBtn.TextColor3 = (cat.Id == selectedCategory) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(170, 185, 215)
    cBtn.Font = Enum.Font.GothamBold
    cBtn.TextSize = 12
    cBtn.Parent = filterBar
    local tabCorner = Instance.new("UICorner"); tabCorner.CornerRadius = UDim.new(0, 8); tabCorner.Parent = cBtn

    categoryButtons[cat.Id] = cBtn

    cBtn.MouseButton1Click:Connect(function()
        selectedCategory = cat.Id
        for id, btn in categoryButtons do
            btn.BackgroundColor3 = (id == selectedCategory) and Color3.fromRGB(45, 60, 95) or Color3.fromRGB(24, 30, 45)
            btn.TextColor3 = (id == selectedCategory) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(170, 185, 215)
        end
        renderProducts()
    end)
end

renderProducts()

player:GetAttributeChangedSignal("IsVIP"):Connect(renderProducts)
player:GetAttributeChangedSignal("Owned_MultiStreamLicense"):Connect(renderProducts)

--------------------------------------------------------------------------------
-- 4. Server-Wide Super-Chat Screen Announcement
--------------------------------------------------------------------------------
broadcastSuperChatRemote.OnClientEvent:Connect(function(senderName: string, subsAmount: number)
    local alertBanner = Instance.new("Frame")
    alertBanner.Name = "SuperChatBanner"
    alertBanner.Size = UDim2.new(0, 520, 0, 75)
    alertBanner.Position = UDim2.new(0.5, 0, 0, -85)
    alertBanner.AnchorPoint = Vector2.new(0.5, 0)
    alertBanner.BackgroundColor3 = Color3.fromRGB(25, 20, 5)
    alertBanner.BorderSizePixel = 0
    alertBanner.ZIndex = 50
    alertBanner.Parent = screenGui

    local abCorner = Instance.new("UICorner"); abCorner.CornerRadius = UDim.new(0, 14); abCorner.Parent = alertBanner
    local abStroke = Instance.new("UIStroke"); abStroke.Color = Color3.fromRGB(255, 215, 0); abStroke.Thickness = 2.5; abStroke.Parent = alertBanner

    local mainLabel = Instance.new("TextLabel")
    mainLabel.Size = UDim2.new(1, -20, 0, 32)
    mainLabel.Position = UDim2.new(0, 10, 0, 6)
    mainLabel.BackgroundTransparency = 1
    mainLabel.Text = "🌟 MEGA SUPER-CHAT DONATION! 🌟"
    mainLabel.TextColor3 = Color3.fromRGB(255, 225, 60)
    mainLabel.Font = Enum.Font.GothamBlack
    mainLabel.TextSize = 16
    mainLabel.ZIndex = 51
    mainLabel.Parent = alertBanner

    local subLabel = Instance.new("TextLabel")
    subLabel.Size = UDim2.new(1, -20, 0, 26)
    subLabel.Position = UDim2.new(0, 10, 0, 38)
    subLabel.BackgroundTransparency = 1
    subLabel.Text = string.format("%s dropped an epic Super-Chat! (+%d Subscribers!)", senderName, subsAmount)
    subLabel.TextColor3 = Color3.fromRGB(255, 245, 200)
    subLabel.Font = Enum.Font.GothamBold
    subLabel.TextSize = 13
    subLabel.ZIndex = 51
    subLabel.Parent = alertBanner

    local slideIn = TweenService:Create(alertBanner, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 0, 20)
    })
    slideIn:Play()

    task.delay(6, function()
        if alertBanner.Parent then
            local slideOut = TweenService:Create(alertBanner, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(0.5, 0, 0, -90)
            })
            slideOut:Play()
            slideOut.Completed:Connect(function()
                alertBanner:Destroy()
            end)
        end
    end)
end)

--------------------------------------------------------------------------------
-- 5. Floating Result Feedback Toast
--------------------------------------------------------------------------------
shopResultRemote.OnClientEvent:Connect(function(itemId: string, success: boolean, message: string)
    local toast = Instance.new("TextLabel")
    toast.Size = UDim2.new(0, 360, 0, 44)
    toast.Position = UDim2.new(0.5, -180, 0.85, 0)
    toast.BackgroundColor3 = success and Color3.fromRGB(15, 60, 35) or Color3.fromRGB(70, 20, 25)
    toast.Text = message
    toast.TextColor3 = Color3.fromRGB(255, 255, 255)
    toast.Font = Enum.Font.GothamBold
    toast.TextSize = 13
    toast.ZIndex = 60
    toast.Parent = screenGui

    local tCorner = Instance.new("UICorner"); tCorner.CornerRadius = UDim.new(0, 10); tCorner.Parent = toast
    local tStroke = Instance.new("UIStroke"); tStroke.Color = success and Color3.fromRGB(40, 200, 100) or Color3.fromRGB(220, 60, 60); tStroke.Thickness = 1.5; tStroke.Parent = toast

    TweenService:Create(toast, TweenInfo.new(0.3), {Position = UDim2.new(0.5, -180, 0.82, 0)}):Play()

    task.delay(3.5, function()
        if toast.Parent then
            local fade = TweenService:Create(toast, TweenInfo.new(0.4), {TextTransparency = 1, BackgroundTransparency = 1})
            fade:Play()
            fade.Completed:Connect(function() toast:Destroy() end)
        end
    end)
end)
