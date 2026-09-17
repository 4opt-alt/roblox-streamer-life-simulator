--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

-- Load Configs
local StreamConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("StreamConfig") :: ModuleScript)
local StreamEventsConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("StreamEventsConfig") :: ModuleScript)

-- Ensure Remotes Folder
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
    remotesFolder = Instance.new("Folder")
    remotesFolder.Name = "Remotes"
    remotesFolder.Parent = ReplicatedStorage
end

-- 1. Start / Stop Stream
local toggleStreamRemote = remotesFolder:FindFirstChild("ToggleStream") :: RemoteEvent?
if not toggleStreamRemote then
    toggleStreamRemote = Instance.new("RemoteEvent")
    toggleStreamRemote.Name = "ToggleStream"
    toggleStreamRemote.Parent = remotesFolder
end

-- 2. State Changed
local streamStateChangedRemote = remotesFolder:FindFirstChild("StreamStateChanged") :: RemoteEvent?
if not streamStateChangedRemote then
    streamStateChangedRemote = Instance.new("RemoteEvent")
    streamStateChangedRemote.Name = "StreamStateChanged"
    streamStateChangedRemote.Parent = remotesFolder
end

-- 3. Channel Name
local setChannelNameRemote = remotesFolder:FindFirstChild("SetChannelName") :: RemoteEvent?
if not setChannelNameRemote then
    setChannelNameRemote = Instance.new("RemoteEvent")
    setChannelNameRemote.Name = "SetChannelName"
    setChannelNameRemote.Parent = remotesFolder
end

-- 4. Dynamic Stream Prompt Event (Server -> Client)
local streamPromptRemote = remotesFolder:FindFirstChild("StreamPromptEvent") :: RemoteEvent?
if not streamPromptRemote then
    streamPromptRemote = Instance.new("RemoteEvent")
    streamPromptRemote.Name = "StreamPromptEvent"
    streamPromptRemote.Parent = remotesFolder
end

-- 5. Submit Choice (Client -> Server)
local submitChoiceRemote = remotesFolder:FindFirstChild("SubmitStreamChoice") :: RemoteEvent?
if not submitChoiceRemote then
    submitChoiceRemote = Instance.new("RemoteEvent")
    submitChoiceRemote.Name = "SubmitStreamChoice"
    submitChoiceRemote.Parent = remotesFolder
end

-- 6. Choice Feedback Result (Server -> Client)
local choiceResultRemote = remotesFolder:FindFirstChild("StreamChoiceResult") :: RemoteEvent?
if not choiceResultRemote then
    choiceResultRemote = Instance.new("RemoteEvent")
    choiceResultRemote.Name = "StreamChoiceResult"
    choiceResultRemote.Parent = remotesFolder
end

-- 7. Lock Platform Contract (Client -> Server)
local lockPlatformRemote = remotesFolder:FindFirstChild("LockPlatform") :: RemoteEvent?
if not lockPlatformRemote then
    lockPlatformRemote = Instance.new("RemoteEvent")
    lockPlatformRemote.Name = "LockPlatform"
    lockPlatformRemote.Parent = remotesFolder
end

-- 8. Perform Rebirth (Client -> Server)
local performRebirthRemote = remotesFolder:FindFirstChild("PerformRebirth") :: RemoteEvent?
if not performRebirthRemote then
    performRebirthRemote = Instance.new("RemoteEvent")
    performRebirthRemote.Name = "PerformRebirth"
    performRebirthRemote.Parent = remotesFolder
end

-- 9. Rebirth Result (Server -> Client)
local rebirthResultRemote = remotesFolder:FindFirstChild("RebirthResult") :: RemoteEvent?
if not rebirthResultRemote then
    rebirthResultRemote = Instance.new("RemoteEvent")
    rebirthResultRemote.Name = "RebirthResult"
    rebirthResultRemote.Parent = remotesFolder
end

-- 10. Prompt Platform Select Modal (Server -> Client)
local promptPlatformSelectRemote = remotesFolder:FindFirstChild("PromptPlatformSelect") :: RemoteEvent?
if not promptPlatformSelectRemote then
    promptPlatformSelectRemote = Instance.new("RemoteEvent")
    promptPlatformSelectRemote.Name = "PromptPlatformSelect"
    promptPlatformSelectRemote.Parent = remotesFolder
end

-- 11. Set Stream Category (Client -> Server)
local setStreamCategoryRemote = remotesFolder:FindFirstChild("SetStreamCategory") :: RemoteEvent?
if not setStreamCategoryRemote then
    setStreamCategoryRemote = Instance.new("RemoteEvent")
    setStreamCategoryRemote.Name = "SetStreamCategory"
    setStreamCategoryRemote.Parent = remotesFolder
end

-- State tracking
local isStreaming: { [Player]: boolean } = {}
local activePlatforms: { [Player]: string } = {}
local lastToggleTimestamp: { [Player]: number } = {}
local activeStreamThreads: { [Player]: thread? } = {}
local pendingEventByPlayer: { [Player]: any } = {}

local TOGGLE_COOLDOWN = 1.0

--------------------------------------------------------------------------------
-- Надголовий інтерфейс (Overhead BillboardGui)
--------------------------------------------------------------------------------
local function updateOverhead(character: Model, player: Player)
    local head = character:FindFirstChild("Head") :: BasePart?
    if not head then return end

    local existingGui = head:FindFirstChild("ChannelOverhead") :: BillboardGui?
    if not existingGui then
        existingGui = Instance.new("BillboardGui")
        existingGui.Name = "ChannelOverhead"
        existingGui.Size = UDim2.new(0, 230, 0, 70)
        existingGui.StudsOffset = Vector3.new(0, 2.6, 0)
        existingGui.AlwaysOnTop = true
        existingGui.MaxDistance = 70

        local frame = Instance.new("Frame")
        frame.Name = "Container"
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
        frame.BackgroundTransparency = 0.25
        frame.BorderSizePixel = 0
        frame.Parent = existingGui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = frame

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(52, 152, 219)
        stroke.Thickness = 1.2
        stroke.Parent = frame

        local channelLabel = Instance.new("TextLabel")
        channelLabel.Name = "ChannelNameLabel"
        channelLabel.Size = UDim2.new(1, 0, 0.48, 0)
        channelLabel.Position = UDim2.new(0, 0, 0.04, 0)
        channelLabel.BackgroundTransparency = 1
        channelLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
        channelLabel.Font = Enum.Font.GothamBold
        channelLabel.TextSize = 14
        channelLabel.Parent = frame

        local statsLabel = Instance.new("TextLabel")
        statsLabel.Name = "StatsLabel"
        statsLabel.Size = UDim2.new(1, 0, 0.44, 0)
        statsLabel.Position = UDim2.new(0, 0, 0.52, 0)
        statsLabel.BackgroundTransparency = 1
        statsLabel.TextColor3 = Color3.fromRGB(220, 225, 235)
        statsLabel.Font = Enum.Font.Gotham
        statsLabel.TextSize = 12
        statsLabel.Parent = frame

        existingGui.Parent = head
    end

    local channelName = player:GetAttribute("ChannelName") or (player.DisplayName .. " TV")
    local leaderstats = player:FindFirstChild("leaderstats")
    local hypeVal = leaderstats and leaderstats:FindFirstChild("Hype") :: IntValue?
    local hypeCount = hypeVal and hypeVal.Value or 0

    local container = existingGui:FindFirstChild("Container")
    if container then
        local cLabel = container:FindFirstChild("ChannelNameLabel") :: TextLabel?
        local sLabel = container:FindFirstChild("StatsLabel") :: TextLabel?

        local isVIP = player:GetAttribute("IsVIP") == true
        local rebirths = (player:GetAttribute("Rebirths") :: number?) or 0
        local tierReward = if rebirths > 0 then (StreamConfig :: any).GetRebirthReward(rebirths) else nil
        local rebirthTag = if tierReward then `{tierReward.TitleTag} ` elseif rebirths > 0 then `⭐[Rebirth {rebirths}] ` else ""

        if cLabel then
            if isVIP then
                cLabel.Text = `👑 [VIP] {rebirthTag}{channelName}`
                cLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
            else
                cLabel.Text = `{rebirthTag}{channelName}`
                cLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
        end
        local stroke = container:FindFirstChildOfClass("UIStroke")
        if stroke then
            stroke.Color = isVIP and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(52, 152, 219)
        end
        if sLabel then
            local isLive = isStreaming[player]
            local plat = activePlatforms[player] or "Live"
            local statusTag = if isLive then `<font color="#ff4d4d">● {plat}</font> | ` else ""
            sLabel.RichText = true
            sLabel.Text = `{statusTag}⭐ {hypeCount} Subscribers`
        end
    end
end

--------------------------------------------------------------------------------
-- Телефон стрімера в руці
--------------------------------------------------------------------------------
local function unequipPhone(player: Player)
    local character = player.Character
    if character then
        local phone = character:FindFirstChild("StreamPhone")
        if phone then phone:Destroy() end
    end
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        local phone = backpack:FindFirstChild("StreamPhone")
        if phone then phone:Destroy() end
    end
end

local function equipPhone(player: Player)
    local character = player.Character
    if not character then return end

    unequipPhone(player)

    local channelName = player:GetAttribute("ChannelName") or (player.DisplayName .. " TV")
    local platKey = activePlatforms[player] or "YouTube"
    local platInfo = StreamConfig.Platforms[platKey]
    local platColor = if platInfo then Color3.fromHex(platInfo.ColorHex) else Color3.fromRGB(52, 152, 219)

    local tool = Instance.new("Tool")
    tool.Name = "StreamPhone"
    tool.CanBeDropped = false
    tool.RequiresHandle = true
    tool.ToolTip = "Streaming Phone"

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.4, 0.8, 0.08)
    handle.Color = Color3.fromRGB(25, 25, 30)
    handle.Material = Enum.Material.SmoothPlastic
    handle.CastShadow = true
    handle.Parent = tool

    local screen = Instance.new("Part")
    screen.Name = "PhoneScreen"
    screen.Size = Vector3.new(0.36, 0.74, 0.02)
    screen.Color = platColor
    screen.Material = Enum.Material.Neon
    screen.CanCollide = false
    screen.CFrame = handle.CFrame * CFrame.new(0, 0, -0.04)
    screen.Parent = tool

    local screenWeld = Instance.new("WeldConstraint")
    screenWeld.Part0 = handle
    screenWeld.Part1 = screen
    screenWeld.Parent = handle

    local lens = Instance.new("Part")
    lens.Name = "CameraLens"
    lens.Size = Vector3.new(0.12, 0.12, 0.02)
    lens.Color = Color3.fromRGB(15, 15, 20)
    lens.Material = Enum.Material.Glass
    lens.CanCollide = false
    lens.CFrame = handle.CFrame * CFrame.new(0.1, 0.28, 0.04)
    lens.Parent = tool

    local lensWeld = Instance.new("WeldConstraint")
    lensWeld.Part0 = handle
    lensWeld.Part1 = lens
    lensWeld.Parent = handle

    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Face = Enum.NormalId.Back
    surfaceGui.CanvasSize = Vector2.new(120, 240)
    surfaceGui.Parent = screen

    local liveLabel = Instance.new("TextLabel")
    liveLabel.Size = UDim2.new(1, 0, 0.25, 0)
    liveLabel.Position = UDim2.new(0, 0, 0.08, 0)
    liveLabel.BackgroundTransparency = 1
    liveLabel.Text = `● {platKey}`
    liveLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
    liveLabel.Font = Enum.Font.GothamBold
    liveLabel.TextSize = 22
    liveLabel.Parent = surfaceGui

    local chanLabel = Instance.new("TextLabel")
    chanLabel.Size = UDim2.new(1, -10, 0.35, 0)
    chanLabel.Position = UDim2.new(0, 5, 0.35, 0)
    chanLabel.BackgroundTransparency = 1
    chanLabel.Text = tostring(channelName)
    chanLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    chanLabel.Font = Enum.Font.GothamMedium
    chanLabel.TextSize = 13
    chanLabel.TextWrapped = true
    chanLabel.Parent = surfaceGui

    tool.GripPos = Vector3.new(0, -0.15, 0)
    tool.GripForward = Vector3.new(0, 0, -1)
    tool.GripRight = Vector3.new(1, 0, 0)
    tool.GripUp = Vector3.new(0, 1, 0)

    tool.Parent = character
end

--------------------------------------------------------------------------------
-- 3D Кнопки YouTube на стіні над сетапом (YouTube Play Buttons Wall of Fame)
--------------------------------------------------------------------------------
local DESK_POSITION = Vector3.new(0, 4.5, -70)

local function updateStudioAwards(player: Player)
    local rebirths = (player:GetAttribute("Rebirths") :: number?) or 0
    if rebirths <= 0 then return end

    local awardsFolder = workspace:FindFirstChild("YouTubeAwardsWall") :: Folder?
    if not awardsFolder then
        awardsFolder = Instance.new("Folder")
        awardsFolder.Name = "YouTubeAwardsWall"
        awardsFolder.Parent = workspace
    end

    local xOffsets = {
        [1] = -4.0,
        [2] = -2.0,
        [3] = 0.0,
        [4] = 2.0,
        [5] = 4.0,
    }

    local channelName = player:GetAttribute("ChannelName") or (player.DisplayName .. " TV")

    for lvl = 1, math.min(rebirths, 5) do
        local plaqueName = `Award_Tier_{lvl}`
        local tier = (StreamConfig :: any).RebirthTiers[lvl]
        if not tier then continue end

        local existingModel = awardsFolder:FindFirstChild(plaqueName) :: Model?
        if existingModel then
            -- Update channel name if already exists
            local face = existingModel:FindFirstChild("FacePlate") :: BasePart?
            local sg = face and face:FindFirstChild("PlaqueGui") :: SurfaceGui?
            local bg = sg and sg:FindFirstChildOfClass("Frame")
            local nameLbl = bg and bg:FindFirstChild("NameLabel") :: TextLabel?
            if nameLbl then
                nameLbl.Text = channelName
            end
            continue
        end

        local plaqueModel = Instance.new("Model")
        plaqueModel.Name = plaqueName

        local posX = xOffsets[lvl] or (lvl * 2.0 - 6.0)
        local posY = 8.6
        local posZ = -73.15

        -- 1. Outer Frame (Shadow box brushed metal frame)
        local frame = Instance.new("Part")
        frame.Name = "Frame"
        frame.Size = Vector3.new(1.7, 2.2, 0.12)
        frame.CFrame = CFrame.new(posX, posY, posZ)
        frame.Anchored = true
        frame.CanCollide = false
        frame.Material = Enum.Material.Metal
        frame.Color = Color3.fromRGB(18, 20, 26)
        frame.Parent = plaqueModel

        -- 2. Inner Plaque Face
        local face = Instance.new("Part")
        face.Name = "FacePlate"
        face.Size = Vector3.new(1.5, 2.0, 0.04)
        face.CFrame = CFrame.new(posX, posY, posZ + 0.05)
        face.Anchored = true
        face.CanCollide = false
        face.Material = tier.Material
        face.Color = tier.PlaqueColor
        face.Parent = plaqueModel

        -- 3. Point Light Glow
        local glow = Instance.new("PointLight")
        glow.Color = tier.GlowColor
        glow.Brightness = 1.0
        glow.Range = 6
        glow.Parent = face

        -- 4. SurfaceGui for Authentic YouTube Button Inscription
        local sg = Instance.new("SurfaceGui")
        sg.Name = "PlaqueGui"
        sg.Face = Enum.NormalId.Front
        sg.CanvasSize = Vector2.new(300, 400)
        sg.LightInfluence = 0
        sg.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
        sg.Parent = face

        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1, 0, 1, 0)
        bg.BackgroundTransparency = 1
        bg.Parent = sg

        -- Red YouTube Play Button Icon
        local playBtnBg = Instance.new("Frame")
        playBtnBg.Size = UDim2.new(0, 120, 0, 84)
        playBtnBg.Position = UDim2.new(0.5, -60, 0, 36)
        playBtnBg.BackgroundColor3 = (lvl == 3) and Color3.fromRGB(0, 200, 255) or ((lvl == 5) and Color3.fromRGB(200, 10, 40) or Color3.fromRGB(230, 33, 23))
        playBtnBg.BorderSizePixel = 0
        playBtnBg.Parent = bg
        local pbc = Instance.new("UICorner"); pbc.CornerRadius = UDim.new(0, 24); pbc.Parent = playBtnBg

        local playTriangle = Instance.new("TextLabel")
        playTriangle.Size = UDim2.new(1, 0, 1, 0)
        playTriangle.BackgroundTransparency = 1
        playTriangle.Font = Enum.Font.GothamBold
        playTriangle.TextSize = 42
        playTriangle.TextColor3 = Color3.fromRGB(255, 255, 255)
        playTriangle.Text = "▶"
        playTriangle.Parent = playBtnBg

        -- Inscription
        local ytLogo = Instance.new("TextLabel")
        ytLogo.Size = UDim2.new(1, 0, 0, 30)
        ytLogo.Position = UDim2.new(0, 0, 0, 136)
        ytLogo.BackgroundTransparency = 1
        ytLogo.Font = Enum.Font.GothamBlack
        ytLogo.TextSize = 22
        ytLogo.TextColor3 = (lvl == 2) and Color3.fromRGB(120, 90, 10) or Color3.fromRGB(25, 25, 30)
        ytLogo.Text = "YouTube"
        ytLogo.Parent = bg

        local presTo = Instance.new("TextLabel")
        presTo.Size = UDim2.new(1, 0, 0, 18)
        presTo.Position = UDim2.new(0, 0, 0, 172)
        presTo.BackgroundTransparency = 1
        presTo.Font = Enum.Font.GothamMedium
        presTo.TextSize = 13
        presTo.TextColor3 = (lvl == 2) and Color3.fromRGB(100, 75, 10) or Color3.fromRGB(60, 60, 70)
        presTo.Text = "PRESENTED TO"
        presTo.Parent = bg

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "NameLabel"
        nameLabel.Size = UDim2.new(1, -20, 0, 36)
        nameLabel.Position = UDim2.new(0, 10, 0, 196)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.GothamBlack
        nameLabel.TextSize = 20
        nameLabel.TextColor3 = (lvl == 2) and Color3.fromRGB(80, 50, 0) or Color3.fromRGB(10, 10, 15)
        nameLabel.TextScaled = true
        nameLabel.Text = channelName
        nameLabel.Parent = bg

        local forPassing = Instance.new("TextLabel")
        forPassing.Size = UDim2.new(1, 0, 0, 18)
        forPassing.Position = UDim2.new(0, 0, 0, 240)
        forPassing.BackgroundTransparency = 1
        forPassing.Font = Enum.Font.Gotham
        forPassing.TextSize = 12
        forPassing.TextColor3 = (lvl == 2) and Color3.fromRGB(100, 75, 10) or Color3.fromRGB(70, 70, 80)
        forPassing.Text = "FOR PASSING"
        forPassing.Parent = bg

        local milestoneLabel = Instance.new("TextLabel")
        milestoneLabel.Size = UDim2.new(1, 0, 0, 32)
        milestoneLabel.Position = UDim2.new(0, 0, 0, 262)
        milestoneLabel.BackgroundTransparency = 1
        milestoneLabel.Font = Enum.Font.GothamBold
        milestoneLabel.TextSize = 17
        milestoneLabel.TextColor3 = (lvl == 2) and Color3.fromRGB(80, 50, 0) or Color3.fromRGB(15, 15, 20)
        milestoneLabel.Text = tier.MilestoneText:upper()
        milestoneLabel.Parent = bg

        plaqueModel.Parent = awardsFolder
    end
end

--------------------------------------------------------------------------------
-- Керування ПК-монітором, веб-камерою та сетапом (PC Battlestation WebCam)
--------------------------------------------------------------------------------
local webcamLoopThread: thread? = nil
local monitorChatLoopThread: thread? = nil

local function updateMonitorDisplay(isLive: boolean, categoryKey: string?, platformStr: string?, player: Player?)
    local mainMon = workspace:FindFirstChild("MainMonitorScreen", true) :: BasePart?
    local leftMon = workspace:FindFirstChild("LeftMonitorScreen", true) :: BasePart?
    if not mainMon then return end

    -- Cancel previous webcam and monitor chat animation loops
    if webcamLoopThread then
        task.cancel(webcamLoopThread)
        webcamLoopThread = nil
    end
    if monitorChatLoopThread then
        task.cancel(monitorChatLoopThread)
        monitorChatLoopThread = nil
    end

    local sg = mainMon:FindFirstChild("MonitorGui") :: SurfaceGui?
    if not sg then
        sg = Instance.new("SurfaceGui")
        sg.Name = "MonitorGui"
        sg.Face = Enum.NormalId.Back
        sg.CanvasSize = Vector2.new(800, 420)
        sg.LightInfluence = 0
        sg.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
        sg.Parent = mainMon
    end

    sg:ClearAllChildren()

    local bgFrame = Instance.new("Frame")
    bgFrame.Name = "MonitorBg"
    bgFrame.Size = UDim2.new(1, 0, 1, 0)
    bgFrame.BackgroundColor3 = Color3.fromRGB(12, 15, 22)
    bgFrame.BorderSizePixel = 0
    bgFrame.Parent = sg

    -- Setup left secondary monitor (Live Scrolling Fast Chat!)
    if leftMon then
        local leftSg = leftMon:FindFirstChild("LeftMonitorGui") :: SurfaceGui?
        if not leftSg then
            leftSg = Instance.new("SurfaceGui")
            leftSg.Name = "LeftMonitorGui"
            leftSg.Face = Enum.NormalId.Back
            leftSg.CanvasSize = Vector2.new(600, 420)
            leftSg.LightInfluence = 0
            leftSg.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
            leftSg.Parent = leftMon
        end
        leftSg:ClearAllChildren()

        local leftBg = Instance.new("Frame")
        leftBg.Size = UDim2.new(1, 0, 1, 0)
        leftBg.BackgroundColor3 = Color3.fromRGB(14, 16, 22)
        leftBg.BorderSizePixel = 0
        leftBg.Parent = leftSg

        -- Header Bar
        local leftHeader = Instance.new("Frame")
        leftHeader.Size = UDim2.new(1, 0, 0, 42)
        leftHeader.BackgroundColor3 = Color3.fromRGB(22, 26, 38)
        leftHeader.BorderSizePixel = 0
        leftHeader.Parent = leftBg

        local headerStroke = Instance.new("UIStroke")
        headerStroke.Color = Color3.fromRGB(45, 55, 75)
        headerStroke.Thickness = 1
        headerStroke.Parent = leftHeader

        local titlePlat = platformStr and platformStr:gsub("+", " + ") or "STREAM"
        local headerLabel = Instance.new("TextLabel")
        headerLabel.Size = UDim2.new(1, -140, 1, 0)
        headerLabel.Position = UDim2.new(0, 14, 0, 0)
        headerLabel.BackgroundTransparency = 1
        headerLabel.Font = Enum.Font.GothamBold
        headerLabel.TextSize = 15
        headerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        headerLabel.TextXAlignment = Enum.TextXAlignment.Left
        headerLabel.Text = isLive and `💬 {titlePlat} LIVE CHAT` or "💬 STREAM CHAT • STANDBY"
        headerLabel.Parent = leftHeader

        local liveBadge = Instance.new("TextLabel")
        liveBadge.Size = UDim2.new(0, 110, 0, 26)
        liveBadge.Position = UDim2.new(1, -120, 0.5, -13)
        liveBadge.BackgroundColor3 = isLive and Color3.fromRGB(231, 76, 60) or Color3.fromRGB(45, 55, 70)
        liveBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
        liveBadge.Font = Enum.Font.GothamBold
        liveBadge.TextSize = 12
        liveBadge.Text = isLive and "🔴 LIVE CHAT" or "⚪ OFFLINE"
        liveBadge.Parent = leftHeader
        local lbc = Instance.new("UICorner"); lbc.CornerRadius = UDim.new(0, 6); lbc.Parent = liveBadge

        if not isLive or not player then
            -- Offline message
            local offlineBox = Instance.new("Frame")
            offlineBox.Size = UDim2.new(1, -40, 0, 140)
            offlineBox.Position = UDim2.new(0, 20, 0.5, -70)
            offlineBox.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
            offlineBox.BorderSizePixel = 0
            offlineBox.Parent = leftBg
            local obc = Instance.new("UICorner"); obc.CornerRadius = UDim.new(0, 10); obc.Parent = offlineBox
            local obs = Instance.new("UIStroke"); obs.Color = Color3.fromRGB(45, 55, 75); obs.Thickness = 1; obs.Parent = offlineBox

            local offText = Instance.new("TextLabel")
            offText.Size = UDim2.new(1, -20, 1, 0)
            offText.Position = UDim2.new(0, 10, 0, 0)
            offText.BackgroundTransparency = 1
            offText.Font = Enum.Font.GothamMedium
            offText.TextSize = 14
            offText.TextColor3 = Color3.fromRGB(160, 175, 205)
            offText.TextWrapped = true
            offText.Text = "📡 Stream Chat is offline.\n\nSit at the Battlestation and click Start Stream to go live and connect your high-speed audience chat!"
            offText.Parent = offlineBox
        else
            -- Live scrolling chat container (Біжить чат!)
            local chatScroll = Instance.new("ScrollingFrame")
            chatScroll.Name = "ChatScroll"
            chatScroll.Size = UDim2.new(1, -20, 1, -52)
            chatScroll.Position = UDim2.new(0, 10, 0, 47)
            chatScroll.BackgroundTransparency = 1
            chatScroll.BorderSizePixel = 0
            chatScroll.ScrollBarThickness = 5
            chatScroll.ScrollBarImageColor3 = Color3.fromRGB(65, 80, 115)
            chatScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
            chatScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
            chatScroll.Parent = leftBg

            local chatLayout = Instance.new("UIListLayout")
            chatLayout.SortOrder = Enum.SortOrder.LayoutOrder
            chatLayout.Padding = UDim.new(0, 5)
            chatLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
            chatLayout.Parent = chatScroll

            local chatMessagesList: { Frame } = {}
            local msgOrder = 0

            local viewerNames = {
                "AlexPro_UA", "CyberNinja", "NeonValkyrie", "PixelGamer", "Vortex99",
                "TurboSlayer", "ShadowWolf", "GamerGirl_Kyiv", "StarWatcher", "RoboFanatic",
                "GlitchMaster", "EchoStream", "HyperClutch", "OmegaGamer", "LunaPlayz",
                "ZeroCool", "DarkKnight", "LuckyStrike", "PixelQueen", "BlazeRunner"
            }

            local badges = {
                { Text = "[VIP]", Color = "#e67e22" },
                { Text = "[SUB 6m]", Color = "#9b59b6" },
                { Text = "[MOD]", Color = "#2ecc71" },
                { Text = "[PRIME]", Color = "#3498db" },
                { Text = "[FAN]", Color = "#f1c40f" },
            }

            local normalTexts = {
                "POGGGGGGG 😲😲",
                "W STREAMER!! 🔥🔥",
                "THAT PLAY WAS SO CLEAN!",
                "bro is on fire today!!",
                "Ukranian streamer on top 🇺🇦💪",
                "LMAOOOO 💀💀",
                "sheeesh 240 FPS looking crisp",
                "drop the setup specs in chat please!",
                "CLIP IT RIGHT NOW 🎬🎬",
                "Hype train level 3 incoming! 🚂🚂",
                "chat spam W in the chat boys!",
                "WWWWWWWWWW",
                "how much did that chair cost bro??",
                "Silver Play Button soon!! 🥈",
                "GOAT streamer fr fr 🐐",
                "Subbed with Prime! Enjoy! ⭐",
                "BEST STREAM TODAY!! 🎉",
                "GG WP 🔥🔥",
                "can you play Horror Night next??",
                "take my energyyyy ⚡⚡",
                "INSANE REACTION TIME ⚡",
                "Bro doesn't miss! 🎯",
            }

            local function addMessage(richTextStr: string, isSuperChat: boolean?)
                msgOrder += 1

                local msgCard = Instance.new("Frame")
                msgCard.Name = `Msg_{msgOrder}`
                msgCard.LayoutOrder = msgOrder
                msgCard.BorderSizePixel = 0
                msgCard.Parent = chatScroll

                if isSuperChat then
                    msgCard.Size = UDim2.new(1, -6, 0, 36)
                    msgCard.BackgroundColor3 = Color3.fromRGB(38, 48, 28)
                    local mcCorner = Instance.new("UICorner"); mcCorner.CornerRadius = UDim.new(0, 6); mcCorner.Parent = msgCard
                    local mcStroke = Instance.new("UIStroke"); mcStroke.Color = Color3.fromRGB(255, 215, 0); mcStroke.Thickness = 1.2; mcStroke.Parent = msgCard
                else
                    msgCard.Size = UDim2.new(1, -6, 0, 26)
                    msgCard.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
                    local mcCorner = Instance.new("UICorner"); mcCorner.CornerRadius = UDim.new(0, 5); mcCorner.Parent = msgCard
                end

                local msgLabel = Instance.new("TextLabel")
                msgLabel.Size = UDim2.new(1, -12, 1, 0)
                msgLabel.Position = UDim2.new(0, 8, 0, 0)
                msgLabel.BackgroundTransparency = 1
                msgLabel.Font = Enum.Font.GothamMedium
                msgLabel.TextSize = 13
                msgLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                msgLabel.TextXAlignment = Enum.TextXAlignment.Left
                msgLabel.RichText = true
                msgLabel.Text = richTextStr
                msgLabel.Parent = msgCard

                table.insert(chatMessagesList, msgCard)
                if #chatMessagesList > 22 then
                    local oldest = table.remove(chatMessagesList, 1)
                    if oldest then oldest:Destroy() end
                end

                chatScroll.CanvasPosition = Vector2.new(0, 999999)
            end

            -- Seed with initial chat messages so it starts lively
            addMessage(`<font color="#8892b0"><b>[BOT]</b></font> <font color="#2ecc71">Welcome to the stream! Enjoy the broadcast!</font>`)
            addMessage(`<font color="#9b59b6"><b>[VIP]</b></font> <font color="#3498db"><b>AlexPro_UA</b></font>: First in chat! Let's go! 🔥`)
            addMessage(`<font color="#f1c40f"><b>[FAN]</b></font> <font color="#e67e22"><b>PixelGamer</b></font>: W streamer! Ready for ranked!`)

            -- Running chat loop (біжить чат!)
            monitorChatLoopThread = task.spawn(function()
                while isStreaming[player] do
                    task.wait(math.random(35, 80) / 100) -- Generates new message every 0.35s - 0.8s!
                    if not isStreaming[player] or not chatScroll.Parent then break end

                    local roll = math.random(1, 100)
                    local vName = viewerNames[math.random(1, #viewerNames)]

                    if roll <= 12 then
                        -- SuperChat / Donation ($10 - $100)
                        local donAmt = math.random(10, 100)
                        addMessage(`💰 <font color="#ffd700"><b>{vName}</b> donated <b>${donAmt}</b>: "Awesome stream, keep it up!"</font>`, true)
                    elseif roll <= 20 then
                        -- New Subscriber announcement
                        addMessage(`⭐ <font color="#55efc4"><b>{vName}</b></font> <font color="#a29bfe">just SUBSCRIBED to the channel! 🌟</font>`)
                    else
                        -- Standard live chat message
                        local badge = badges[math.random(1, #badges)]
                        local txt = normalTexts[math.random(1, #normalTexts)]
                        addMessage(`<font color="{badge.Color}"><b>{badge.Text}</b></font> <font color="#74b9ff"><b>{vName}</b></font>: {txt}`)
                    end
                end
            end)
        end
    end

    if not isLive or not player then
        -- OFFLINE / STANDBY SCREEN
        mainMon.Material = Enum.Material.Neon
        mainMon.Color = Color3.fromRGB(25, 30, 42)

        local offlineTitle = Instance.new("TextLabel")
        offlineTitle.Size = UDim2.new(1, 0, 0, 60)
        offlineTitle.Position = UDim2.new(0, 0, 0.35, 0)
        offlineTitle.BackgroundTransparency = 1
        offlineTitle.Font = Enum.Font.GothamBlack
        offlineTitle.TextSize = 36
        offlineTitle.TextColor3 = Color3.fromRGB(100, 130, 180)
        offlineTitle.Text = "🖥️ Battlestation OS v2.4"
        offlineTitle.Parent = bgFrame

        local offlineSub = Instance.new("TextLabel")
        offlineSub.Size = UDim2.new(1, 0, 0, 30)
        offlineSub.Position = UDim2.new(0, 0, 0.52, 0)
        offlineSub.BackgroundTransparency = 1
        offlineSub.Font = Enum.Font.GothamMedium
        offlineSub.TextSize = 20
        offlineSub.TextColor3 = Color3.fromRGB(150, 170, 200)
        offlineSub.Text = "[Sit at Battlestation & Click Start Stream]"
        offlineSub.Parent = bgFrame
        return
    end

    -- =========================================================================
    -- ONLINE STREAMING SCREEN WITH LIVE AVATAR WEBCAM!
    -- =========================================================================
    mainMon.Material = Enum.Material.Neon
    mainMon.Color = (categoryKey == "Gaming") and Color3.fromRGB(130, 60, 220) or Color3.fromRGB(240, 140, 20)

    -- 1. Top OBS Status Bar
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, 38)
    topBar.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
    topBar.BorderSizePixel = 0
    topBar.Parent = bgFrame

    local recDot = Instance.new("TextLabel")
    recDot.Size = UDim2.new(0, 30, 1, 0)
    recDot.Position = UDim2.new(0, 10, 0, 0)
    recDot.BackgroundTransparency = 1
    recDot.Font = Enum.Font.GothamBlack
    recDot.TextSize = 18
    recDot.TextColor3 = Color3.fromRGB(231, 76, 60)
    recDot.Text = "●"
    recDot.Parent = topBar

    local obsTitle = Instance.new("TextLabel")
    obsTitle.Size = UDim2.new(0, 240, 1, 0)
    obsTitle.Position = UDim2.new(0, 36, 0, 0)
    obsTitle.BackgroundTransparency = 1
    obsTitle.Font = Enum.Font.GothamBold
    obsTitle.TextSize = 13
    obsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    obsTitle.TextXAlignment = Enum.TextXAlignment.Left
    obsTitle.Text = "LIVE BROADCAST | OBS Studio"
    obsTitle.Parent = topBar

    local platBadge = Instance.new("TextLabel")
    platBadge.Size = UDim2.new(0, 220, 0, 26)
    platBadge.Position = UDim2.new(0.5, -110, 0.5, -13)
    platBadge.BackgroundColor3 = (categoryKey == "Gaming") and Color3.fromRGB(90, 40, 150) or Color3.fromRGB(180, 80, 20)
    platBadge.Font = Enum.Font.GothamBold
    platBadge.TextSize = 12
    platBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
    platBadge.Text = `📡 {platformStr or "YOUTUBE"}`
    platBadge.Parent = topBar
    local pbCorner = Instance.new("UICorner"); pbCorner.CornerRadius = UDim.new(0, 6); pbCorner.Parent = platBadge

    local statsText = Instance.new("TextLabel")
    statsText.Size = UDim2.new(0, 220, 1, 0)
    statsText.Position = UDim2.new(1, -230, 0, 0)
    statsText.BackgroundTransparency = 1
    statsText.Font = Enum.Font.Gotham
    statsText.TextSize = 12
    statsText.TextColor3 = Color3.fromRGB(160, 175, 200)
    statsText.TextXAlignment = Enum.TextXAlignment.Right
    statsText.Text = "60 FPS | 6,000 Kbps | 0 Drop"
    statsText.Parent = topBar

    -- 2. Left Main Gameplay / Talk Viewport (488 x 366)
    local leftArea = Instance.new("Frame")
    leftArea.Name = "LeftArea"
    leftArea.Size = UDim2.new(0, 488, 0, 366)
    leftArea.Position = UDim2.new(0, 12, 0, 44)
    leftArea.BackgroundColor3 = Color3.fromRGB(16, 20, 28)
    leftArea.BorderSizePixel = 0
    leftArea.Parent = bgFrame
    local laCorner = Instance.new("UICorner"); laCorner.CornerRadius = UDim.new(0, 8); laCorner.Parent = leftArea
    local laStroke = Instance.new("UIStroke"); laStroke.Color = Color3.fromRGB(40, 50, 70); laStroke.Thickness = 1.2; laStroke.Parent = leftArea

    local laHeader = Instance.new("TextLabel")
    laHeader.Size = UDim2.new(1, 0, 0, 32)
    laHeader.BackgroundColor3 = Color3.fromRGB(22, 27, 38)
    laHeader.Font = Enum.Font.GothamBold
    laHeader.TextSize = 12
    laHeader.TextColor3 = (categoryKey == "Gaming") and Color3.fromRGB(210, 140, 255) or Color3.fromRGB(255, 200, 80)
    laHeader.Text = (categoryKey == "Gaming") and "🎮 GAMEPLAY: CYBERSHOOTER 2026 (Ranked)" or "🎙️ STUDIO TALK SHOW: COMMUNITY Q&A"
    laHeader.Parent = leftArea
    local lahCorner = Instance.new("UICorner"); lahCorner.CornerRadius = UDim.new(0, 8); lahCorner.Parent = laHeader

    local laScreen = Instance.new("Frame")
    laScreen.Size = UDim2.new(1, -16, 1, -44)
    laScreen.Position = UDim2.new(0, 8, 0, 36)
    laScreen.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
    laScreen.BorderSizePixel = 0
    laScreen.Parent = leftArea
    local lasCorner = Instance.new("UICorner"); lasCorner.CornerRadius = UDim.new(0, 6); lasCorner.Parent = laScreen

    local gameOverlay = Instance.new("TextLabel")
    gameOverlay.Size = UDim2.new(1, 0, 1, 0)
    gameOverlay.BackgroundTransparency = 1
    gameOverlay.Font = Enum.Font.GothamBold
    gameOverlay.TextSize = 17
    gameOverlay.TextColor3 = Color3.fromRGB(255, 255, 255)
    if categoryKey == "Gaming" then
        gameOverlay.Text = "🕹️ 240 FPS ULTRA GAMEPLAY\n\n🏆 SCORE: 148,200  |  💥 KILLS: 16\n🔥 WIN STREAK: 5 WINS IN A ROW!"
    else
        gameOverlay.Text = "🎙️ LIVE PODCAST & TALK SHOW\n\n💬 TOPIC: STREAMER LIFE SIMULATOR\n⭐ AUDIENCE PARTICIPATION: ACTIVE"
    end
    gameOverlay.Parent = laScreen

    -- 3. Right LIVE WEBCAM WINDOW (280 x 366)
    local webcamArea = Instance.new("Frame")
    webcamArea.Name = "WebcamArea"
    webcamArea.Size = UDim2.new(0, 280, 0, 366)
    webcamArea.Position = UDim2.new(0, 508, 0, 44)
    webcamArea.BackgroundColor3 = Color3.fromRGB(14, 16, 24)
    webcamArea.BorderSizePixel = 0
    webcamArea.Parent = bgFrame
    local wCorner = Instance.new("UICorner"); wCorner.CornerRadius = UDim.new(0, 8); wCorner.Parent = webcamArea
    local wStroke = Instance.new("UIStroke"); wStroke.Color = Color3.fromRGB(46, 204, 113); wStroke.Thickness = 2; wStroke.Parent = webcamArea

    -- Webcam Header
    local camHeader = Instance.new("Frame")
    camHeader.Size = UDim2.new(1, 0, 0, 30)
    camHeader.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
    camHeader.BorderSizePixel = 0
    camHeader.Parent = webcamArea
    local chCorner = Instance.new("UICorner"); chCorner.CornerRadius = UDim.new(0, 8); chCorner.Parent = camHeader

    local camTitle = Instance.new("TextLabel")
    camTitle.Size = UDim2.new(1, -70, 1, 0)
    camTitle.Position = UDim2.new(0, 10, 0, 0)
    camTitle.BackgroundTransparency = 1
    camTitle.Font = Enum.Font.GothamBold
    camTitle.TextSize = 11
    camTitle.TextColor3 = Color3.fromRGB(240, 245, 255)
    camTitle.TextXAlignment = Enum.TextXAlignment.Left
    camTitle.Text = "📷 FACECAM 1080p 60FPS"
    camTitle.Parent = camHeader

    local camLiveTag = Instance.new("TextLabel")
    camLiveTag.Size = UDim2.new(0, 54, 0, 18)
    camLiveTag.Position = UDim2.new(1, -60, 0.5, -9)
    camLiveTag.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    camLiveTag.Font = Enum.Font.GothamBold
    camLiveTag.TextSize = 9
    camLiveTag.TextColor3 = Color3.fromRGB(255, 255, 255)
    camLiveTag.Text = "🔴 REC"
    camLiveTag.Parent = camHeader
    local clCorner = Instance.new("UICorner"); clCorner.CornerRadius = UDim.new(0, 4); clCorner.Parent = camLiveTag

    -- Real Avatar Facecam Image
    local camImg = Instance.new("ImageLabel")
    camImg.Name = "WebcamImage"
    camImg.Size = UDim2.new(1, -16, 1, -78)
    camImg.Position = UDim2.new(0, 8, 0, 34)
    camImg.BackgroundColor3 = Color3.fromRGB(8, 10, 15)
    camImg.BorderSizePixel = 0
    camImg.ScaleType = Enum.ScaleType.Fit
    camImg.Parent = webcamArea
    local ciCorner = Instance.new("UICorner"); ciCorner.CornerRadius = UDim.new(0, 6); ciCorner.Parent = camImg

    -- Load real avatar headshot/bust thumbnail
    task.spawn(function()
        local thumbType = Enum.ThumbnailType.AvatarBust
        local thumbSize = Enum.ThumbnailSize.Size420x420
        local content, isReady = Players:GetUserThumbnailAsync(player.UserId, thumbType, thumbSize)
        if content and camImg.Parent ~= nil then
            camImg.Image = content
        end
    end)

    -- Bottom Streamer Banner (Username + Dynamic Mic Meter)
    local bottomBanner = Instance.new("Frame")
    bottomBanner.Size = UDim2.new(1, -16, 0, 34)
    bottomBanner.Position = UDim2.new(0, 8, 1, -40)
    bottomBanner.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
    bottomBanner.BorderSizePixel = 0
    bottomBanner.Parent = webcamArea
    local bbCorner = Instance.new("UICorner"); bbCorner.CornerRadius = UDim.new(0, 6); bbCorner.Parent = bottomBanner

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.65, 0, 1, 0)
    nameLabel.Position = UDim2.new(0, 8, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 12
    nameLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Text = `👤 {player.DisplayName}`
    nameLabel.Parent = bottomBanner

    local micMeter = Instance.new("TextLabel")
    micMeter.Size = UDim2.new(0.35, -8, 1, 0)
    micMeter.Position = UDim2.new(0.65, 0, 0, 0)
    micMeter.BackgroundTransparency = 1
    micMeter.Font = Enum.Font.GothamBold
    micMeter.TextSize = 11
    micMeter.TextColor3 = Color3.fromRGB(46, 204, 113)
    micMeter.TextXAlignment = Enum.TextXAlignment.Right
    micMeter.Text = "🎙️ ▂▄▆█"
    micMeter.Parent = bottomBanner

    -- Animate mic VU meter and blinking REC dot
    webcamLoopThread = task.spawn(function()
        local patterns = { "🎙️ ▂▃", "🎙️ ▂▄▅", "🎙️ ▂▄▆█", "🎙️ ▂▄▅", "🎙️ ▂▃▄" }
        local pIdx = 1
        local blink = true
        while isLive and webcamArea.Parent ~= nil do
            task.wait(0.4)
            pIdx = (pIdx % #patterns) + 1
            if micMeter.Parent then
                micMeter.Text = patterns[pIdx]
            end
            blink = not blink
            if camLiveTag.Parent then
                camLiveTag.Visible = blink
            end
            if recDot.Parent then
                recDot.TextColor3 = blink and Color3.fromRGB(231, 76, 60) or Color3.fromRGB(100, 30, 30)
            end
        end
    end)
end

--------------------------------------------------------------------------------
-- Зупинка та запуск стріму з вибором платформи та категорії
--------------------------------------------------------------------------------
local function stopStream(player: Player)
    isStreaming[player] = false
    activeStreamThreads[player] = nil
    pendingEventByPlayer[player] = nil

    unequipPhone(player)
    updateMonitorDisplay(false, nil, nil, player)

    player:SetAttribute("ActiveStreamPlatforms", "")
    player:SetAttribute("IsStreamingYouTube", false)
    player:SetAttribute("IsStreamingTwitch", false)
    player:SetAttribute("IsStreamingTikTok", false)
    player:SetAttribute("IsPCStream", false)
    player:SetAttribute("IsPhoneStream", false)

    if player.Character then
        updateOverhead(player.Character, player)
    end

    if player.Parent ~= nil then
        streamStateChangedRemote:FireClient(player, false, "")
    end
end

local function triggerRandomStreamEvent(player: Player)
    if not isStreaming[player] or pendingEventByPlayer[player] ~= nil then
        return
    end

    local randomEvent = StreamEventsConfig[math.random(1, #StreamEventsConfig)]
    pendingEventByPlayer[player] = randomEvent

    streamPromptRemote:FireClient(player, {
        Id = randomEvent.Id,
        Title = randomEvent.Title,
        Situation = randomEvent.Situation,
        TimeoutSeconds = randomEvent.TimeoutSeconds,
        Choices = randomEvent.Choices,
    })

    -- Auto timeout after TimeoutSeconds + 1s
    task.delay(randomEvent.TimeoutSeconds + 1, function()
        if pendingEventByPlayer[player] == randomEvent then
            pendingEventByPlayer[player] = nil
        end
    end)
end

local function parsePlatformSelection(player: Player, platformKey: string): ({ string }, number, number)
    local rawList = {}
    for part in string.gmatch(platformKey, "[^+]+") do
        local trimmed = string.match(part, "^%s*(.-)%s*$")
        if trimmed and (trimmed == "YouTube" or trimmed == "Twitch" or trimmed == "TikTok") then
            if not table.find(rawList, trimmed) then
                table.insert(rawList, trimmed)
            end
        end
    end

    if #rawList == 0 then
        table.insert(rawList, "YouTube")
    end

    local hasSplitLicense = player:GetAttribute("Owned_MultiStreamLicense") == true

    -- Without Robux Split Pass: can ONLY stream to ONE platform!
    if not hasSplitLicense or #rawList == 1 then
        local singlePlat = rawList[1]
        local info = StreamConfig.Platforms[singlePlat] or StreamConfig.Platforms.YouTube
        return { singlePlat }, info.MoneyMultiplier, info.HypeMultiplier
    else
        -- With Robux Split Pass: stream to TWO platforms simultaneously!
        local selectedTwo = { rawList[1], rawList[2] }
        return selectedTwo, 1.85, 1.50
    end
end

local function startStream(player: Player, platformKey: string)
    if isStreaming[player] then return end

    local validPlatforms, moneyMult, hypeMult = parsePlatformSelection(player, platformKey)
    local displayPlatformStr = table.concat(validPlatforms, " + ")

    local categoryKey = (player:GetAttribute("StreamCategory") :: string?) or "Gaming"
    local catInfo = StreamConfig.Categories[categoryKey] or StreamConfig.Categories.Gaming
    local isPC = catInfo.RequiresPC

    if isPC then
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
        if root then
            local dist = (root.Position - DESK_POSITION).Magnitude
            if dist > 24 then
                rebirthResultRemote:FireClient(player, "PcRequired", "⚠️ You must be at your Computer Desk for Gaming or Just Chatting! (Sit at chair or switch to 📱 IRL to stream anywhere!)")
                return
            end
        end
        unequipPhone(player)
        updateMonitorDisplay(true, categoryKey, displayPlatformStr, player)
        player:SetAttribute("IsPCStream", true)
        player:SetAttribute("IsPhoneStream", false)
    else
        equipPhone(player)
        updateMonitorDisplay(false, nil, nil, player)
        player:SetAttribute("IsPCStream", false)
        player:SetAttribute("IsPhoneStream", true)
    end

    isStreaming[player] = true
    activePlatforms[player] = displayPlatformStr
    streamStateChangedRemote:FireClient(player, true, displayPlatformStr)

    player:SetAttribute("ActiveStreamPlatforms", displayPlatformStr)
    player:SetAttribute("IsStreamingYouTube", table.find(validPlatforms, "YouTube") ~= nil)
    player:SetAttribute("IsStreamingTwitch", table.find(validPlatforms, "Twitch") ~= nil)
    player:SetAttribute("IsStreamingTikTok", table.find(validPlatforms, "TikTok") ~= nil)

    if player.Character then
        updateOverhead(player.Character, player)
    end

    -- Серверний цикл нарахування нагород та запуск подій
    local streamThread = task.spawn(function()
        local secondsSinceLastEvent = 0
        local nextEventThreshold = math.random(10, 14)
        local elapsedSeconds = 0

        while isStreaming[player] and player.Parent ~= nil do
            task.wait(StreamConfig.IncomeIntervalSeconds)

            if not isStreaming[player] or player.Parent == nil then break end
            elapsedSeconds += 1

            -- 1. Симуляція виживання: витрата Енергії (Energy Drain)
            local infiniteExp = (player:GetAttribute("InfiniteEnergyExpiry") :: number?) or 0
            local hasInfiniteEnergy = infiniteExp > os.time()

            local maxEnergy = (player:GetAttribute("MaxEnergy") :: number?) or StreamConfig.MaxEnergy
            local currentEnergy = (player:GetAttribute("Energy") :: number?) or maxEnergy

            if hasInfiniteEnergy then
                currentEnergy = maxEnergy
                player:SetAttribute("Energy", maxEnergy)
            elseif elapsedSeconds % StreamConfig.EnergyDrainSeconds == 0 then
                local drain = StreamConfig.EnergyDrainPerSecond or 2
                currentEnergy = math.max(0, currentEnergy - drain)
                player:SetAttribute("Energy", currentEnergy)

                -- Якщо енергія впала до 0 — стрімер втрачає свідомість від втоми
                if currentEnergy <= 0 then
                    stopStream(player)
                    break
                end
            end

            -- Перевірка відстані для ПК-стрімів (Gaming / Just Chatting)
            if isPC then
                local char = player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
                if root then
                    local dist = (root.Position - DESK_POSITION).Magnitude
                    if dist > 30 then
                        stopStream(player)
                        rebirthResultRemote:FireClient(player, "PcLeft", "⚠️ You stepped away from your PC Battlestation! Stream ended.")
                        break
                    end
                end
            end

            local leaderstats = player:FindFirstChild("leaderstats")
            if leaderstats then
                local moneyObj = leaderstats:FindFirstChild("Money") :: IntValue?
                local hypeObj = leaderstats:FindFirstChild("Hype") :: IntValue?

                if moneyObj and hypeObj then
                    local gamesCount = (player:GetAttribute("GamesOwnedCount") :: number?) or 0
                    local gearCount = (player:GetAttribute("GearOwnedCount") :: number?) or 0

                    -- Динамічний старт: дохід та підписники йдуть стабільно та захоплююче!
                    local baseMoney = 0
                    local baseHype = 0

                    if math.random() < StreamConfig.BaseDonationChance then
                        baseMoney = math.random(2, 4)
                    end
                    if math.random() < StreamConfig.BaseSubChance then
                        baseHype = math.random(3, 7)
                    end

                    -- Бонуси від купленого заліза та ігор (CyberByte Tech Store)
                    local equipMoneyBonus = (player:GetAttribute("StreamMoneyBonus") :: number?) or 0
                    local equipHypeBonus = (player:GetAttribute("StreamHypeBonus") :: number?) or 0
                    local audienceCashBonus = math.floor(hypeObj.Value * 0.003)
                    -- Експоненційний ріст аудиторії: чим більше підписників, тим потужніша вірусність!
                    local audienceHypeBonus = math.floor(hypeObj.Value * 0.004)

                    local totalMoney = baseMoney + equipMoneyBonus + audienceCashBonus
                    local totalHype = baseHype + equipHypeBonus + audienceHypeBonus

                    -- Штраф втоми (якщо енергія < 25% — дохід падає на 50%)
                    if currentEnergy < 25 and not hasInfiniteEnergy then
                        totalMoney = math.floor(totalMoney * 0.5)
                        totalHype = math.floor(totalHype * 0.5)
                    end

                    -- Множники платформи (1 платформа або Split 2-Platforms з Robux)
                    totalMoney = math.floor(totalMoney * moneyMult)
                    totalHype = math.floor(totalHype * hypeMult)

                    -- Множники категорії (IRL, Gaming, Just Chatting)
                    totalMoney = math.floor(totalMoney * catInfo.MoneyMultiplier)
                    totalHype = math.floor(totalHype * catInfo.HypeMultiplier)

                    -- PC Gaming: синергія з купленими іграми в Steam (+20% грошей та +15% сабів за кожну гру)
                    if categoryKey == "Gaming" and gamesCount > 0 then
                        totalMoney = math.floor(totalMoney * (1.0 + (gamesCount * 0.20)))
                        totalHype = math.floor(totalHype * (1.0 + (gamesCount * 0.15)))
                    end

                    -- VIP Pass (+50% грошей, +25% сабів)
                    if player:GetAttribute("IsVIP") == true then
                        totalMoney = math.floor(totalMoney * 1.5)
                        totalHype = math.floor(totalHype * 1.25)
                    end

                    -- 2X Viral Stream Boost (Robux DevProduct)
                    local viralBoostExp = (player:GetAttribute("ViralBoostExpiry") :: number?) or 0
                    if viralBoostExp > os.time() then
                        totalHype = math.floor(totalHype * 2.0)
                    end

                    -- Rebirth Multiplier (+50% Cash & Subs per Rebirth level!)
                    local rebirths = (player:GetAttribute("Rebirths") :: number?) or 0
                    if rebirths > 0 then
                        local rebirthMult = 1.0 + (rebirths * StreamConfig.Rebirth.MultiplierPerRebirth)
                        totalMoney = math.floor(totalMoney * rebirthMult)
                        totalHype = math.floor(totalHype * rebirthMult)
                    end

                    -- Щогодинний буст 1.5х
                    local eventFolder = ReplicatedStorage:FindFirstChild("EventState")
                    local isBoostActive = eventFolder and eventFolder:FindFirstChild("IsBoostActive") and (eventFolder.IsBoostActive :: BoolValue).Value
                    if isBoostActive then
                        totalMoney = math.floor(totalMoney * StreamConfig.EventMoneyMultiplier)
                    end

                    moneyObj.Value += totalMoney

                    -- Розподіл підписників по обраних стрім-платформах (YouTube, Twitch, TikTok)
                    local currentYT = (player:GetAttribute("YouTubeSubs") :: number?) or 0
                    local currentTW = (player:GetAttribute("TwitchSubs") :: number?) or 0
                    local currentTT = (player:GetAttribute("TikTokSubs") :: number?) or 0

                    local numPlatforms = #validPlatforms
                    if numPlatforms > 0 then
                        local perPlatformHype = math.max(1, math.floor(totalHype / numPlatforms))
                        for _, pKey in validPlatforms do
                            if pKey == "YouTube" then
                                currentYT += perPlatformHype
                            elseif pKey == "Twitch" then
                                currentTW += perPlatformHype
                            elseif pKey == "TikTok" then
                                currentTT += perPlatformHype
                            end
                        end
                        player:SetAttribute("YouTubeSubs", currentYT)
                        player:SetAttribute("TwitchSubs", currentTW)
                        player:SetAttribute("TikTokSubs", currentTT)
                        hypeObj.Value = currentYT + currentTW + currentTT
                    else
                        hypeObj.Value += totalHype
                    end

                    -- Оновлення рангу стрімера для HUD
                    local rankTitle = "Potato Setup"
                    if gearCount >= 3 and gamesCount >= 2 then
                        rankTitle = "Pro Battlestation"
                    elseif gearCount >= 2 or gamesCount >= 2 then
                        rankTitle = "Rising Streamer"
                    elseif gearCount >= 1 or gamesCount >= 1 then
                        rankTitle = "Budget Creator"
                    end
                    player:SetAttribute("StreamRankTitle", rankTitle)

                    if player.Character then
                        updateOverhead(player.Character, player)
                    end
                end
            end

            -- Таймер випадкових подій під час стріму
            secondsSinceLastEvent += 1
            if secondsSinceLastEvent >= nextEventThreshold then
                secondsSinceLastEvent = 0
                nextEventThreshold = math.random(30, 45)
                task.spawn(triggerRandomStreamEvent, player)
            end
        end
    end)

    activeStreamThreads[player] = streamThread
end

-- Обработка відповіді на динамічну подію
submitChoiceRemote.OnServerEvent:Connect(function(player: Player, eventId: any, choiceId: any)
    local activeEvent = pendingEventByPlayer[player]
    if not activeEvent or activeEvent.Id ~= eventId then return end
    pendingEventByPlayer[player] = nil

    local chosenOption = nil
    for _, ch in activeEvent.Choices do
        if ch.Id == choiceId then
            chosenOption = ch
            break
        end
    end
    if not chosenOption then return end

    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end
    local hypeObj = leaderstats:FindFirstChild("Hype") :: IntValue?
    local moneyObj = leaderstats:FindFirstChild("Money") :: IntValue?
    if not hypeObj or not moneyObj then return end

    local isSuccess = math.random() <= chosenOption.SuccessChance
    local currentHype = hypeObj.Value

    local hypeDelta = 0
    local moneyDelta = 0
    local message = ""

    if isSuccess then
        -- Точна пропорційна формула успіху від кількості підписників:
        -- При 1000 сабів: 1000 * 0.10 = +100
        -- При 50 сабів: 50 * 0.10 = +5
        -- Для початківця: мінімум +5
        hypeDelta = math.max(5, math.round(currentHype * chosenOption.SuccessHypeMultiplier))
        -- 2X Viral Boost multiplier
        if (player:GetAttribute("ViralBoostExpiry") or 0) > os.time() then
            hypeDelta = math.floor(hypeDelta * 2.0)
        end
        -- VIP Multipliers (+25% subs, +50% cash)
        if player:GetAttribute("IsVIP") == true then
            hypeDelta = math.floor(hypeDelta * 1.25)
            moneyDelta = math.floor(chosenOption.MoneyReward * 1.5)
        else
            moneyDelta = chosenOption.MoneyReward
        end
        message = chosenOption.SuccessMessage
    else
        -- Точна формула невдачі:
        -- При 1000 сабів: 1000 * -0.05 = -50
        -- При 50 сабів: 50 * 0.05 = 2.5 -> math.round = 3 (-3 саби)
        -- Для початківця: мінімум -1 або -2
        local rawLoss = math.round(currentHype * math.abs(chosenOption.FailHypeMultiplier))
        hypeDelta = -math.max(1, rawLoss)
        moneyDelta = 0
        message = chosenOption.FailMessage
    end

    -- Apply results
    hypeObj.Value = math.max(0, hypeObj.Value + hypeDelta)
    moneyObj.Value = math.max(0, moneyObj.Value + moneyDelta)

    if player.Character then
        updateOverhead(player.Character, player)
    end

    -- Send result to client
    choiceResultRemote:FireClient(player, {
        Success = isSuccess,
        Message = message,
        HypeDelta = hypeDelta,
        MoneyDelta = moneyDelta,
    })
end)

-- Обробка запиту Start/Stop від клієнта
toggleStreamRemote.OnServerEvent:Connect(function(player: Player, requestedPlatform: any)
    local now = os.clock()
    local lastTime = lastToggleTimestamp[player] or 0
    if (now - lastTime) < TOGGLE_COOLDOWN then
        return
    end
    lastToggleTimestamp[player] = now

    if isStreaming[player] then
        stopStream(player)
    else
        -- Перевіряємо, чи гравець закріпив платформу до ребірсу
        local lockedPlat = player:GetAttribute("LockedPlatform") :: string?
        if not lockedPlat or lockedPlat == "" then
            -- Якщо платформа ще не вибрана — відкриваємо вікно вибору платформи
            promptPlatformSelectRemote:FireClient(player, false)
            return
        end

        startStream(player, lockedPlat)
    end
end)

-- 7. Закріплення платформи до ребірсу (Client -> Server)
lockPlatformRemote.OnServerEvent:Connect(function(player: Player, requestedPlatform: any)
    if typeof(requestedPlatform) ~= "string" then return end

    -- Якщо платформа вже зафіксована для поточного ребірсу — блокуємо зміну
    local existingLock = player:GetAttribute("LockedPlatform")
    if existingLock and existingLock ~= "" then
        rebirthResultRemote:FireClient(player, "PlatformAlreadyLocked", existingLock)
        return
    end

    local validPlatforms, _, _ = parsePlatformSelection(player, requestedPlatform)
    local lockedKey = table.concat(validPlatforms, "+")
    local displayNames = table.concat(validPlatforms, " + ")

    player:SetAttribute("LockedPlatform", lockedKey)
    player:SetAttribute("ActiveStreamPlatforms", displayNames)
    rebirthResultRemote:FireClient(player, "PlatformLocked", displayNames)
end)

-- 11. Вибір категорії стріму (Client -> Server)
setStreamCategoryRemote.OnServerEvent:Connect(function(player: Player, requestedCategory: any)
    if typeof(requestedCategory) == "string" and StreamConfig.Categories[requestedCategory] then
        player:SetAttribute("StreamCategory", requestedCategory)
    end
end)

-- 8. Виконання Ребірсу (Rebirth)
performRebirthRemote.OnServerEvent:Connect(function(player: Player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end

    local hypeObj = leaderstats:FindFirstChild("Hype") :: IntValue?
    local moneyObj = leaderstats:FindFirstChild("Money") :: IntValue?
    local rebirthsObj = leaderstats:FindFirstChild("Rebirths") :: IntValue?
    if not hypeObj or not moneyObj then return end

    local currentRebirths = rebirthsObj and rebirthsObj.Value or ((player:GetAttribute("Rebirths") :: number?) or 0)
    local reqSubs, reqMoney = StreamConfig.GetRebirthRequirements(currentRebirths)

    if hypeObj.Value >= reqSubs and moneyObj.Value >= reqMoney then
        if isStreaming[player] then
            stopStream(player)
        end

        local newRebirths = currentRebirths + 1
        if rebirthsObj then
            rebirthsObj.Value = newRebirths
        end
        player:SetAttribute("Rebirths", newRebirths)

        -- Скидання параметрів поточної кар'єри
        hypeObj.Value = 0
        local starterBonus = newRebirths * StreamConfig.Rebirth.StarterCashBonusPerRebirth
        moneyObj.Value = StreamConfig.StarterMoney + starterBonus

        local maxEnergy = StreamConfig.MaxEnergy + (newRebirths * StreamConfig.Rebirth.MaxEnergyBonusPerRebirth)
        player:SetAttribute("MaxEnergy", maxEnergy)
        player:SetAttribute("Energy", maxEnergy)

        -- РОЗБЛОКУВАННЯ ПЛАТФОРМИ: гравець може вибрати нову платформу для нового життя!
        player:SetAttribute("LockedPlatform", nil)
        player:SetAttribute("ActiveStreamPlatforms", nil)

        if player.Character then
            updateOverhead(player.Character, player)
        end

        -- Оновлюємо 3D кнопки YouTube у студії над сетапом
        updateStudioAwards(player)

        local rewardInfo = (StreamConfig :: any).GetRebirthReward(newRebirths)

        -- Сповіщаємо клієнта та відкриваємо вікно вибору нової платформи
        rebirthResultRemote:FireClient(player, "RebirthSuccess", newRebirths, rewardInfo)
        promptPlatformSelectRemote:FireClient(player, true)

        local broadcastChat = remotesFolder:FindFirstChild("BroadcastSuperChat") :: RemoteEvent?
        if broadcastChat then
            broadcastChat:FireAllClients(player.DisplayName, 0, `🎉 Стрімер {player.DisplayName} розблокував {rewardInfo.ButtonIcon} {rewardInfo.ButtonNameUA} ({rewardInfo.MilestoneText})!`)
        end
    else
        rebirthResultRemote:FireClient(player, "RebirthFailed", `Requires {reqSubs} Subs and ${reqMoney} Cash!`)
    end
end)

--------------------------------------------------------------------------------
-- Обробка назви каналу
--------------------------------------------------------------------------------
setChannelNameRemote.OnServerEvent:Connect(function(player: Player, requestedName: any)
    if typeof(requestedName) ~= "string" then return end
    local cleanedName = string.gsub(requestedName, "^%s*(.-)%s*$", "%1")

    if #cleanedName < StreamConfig.MinChannelNameLength or #cleanedName > StreamConfig.MaxChannelNameLength then
        return
    end

    local filteredName = cleanedName
    local success, result = pcall(function()
        local filterResult = TextService:FilterStringAsync(cleanedName, player.UserId)
        return filterResult:GetNonChatStringForBroadcastAsync()
    end)
    if success and result and #result > 0 then
        filteredName = result
    end

    player:SetAttribute("ChannelName", filteredName)
    if player.Character then
        updateOverhead(player.Character, player)
        if isStreaming[player] then
            equipPhone(player)
        end
    end
    updateStudioAwards(player)
end)

local function onPlayerAdded(player: Player)
    if not player:GetAttribute("ChannelName") then
        player:SetAttribute("ChannelName", player.DisplayName .. " TV")
    end

    player.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        if char.Parent ~= nil then
            updateOverhead(char, player)
            updateStudioAwards(player)
            if isStreaming[player] then
                equipPhone(player)
            end
        end
    end)

    task.delay(1.5, function()
        if player.Parent ~= nil then
            updateStudioAwards(player)
        end
    end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in Players:GetPlayers() do
    task.spawn(onPlayerAdded, p)
end

Players.PlayerRemoving:Connect(function(player: Player)
    unequipPhone(player)
    isStreaming[player] = nil
    activePlatforms[player] = nil
    lastToggleTimestamp[player] = nil
    activeStreamThreads[player] = nil
    pendingEventByPlayer[player] = nil
end)

--------------------------------------------------------------------------------
-- 7. Gaming Chair & Desk Setup with ProximityPrompt
--------------------------------------------------------------------------------
task.spawn(function()
    local cityWorld = workspace:WaitForChild("CityWorld", 10) :: Model?
    local chairSeat = (cityWorld and cityWorld:FindFirstChild("GamingChairSeat", true)) or workspace:FindFirstChild("GamingChairSeat", true) :: Seat?
    if not chairSeat then return end

    local sitPrompt = chairSeat:FindFirstChild("SitPrompt") :: ProximityPrompt?
    if not sitPrompt then
        sitPrompt = Instance.new("ProximityPrompt")
        sitPrompt.Name = "SitPrompt"
        sitPrompt.ObjectText = "Streaming Battlestation"
        sitPrompt.ActionText = "Sit & Stream (E)"
        sitPrompt.HoldDuration = 0
        sitPrompt.MaxActivationDistance = 10
        sitPrompt.KeyboardKeyCode = Enum.KeyCode.E
        sitPrompt.RequiresLineOfSight = false
        sitPrompt.Parent = chairSeat
    end

    sitPrompt.Triggered:Connect(function(player: Player)
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid and chairSeat.Occupant == nil then
                chairSeat:Sit(humanoid)
            end
        end
    end)

    chairSeat:GetPropertyChangedSignal("Occupant"):Connect(function()
        sitPrompt.Enabled = (chairSeat.Occupant == nil)
    end)
end)

--------------------------------------------------------------------------------
-- Пасивне відновлення сил під час відпочинку (поза стрімом)
--------------------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(StreamConfig.EnergyRestRecoverySeconds or 2)
        for _, player in Players:GetPlayers() do
            if not isStreaming[player] and player.Parent ~= nil then
                local maxEnergy = (player:GetAttribute("MaxEnergy") :: number?) or StreamConfig.MaxEnergy
                local currentEnergy = (player:GetAttribute("Energy") :: number?) or maxEnergy
                if currentEnergy < maxEnergy then
                    local restored = math.min(maxEnergy, currentEnergy + 3)
                    player:SetAttribute("Energy", restored)
                end
            end
        end
    end
end)

