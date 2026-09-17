--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui

-- Load Shared Config
local StreamConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("StreamConfig") :: ModuleScript)

-- Connect to RemoteEvents
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
local toggleStreamRemote = remotesFolder:WaitForChild("ToggleStream") :: RemoteEvent
local streamStateChangedRemote = remotesFolder:WaitForChild("StreamStateChanged") :: RemoteEvent
local setChannelNameRemote = remotesFolder:WaitForChild("SetChannelName") :: RemoteEvent

-- Wait for UI elements
local streamGui = PlayerGui:WaitForChild("StreamGui") :: ScreenGui
local streamButton = streamGui:WaitForChild("StreamButton") :: TextButton

-- Channel Bar
local channelBar = streamGui:WaitForChild("ChannelBar") :: Frame
local channelTitleLabel = channelBar:WaitForChild("ChannelTitleLabel") :: TextLabel
local editChannelButton = channelBar:WaitForChild("EditChannelButton") :: TextButton

-- Live Chat Panel
local chatContainer = streamGui:WaitForChild("ChatContainer") :: Frame
local chatHeader = chatContainer:WaitForChild("ChatHeader") :: TextLabel
local scrollingFrame = chatContainer:WaitForChild("ChatScrollingFrame") :: ScrollingFrame

-- Modal Popup
local modalBackdrop = streamGui:WaitForChild("ChannelModalBackdrop") :: Frame
local modalBox = modalBackdrop:WaitForChild("ModalBox") :: Frame
local channelInputBox = modalBox:WaitForChild("ChannelInputBox") :: TextBox
local saveChannelButton = modalBox:WaitForChild("SaveChannelButton") :: TextButton
local closeModalButton = modalBox:WaitForChild("CloseModalButton") :: TextButton

local isLocalStreaming = false
local messageCount = 0

--------------------------------------------------------------------------------
-- Update Channel Name in UI
--------------------------------------------------------------------------------
local function updateChannelDisplay()
    local currentChannel = LocalPlayer:GetAttribute("ChannelName") or (LocalPlayer.DisplayName .. " TV")
    channelTitleLabel.Text = `📺 Channel: {currentChannel}`
    channelInputBox.Text = tostring(currentChannel)
end

updateChannelDisplay()
LocalPlayer:GetAttributeChangedSignal("ChannelName"):Connect(updateChannelDisplay)

--------------------------------------------------------------------------------
-- Modal Controls
--------------------------------------------------------------------------------
local function openModal()
    updateChannelDisplay()
    modalBackdrop.Visible = true
    channelInputBox:CaptureFocus()
end

local function closeModal()
    modalBackdrop.Visible = false
end

editChannelButton.MouseButton1Click:Connect(openModal)
closeModalButton.MouseButton1Click:Connect(closeModal)

saveChannelButton.MouseButton1Click:Connect(function()
    local input = channelInputBox.Text
    local cleaned = string.gsub(input, "^%s*(.-)%s*$", "%1")

    if #cleaned >= StreamConfig.MinChannelNameLength and #cleaned <= StreamConfig.MaxChannelNameLength then
        setChannelNameRemote:FireServer(cleaned)
        closeModal()
    else
        channelInputBox.PlaceholderText = "Between 3 and 20 characters!"
        channelInputBox.Text = ""
    end
end)

-- Prompt player to name channel on first join if default
task.delay(1.5, function()
    local currentChannel = LocalPlayer:GetAttribute("ChannelName")
    if not currentChannel or currentChannel == (LocalPlayer.DisplayName .. " TV") then
        openModal()
    end
end)

--------------------------------------------------------------------------------
-- Chat Feed Logic
--------------------------------------------------------------------------------
local function addComment(author: string, rawText: string)
    messageCount += 1

    local currentChannel = LocalPlayer:GetAttribute("ChannelName") or LocalPlayer.DisplayName
    -- Replace {channel} placeholder with actual channel name
    local formattedText = string.gsub(rawText, "{channel}", tostring(currentChannel))

    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = `Msg_{messageCount}`
    messageLabel.LayoutOrder = messageCount
    messageLabel.Size = UDim2.new(1, 0, 0, 0)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextSize = 13
    messageLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
    messageLabel.TextWrapped = true
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextYAlignment = Enum.TextYAlignment.Top
    messageLabel.AutomaticSize = Enum.AutomaticSize.Y
    messageLabel.RichText = true

    local nameColors = { "#4FC3F7", "#81C784", "#FFD54F", "#FF8A65", "#BA68C8", "#4DB6AC" }
    local chosenColor = nameColors[math.random(1, #nameColors)]

    messageLabel.Text = `<b><font color="{chosenColor}">@{author}</font></b>: {formattedText}`
    messageLabel.Parent = scrollingFrame

    -- Trim old messages to conserve memory
    local allMessages = scrollingFrame:GetChildren()
    local textLabels = {}
    for _, child in allMessages do
        if child:IsA("TextLabel") then
            table.insert(textLabels, child)
        end
    end

    if #textLabels > StreamConfig.MaxChatHistory then
        table.sort(textLabels, function(a, b)
            return a.LayoutOrder < b.LayoutOrder
        end)
        textLabels[1]:Destroy()
    end

    -- Auto-scroll
    task.defer(function()
        scrollingFrame.CanvasPosition = Vector2.new(0, 999999)
    end)
end

local function startCommentLoop()
    task.spawn(function()
        local currentChannel = LocalPlayer:GetAttribute("ChannelName") or LocalPlayer.DisplayName
        addComment("SYSTEM", `Stream started on «{currentChannel}»! Viewers are tuning in...`)

        while isLocalStreaming do
            local interval = math.random(
                math.floor(StreamConfig.CommentIntervalMin * 10),
                math.floor(StreamConfig.CommentIntervalMax * 10)
            ) / 10

            task.wait(interval)
            if not isLocalStreaming then
                break
            end

            local randomName = StreamConfig.ViewerNames[math.random(1, #StreamConfig.ViewerNames)]
            local gamesCount = LocalPlayer:GetAttribute("GamesOwnedCount") or 0
            local energy = (LocalPlayer:GetAttribute("Energy") :: number?) or 100
            local gearCount = LocalPlayer:GetAttribute("GearOwnedCount") or 0

            local commentPool = StreamConfig.ViewerComments
            local catKey = (LocalPlayer:GetAttribute("StreamCategory") :: string?) or "Gaming"

            if energy < 25 and #StreamConfig.LowEnergyComments > 0 then
                -- Втомлений стрімер
                commentPool = StreamConfig.LowEnergyComments
            elseif catKey == "Gaming" and gamesCount == 0 and #StreamConfig.NoGameComments > 0 and math.random() < 0.65 then
                -- Стрімер без ігор
                commentPool = StreamConfig.NoGameComments
            elseif catKey == "IRL" and StreamConfig.IRLComments and #StreamConfig.IRLComments > 0 and math.random() < 0.60 then
                commentPool = StreamConfig.IRLComments
            elseif catKey == "Gaming" and StreamConfig.GamingComments and #StreamConfig.GamingComments > 0 and math.random() < 0.60 then
                commentPool = StreamConfig.GamingComments
            elseif catKey == "JustChatting" and StreamConfig.JustChattingComments and #StreamConfig.JustChattingComments > 0 and math.random() < 0.60 then
                commentPool = StreamConfig.JustChattingComments
            elseif gearCount >= 3 and #StreamConfig.ProComments > 0 and math.random() < 0.5 then
                -- Крутий стрімер з топовим сетапом
                commentPool = StreamConfig.ProComments
            end

            local randomText = commentPool[math.random(1, #commentPool)]
            addComment(randomName, randomText)
        end

        addComment("SYSTEM", "Stream ended. Thanks for watching everyone!")
    end)
end

--------------------------------------------------------------------------------
-- Stream Toggle Interaction with Platform Selection & Category Checks
--------------------------------------------------------------------------------
streamButton.MouseButton1Click:Connect(function()
    if isLocalStreaming then
        -- Stop stream directly
        toggleStreamRemote:FireServer()
    else
        local lockedPlat = LocalPlayer:GetAttribute("LockedPlatform")
        if not lockedPlat or lockedPlat == "" then
            -- Platform not selected yet: open contract selection window
            if _G.OpenPlatformSelect then
                _G.OpenPlatformSelect(false)
            end
            return
        end

        local catKey = (LocalPlayer:GetAttribute("StreamCategory") :: string?) or "Gaming"
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
        local deskPos = Vector3.new(0, 4.5, -70)

        if (catKey == "Gaming" or catKey == "JustChatting") and root then
            local dist = (root.Position - deskPos).Magnitude
            if dist > 24 then
                addComment("SYSTEM", "⚠️ You must be at your Computer Battlestation to stream Gaming or Just Chatting! (Sit at your PC or switch to 📱 IRL)")
                return
            end
        end

        -- Stream directly with locked contract!
        toggleStreamRemote:FireServer(lockedPlat)
    end
end)

-- Prompt platform contract choice on join if not locked yet
task.delay(2.5, function()
    local locked = LocalPlayer:GetAttribute("LockedPlatform")
    if not locked or locked == "" then
        if _G.OpenPlatformSelect then
            _G.OpenPlatformSelect(false)
        end
    end
end)

streamStateChangedRemote.OnClientEvent:Connect(function(streamingState: boolean, platformKey: string?)
    isLocalStreaming = streamingState
    local currentChannel = LocalPlayer:GetAttribute("ChannelName") or LocalPlayer.DisplayName
    local plat = platformKey or "YouTube"
    local catKey = (LocalPlayer:GetAttribute("StreamCategory") :: string?) or "Gaming"
    local catIcon = if catKey == "IRL" then "📱" elseif catKey == "JustChatting" then "🎙️" else "🎮"

    if isLocalStreaming then
        TweenService:Create(streamButton, TweenInfo.new(0.25), {
            BackgroundColor3 = Color3.fromRGB(231, 76, 60),
        }):Play()
        streamButton.Text = `⏹ Stop Stream ({plat})`
        chatHeader.Text = `  🔴 «{currentChannel}» LIVE [{plat}] [{catIcon} {catKey}]`
        chatHeader.TextColor3 = Color3.fromRGB(255, 120, 120)

        startCommentLoop()
    else
        TweenService:Create(streamButton, TweenInfo.new(0.25), {
            BackgroundColor3 = Color3.fromRGB(46, 204, 113),
        }):Play()
        streamButton.Text = "▶ Start Stream"
        chatHeader.Text = `  💬 «{currentChannel}» (Offline)`
        chatHeader.TextColor3 = Color3.fromRGB(220, 225, 235)
    end
end)
