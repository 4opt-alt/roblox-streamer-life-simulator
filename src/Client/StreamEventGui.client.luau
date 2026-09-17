--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
local streamPromptRemote = remotesFolder:WaitForChild("StreamPromptEvent") :: RemoteEvent
local submitChoiceRemote = remotesFolder:WaitForChild("SubmitStreamChoice") :: RemoteEvent
local choiceResultRemote = remotesFolder:WaitForChild("StreamChoiceResult") :: RemoteEvent

-- ScreenGui for Interactive Stream Prompts
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StreamEventGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

-- Event Card (Centered at top)
local eventCard = Instance.new("Frame")
eventCard.Name = "EventCard"
eventCard.Size = UDim2.new(0, 440, 0, 260)
eventCard.Position = UDim2.new(0.5, -220, 0.12, 0)
eventCard.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
eventCard.BorderSizePixel = 0
eventCard.Visible = false
eventCard.ZIndex = 40
eventCard.Parent = screenGui

local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 14)
cardCorner.Parent = eventCard

local cardStroke = Instance.new("UIStroke")
cardStroke.Color = Color3.fromRGB(255, 170, 0)
cardStroke.Thickness = 2
cardStroke.Parent = eventCard

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, -20, 0, 32)
titleLabel.Position = UDim2.new(0, 10, 0, 10)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 17
titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
titleLabel.ZIndex = 41
titleLabel.Parent = eventCard

-- Situation description
local situationLabel = Instance.new("TextLabel")
situationLabel.Name = "SituationLabel"
situationLabel.Size = UDim2.new(1, -24, 0, 44)
situationLabel.Position = UDim2.new(0, 12, 0, 42)
situationLabel.BackgroundTransparency = 1
situationLabel.Font = Enum.Font.Gotham
situationLabel.TextSize = 13
situationLabel.TextColor3 = Color3.fromRGB(230, 235, 245)
situationLabel.TextWrapped = true
situationLabel.ZIndex = 41
situationLabel.Parent = eventCard

-- Timer Progress Bar
local timerBarBg = Instance.new("Frame")
timerBarBg.Name = "TimerBarBg"
timerBarBg.Size = UDim2.new(1, -24, 0, 6)
timerBarBg.Position = UDim2.new(0, 12, 0, 90)
timerBarBg.BackgroundColor3 = Color3.fromRGB(40, 45, 55)
timerBarBg.BorderSizePixel = 0
timerBarBg.ZIndex = 41
timerBarBg.Parent = eventCard

local timerCorner = Instance.new("UICorner")
timerCorner.CornerRadius = UDim.new(1, 0)
timerCorner.Parent = timerBarBg

local timerFill = Instance.new("Frame")
timerFill.Name = "TimerFill"
timerFill.Size = UDim2.new(1, 0, 1, 0)
timerFill.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
timerFill.BorderSizePixel = 0
timerFill.ZIndex = 42
timerFill.Parent = timerBarBg

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = timerFill

-- Buttons Container
local choicesContainer = Instance.new("Frame")
choicesContainer.Name = "ChoicesContainer"
choicesContainer.Size = UDim2.new(1, -24, 0, 140)
choicesContainer.Position = UDim2.new(0, 12, 0, 105)
choicesContainer.BackgroundTransparency = 1
choicesContainer.ZIndex = 41
choicesContainer.Parent = eventCard

local choicesLayout = Instance.new("UIListLayout")
choicesLayout.SortOrder = Enum.SortOrder.LayoutOrder
choicesLayout.Padding = UDim.new(0, 8)
choicesLayout.Parent = choicesContainer

local currentEventId = ""
local timerTween: Tween? = nil

local function showFloatingOutcome(text: string, isPositive: boolean)
    local floatLabel = Instance.new("TextLabel")
    floatLabel.Size = UDim2.new(0, 300, 0, 45)
    floatLabel.Position = UDim2.new(0.5, -150, 0.45, 0)
    floatLabel.BackgroundColor3 = if isPositive then Color3.fromRGB(30, 45, 30) else Color3.fromRGB(50, 25, 25)
    floatLabel.BackgroundTransparency = 0.2
    floatLabel.TextColor3 = if isPositive then Color3.fromRGB(46, 204, 113) else Color3.fromRGB(231, 76, 60)
    floatLabel.Font = Enum.Font.GothamBold
    floatLabel.TextSize = 16
    floatLabel.Text = text
    floatLabel.ZIndex = 50
    floatLabel.Parent = screenGui

    local stroke = Instance.new("UIStroke")
    stroke.Color = if isPositive then Color3.fromRGB(46, 204, 113) else Color3.fromRGB(231, 76, 60)
    stroke.Thickness = 2
    stroke.Parent = floatLabel

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = floatLabel

    TweenService:Create(floatLabel, TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -150, 0.35, 0),
        BackgroundTransparency = 1,
        TextTransparency = 1,
    }):Play()

    task.delay(2, function()
        floatLabel:Destroy()
    end)
end

-- Handle receiving prompt from server
streamPromptRemote.OnClientEvent:Connect(function(data: any)
    currentEventId = data.Id
    titleLabel.Text = data.Title
    situationLabel.Text = data.Situation

    -- Clear old buttons
    for _, ch in choicesContainer:GetChildren() do
        if ch:IsA("TextButton") then
            ch:Destroy()
        end
    end

    -- Create choice buttons
    for idx, choice in data.Choices do
        local btn = Instance.new("TextButton")
        btn.Name = `Choice_{choice.Id}`
        btn.LayoutOrder = idx
        btn.Size = UDim2.new(1, 0, 0, 38)
        btn.BackgroundColor3 = Color3.fromRGB(35, 40, 52)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 13
        btn.Text = choice.Text
        btn.ZIndex = 43
        btn.Parent = choicesContainer

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = btn

        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = Color3.fromRGB(60, 68, 85)
        btnStroke.Thickness = 1
        btnStroke.Parent = btn

        btn.MouseButton1Click:Connect(function()
            eventCard.Visible = false
            if timerTween then timerTween:Cancel() end
            submitChoiceRemote:FireServer(currentEventId, choice.Id)
        end)
    end

    -- Resize card according to number of choices
    eventCard.Size = UDim2.new(0, 440, 0, 120 + (#data.Choices * 46))
    choicesContainer.Size = UDim2.new(1, -24, 0, #data.Choices * 46)

    timerFill.Size = UDim2.new(1, 0, 1, 0)
    eventCard.Visible = true

    -- Animate countdown bar
    if timerTween then timerTween:Cancel() end
    timerTween = TweenService:Create(timerFill, TweenInfo.new(data.TimeoutSeconds, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 1, 0),
    })
    timerTween:Play()

    task.delay(data.TimeoutSeconds, function()
        if eventCard.Visible and currentEventId == data.Id then
            eventCard.Visible = false
        end
    end)
end)

-- Handle choice result
choiceResultRemote.OnClientEvent:Connect(function(res: any)
    local sign = if res.HypeDelta >= 0 then "+" else ""
    local hypeStr = `{sign}{res.HypeDelta} Subs`
    local moneyStr = if res.MoneyDelta > 0 then ` | +${res.MoneyDelta}` else ""
    local outcomeText = `{res.Message}\n({hypeStr}{moneyStr})`

    showFloatingOutcome(outcomeText, res.Success)
end)
