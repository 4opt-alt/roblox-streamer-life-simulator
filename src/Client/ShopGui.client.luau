--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui

local ShopConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ShopConfig") :: ModuleScript)

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
local buyItemRemote = remotesFolder:WaitForChild("BuyShopItem") :: RemoteEvent
local shopResultRemote = remotesFolder:WaitForChild("ShopItemPurchased") :: RemoteEvent

-- Create Shop ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShopGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 5
screenGui.Parent = PlayerGui

-- Floating Quick Shop Button on screen
local openShopBtn = Instance.new("TextButton")
openShopBtn.Name = "OpenShopButton"
openShopBtn.Size = UDim2.new(0, 110, 0, 44)
openShopBtn.Position = UDim2.new(1, -125, 0.5, -22)
openShopBtn.BackgroundColor3 = Color3.fromRGB(41, 128, 185)
openShopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
openShopBtn.Font = Enum.Font.GothamBold
openShopBtn.TextSize = 15
openShopBtn.Text = "🛒 Shop"
openShopBtn.ZIndex = 10
openShopBtn.AutoButtonColor = true
openShopBtn.Active = true
openShopBtn.Parent = screenGui

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 10)
btnCorner.Parent = openShopBtn

local btnStroke = Instance.new("UIStroke")
btnStroke.Color = Color3.fromRGB(52, 152, 219)
btnStroke.Thickness = 1.5
btnStroke.Parent = openShopBtn

-- Modal Backdrop
local modalBackdrop = Instance.new("Frame")
modalBackdrop.Name = "ShopBackdrop"
modalBackdrop.Size = UDim2.new(1, 0, 1, 0)
modalBackdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
modalBackdrop.BackgroundTransparency = 0.55
modalBackdrop.Visible = false
modalBackdrop.ZIndex = 20
modalBackdrop.Parent = screenGui

-- Main Shop Window
local shopWindow = Instance.new("Frame")
shopWindow.Name = "ShopWindow"
shopWindow.Size = UDim2.new(0, 520, 0, 460)
shopWindow.Position = UDim2.new(0.5, -260, 0.5, -230)
shopWindow.BackgroundColor3 = Color3.fromRGB(22, 25, 34)
shopWindow.BorderSizePixel = 0
shopWindow.ZIndex = 21
shopWindow.Parent = modalBackdrop

local windowCorner = Instance.new("UICorner")
windowCorner.CornerRadius = UDim.new(0, 14)
windowCorner.Parent = shopWindow

local windowStroke = Instance.new("UIStroke")
windowStroke.Color = Color3.fromRGB(52, 152, 219)
windowStroke.Thickness = 1.8
windowStroke.Parent = shopWindow

-- Title Header
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -60, 0, 35)
titleLabel.Position = UDim2.new(0, 20, 0, 10)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 20
titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Text = "🛒 STREAMER GEAR & TECH SHOP"
titleLabel.ZIndex = 22
titleLabel.Parent = shopWindow

local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.Size = UDim2.new(1, -60, 0, 20)
subtitleLabel.Position = UDim2.new(0, 20, 0, 42)
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Font = Enum.Font.Gotham
subtitleLabel.TextSize = 13
subtitleLabel.TextColor3 = Color3.fromRGB(170, 175, 190)
subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
subtitleLabel.Text = "Equip better hardware to boost your Money and Subscribers per second!"
subtitleLabel.ZIndex = 22
subtitleLabel.Parent = shopWindow

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, 32, 0, 32)
closeBtn.Position = UDim2.new(1, -44, 0, 12)
closeBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.Text = "✕"
closeBtn.ZIndex = 22
closeBtn.Parent = shopWindow

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeBtn

-- Scrolling Items List
local scrollList = Instance.new("ScrollingFrame")
scrollList.Name = "ItemList"
scrollList.Size = UDim2.new(1, -24, 1, -85)
scrollList.Position = UDim2.new(0, 12, 0, 72)
scrollList.BackgroundTransparency = 1
scrollList.BorderSizePixel = 0
scrollList.ScrollBarThickness = 5
scrollList.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollList.ZIndex = 22
scrollList.Parent = shopWindow

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 8)
listLayout.Parent = scrollList

local itemButtons: { [string]: TextButton } = {}

local function refreshShopItems()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    local moneyVal = leaderstats and leaderstats:FindFirstChild("Money") :: IntValue?
    local currentMoney = moneyVal and moneyVal.Value or 0

    -- Sort items by price
    local sortedItems = {}
    for _, item in ShopConfig do
        table.insert(sortedItems, item)
    end
    table.sort(sortedItems, function(a, b) return a.Price < b.Price end)

    for order, item in sortedItems do
        local isOwned = LocalPlayer:GetAttribute("Owned_" .. item.Id) == true
        local btn = itemButtons[item.Id]

        if not btn then
            local card = Instance.new("Frame")
            card.Name = `Card_{item.Id}`
            card.LayoutOrder = order
            card.Size = UDim2.new(1, -8, 0, 64)
            card.BackgroundColor3 = Color3.fromRGB(28, 32, 42)
            card.ZIndex = 23
            card.Parent = scrollList

            local cardCorner = Instance.new("UICorner")
            cardCorner.CornerRadius = UDim.new(0, 10)
            cardCorner.Parent = card

            -- Icon
            local icon = Instance.new("TextLabel")
            icon.Size = UDim2.new(0, 48, 1, 0)
            icon.BackgroundTransparency = 1
            icon.Font = Enum.Font.GothamBold
            icon.TextSize = 24
            icon.Text = item.IconText
            icon.ZIndex = 24
            icon.Parent = card

            -- Info
            local name = Instance.new("TextLabel")
            name.Size = UDim2.new(1, -190, 0, 24)
            name.Position = UDim2.new(0, 52, 0, 8)
            name.BackgroundTransparency = 1
            name.Font = Enum.Font.GothamBold
            name.TextSize = 14
            name.TextColor3 = Color3.fromRGB(255, 255, 255)
            name.TextXAlignment = Enum.TextXAlignment.Left
            name.Text = item.Name
            name.ZIndex = 24
            name.Parent = card

            local desc = Instance.new("TextLabel")
            desc.Size = UDim2.new(1, -190, 0, 20)
            desc.Position = UDim2.new(0, 52, 0, 32)
            desc.BackgroundTransparency = 1
            desc.Font = Enum.Font.Gotham
            desc.TextSize = 12
            desc.TextColor3 = Color3.fromRGB(46, 204, 113)
            desc.TextXAlignment = Enum.TextXAlignment.Left
            desc.Text = item.Description
            desc.ZIndex = 24
            desc.Parent = card

            -- Buy Button
            local buyBtn = Instance.new("TextButton")
            buyBtn.Name = "BuyButton"
            buyBtn.Size = UDim2.new(0, 120, 0, 40)
            buyBtn.Position = UDim2.new(1, -130, 0.5, -20)
            buyBtn.Font = Enum.Font.GothamBold
            buyBtn.TextSize = 13
            buyBtn.ZIndex = 24
            buyBtn.Parent = card

            local buyCorner = Instance.new("UICorner")
            buyCorner.CornerRadius = UDim.new(0, 8)
            buyCorner.Parent = buyBtn

            buyBtn.MouseButton1Click:Connect(function()
                if not (LocalPlayer:GetAttribute("Owned_" .. item.Id) == true) then
                    buyItemRemote:FireServer(item.Id)
                end
            end)

            itemButtons[item.Id] = buyBtn
            btn = buyBtn
        end

        if isOwned then
            btn.Text = "✔ OWNED"
            btn.BackgroundColor3 = Color3.fromRGB(70, 75, 85)
            btn.TextColor3 = Color3.fromRGB(160, 165, 175)
            btn.AutoButtonColor = false
        elseif currentMoney >= item.Price then
            btn.Text = `Buy: ${item.Price}`
            btn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.AutoButtonColor = true
        else
            btn.Text = `🔒 ${item.Price}`
            btn.BackgroundColor3 = Color3.fromRGB(60, 30, 30)
            btn.TextColor3 = Color3.fromRGB(220, 120, 120)
            btn.AutoButtonColor = true
        end
    end
end

local function openShop()
    refreshShopItems()
    modalBackdrop.Visible = true
end

local function closeShop()
    modalBackdrop.Visible = false
end

openShopBtn.MouseButton1Click:Connect(openShop)
closeBtn.MouseButton1Click:Connect(closeShop)

shopResultRemote.OnClientEvent:Connect(function(itemId: string, success: boolean, message: string)
    refreshShopItems()
end)

LocalPlayer.AttributeChanged:Connect(function(attr)
    if attr:sub(1, 6) == "Owned_" then
        refreshShopItems()
    end
end)

-- Physical In-World Counter ProximityPrompts
local ProximityPromptService = game:GetService("ProximityPromptService")
ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, player: Player)
    if player == LocalPlayer then
        if prompt.Name == "TechPrompt" or prompt.Name == "GroceryPrompt" then
            openShop()
        end
    end
end)

