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
        if cLabel then
            if isVIP then
                cLabel.Text = `👑 [VIP] {channelName}`
                cLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
            else
                cLabel.Text = `📺 {channelName}`
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
-- Зупинка та запуск стріму з вибором платформи
--------------------------------------------------------------------------------
local function stopStream(player: Player)
    isStreaming[player] = false
    activeStreamThreads[player] = nil
    pendingEventByPlayer[player] = nil

    unequipPhone(player)

    player:SetAttribute("ActiveStreamPlatforms", "")
    player:SetAttribute("IsStreamingYouTube", false)
    player:SetAttribute("IsStreamingTwitch", false)
    player:SetAttribute("IsStreamingTikTok", false)

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

    isStreaming[player] = true
    activePlatforms[player] = displayPlatformStr
    streamStateChangedRemote:FireClient(player, true, displayPlatformStr)

    player:SetAttribute("ActiveStreamPlatforms", displayPlatformStr)
    player:SetAttribute("IsStreamingYouTube", table.find(validPlatforms, "YouTube") ~= nil)
    player:SetAttribute("IsStreamingTwitch", table.find(validPlatforms, "Twitch") ~= nil)
    player:SetAttribute("IsStreamingTikTok", table.find(validPlatforms, "TikTok") ~= nil)

    equipPhone(player)
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

            local currentEnergy = (player:GetAttribute("Energy") :: number?) or 100
            if hasInfiniteEnergy then
                currentEnergy = 100
                player:SetAttribute("Energy", 100)
            elseif elapsedSeconds % StreamConfig.EnergyDrainSeconds == 0 then
                currentEnergy = math.max(0, currentEnergy - 1)
                player:SetAttribute("Energy", currentEnergy)

                -- Якщо енергія впала до 0 — стрімер втрачає свідомість від втоми
                if currentEnergy <= 0 then
                    stopStream(player)
                    break
                end
            end

            local leaderstats = player:FindFirstChild("leaderstats")
            if leaderstats then
                local moneyObj = leaderstats:FindFirstChild("Money") :: IntValue?
                local hypeObj = leaderstats:FindFirstChild("Hype") :: IntValue?

                if moneyObj and hypeObj then
                    local gamesCount = (player:GetAttribute("GamesOwnedCount") :: number?) or 0
                    local gearCount = (player:GetAttribute("GearOwnedCount") :: number?) or 0

                    -- Реалістичний старт: без ігор та заліза гроші і підписники йдуть дуже повільно!
                    local baseMoney = 0
                    local baseHype = 0

                    if math.random() < StreamConfig.BaseDonationChance then
                        baseMoney = 1
                    end
                    if math.random() < StreamConfig.BaseSubChance then
                        baseHype = 1
                    end

                    -- Бонуси від купленого заліза та ігор (CyberByte Tech Store)
                    local equipMoneyBonus = (player:GetAttribute("StreamMoneyBonus") :: number?) or 0
                    local equipHypeBonus = (player:GetAttribute("StreamHypeBonus") :: number?) or 0
                    local audienceBonus = math.floor(hypeObj.Value * 0.003) -- Дуже плавний приріст від постійної аудиторії (0.3%)

                    local totalMoney = baseMoney + equipMoneyBonus + audienceBonus
                    local totalHype = baseHype + equipHypeBonus

                    -- Штраф втоми (якщо енергія < 25% — дохід падає на 50%)
                    if currentEnergy < 25 and not hasInfiniteEnergy then
                        totalMoney = math.floor(totalMoney * 0.5)
                        totalHype = math.floor(totalHype * 0.5)
                    end

                    -- Множники платформи (1 платформа або Split 2-Platforms з Robux)
                    totalMoney = math.floor(totalMoney * moneyMult)
                    totalHype = math.floor(totalHype * hypeMult)

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

                    -- Щогодинний буст 1.5х
                    local eventFolder = ReplicatedStorage:FindFirstChild("EventState")
                    local isBoostActive = eventFolder and eventFolder:FindFirstChild("IsBoostActive") and (eventFolder.IsBoostActive :: BoolValue).Value
                    if isBoostActive then
                        totalMoney = math.floor(totalMoney * StreamConfig.EventMoneyMultiplier)
                    end

                    moneyObj.Value += totalMoney
                    hypeObj.Value += totalHype

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
        local platKey = if typeof(requestedPlatform) == "string" and StreamConfig.Platforms[requestedPlatform]
            then requestedPlatform
            else "YouTube"
        startStream(player, platKey)
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
end)

local function onPlayerAdded(player: Player)
    if not player:GetAttribute("ChannelName") then
        player:SetAttribute("ChannelName", player.DisplayName .. " TV")
    end

    player.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        if char.Parent ~= nil then
            updateOverhead(char, player)
            if isStreaming[player] then
                equipPhone(player)
            end
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

