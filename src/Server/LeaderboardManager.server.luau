--!strict
local Players = game:GetService("Players")

local surfaceGui: SurfaceGui? = nil
local container: ScrollingFrame? = nil

-- Функція гарантованого створення / налаштування SurfaceGui на табло
local function ensureSurfaceGui(): boolean
    if surfaceGui and container and surfaceGui.Parent then
        return true
    end

    local streamerCorner = workspace:WaitForChild("StreamerCorner", 10)
    if not streamerCorner then return false end

    local board = streamerCorner:WaitForChild("LeaderboardBoard", 10)
    if not board then return false end

    local display = board:WaitForChild("Display", 10) :: BasePart?
    if not display then return false end

    -- Очищаємо старі SurfaceGui якщо були з неправильною стороною
    for _, child in display:GetChildren() do
        if child:IsA("SurfaceGui") then
            child:Destroy()
        end
    end

    -- Створюємо новий ідеальний SurfaceGui на лицьовій стороні (Front = 5)
    local sg = Instance.new("SurfaceGui")
    sg.Name = "LeaderboardGui"
    sg.Face = Enum.NormalId.Front -- Лицьова сторона, повернена до гравця!
    sg.CanvasSize = Vector2.new(800, 560)
    sg.LightInfluence = 0 -- Яскраве світіння екрана навіть уночі!
    sg.AlwaysOnTop = false
    sg.Parent = display

    -- Заголовок табло
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 70)
    header.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
    header.BorderSizePixel = 0
    header.Parent = sg

    local headerStroke = Instance.new("UIStroke")
    headerStroke.Color = Color3.fromRGB(255, 215, 0)
    headerStroke.Thickness = 2
    headerStroke.Parent = header

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.6, 0)
    title.Position = UDim2.new(0, 0, 0.05, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 26
    title.TextColor3 = Color3.fromRGB(255, 215, 0)
    title.Text = "🏆 TOP STREAMERS | WALL OF FAME"
    title.Parent = header

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, 0, 0.35, 0)
    subtitle.Position = UDim2.new(0, 0, 0.6, 0)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = Enum.Font.GothamMedium
    subtitle.TextSize = 14
    subtitle.TextColor3 = Color3.fromRGB(180, 190, 210)
    subtitle.Text = "⭐ Top Stream Channels Ranked by Subscribers"
    subtitle.Parent = header

    -- Контейнер для списку стрімерів
    local sc = Instance.new("ScrollingFrame")
    sc.Name = "ScrollContainer"
    sc.Size = UDim2.new(1, -20, 1, -85)
    sc.Position = UDim2.new(0, 10, 0, 80)
    sc.BackgroundTransparency = 1
    sc.BorderSizePixel = 0
    sc.ScrollBarThickness = 6
    sc.ScrollBarImageColor3 = Color3.fromRGB(255, 215, 0)
    sc.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sc.Parent = sg

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.Parent = sc

    surfaceGui = sg
    container = sc
    return true
end

-- Головна функція оновлення табло
local function updateLeaderboard()
    if not ensureSurfaceGui() or not container then
        return
    end

    -- Збираємо всіх гравців
    local playerList: { { Player: Player, Hype: number, Channel: string } } = {}
    for _, player in Players:GetPlayers() do
        local leaderstats = player:FindFirstChild("leaderstats")
        local hypeVal = leaderstats and leaderstats:FindFirstChild("Hype") :: IntValue?
        local hype = hypeVal and hypeVal.Value or 0
        local channel = player:GetAttribute("ChannelName") or (player.DisplayName .. " TV")

        table.insert(playerList, {
            Player = player,
            Hype = hype,
            Channel = tostring(channel),
        })
    end

    -- Сортуємо за Hype спаданням
    table.sort(playerList, function(a, b)
        return a.Hype > b.Hype
    end)

    -- Очищаємо старі рядки
    for _, child in container:GetChildren() do
        if child:IsA("Frame") and child.Name:sub(1, 4) == "Row_" then
            child:Destroy()
        end
    end

    local medals = { "🥇", "🥈", "🥉" }

    -- Створюємо рядки (до 10 гравців)
    for rank = 1, math.min(#playerList, 10) do
        local data = playerList[rank]
        local row = Instance.new("Frame")
        row.Name = `Row_{rank}`
        row.LayoutOrder = rank
        row.Size = UDim2.new(1, -8, 0, 56)
        row.BackgroundColor3 = if rank == 1 then Color3.fromRGB(48, 42, 22)
            elseif rank == 2 then Color3.fromRGB(38, 40, 48)
            elseif rank == 3 then Color3.fromRGB(44, 34, 26)
            else Color3.fromRGB(24, 27, 36)
        row.BorderSizePixel = 0
        row.Parent = container

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = row

        local stroke = Instance.new("UIStroke")
        stroke.Color = if rank == 1 then Color3.fromRGB(255, 215, 0)
            elseif rank == 2 then Color3.fromRGB(200, 205, 215)
            elseif rank == 3 then Color3.fromRGB(215, 135, 60)
            else Color3.fromRGB(60, 65, 80)
        stroke.Thickness = if rank <= 3 then 2 else 1
        stroke.Parent = row

        -- Номер / Медаль
        local rankLabel = Instance.new("TextLabel")
        rankLabel.Size = UDim2.new(0, 55, 1, 0)
        rankLabel.BackgroundTransparency = 1
        rankLabel.Font = Enum.Font.GothamBold
        rankLabel.TextSize = 24
        rankLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        rankLabel.Text = if rank <= 3 then medals[rank] else `#{rank}`
        rankLabel.Parent = row

        -- Аватарка гравця
        local avatarImg = Instance.new("ImageLabel")
        avatarImg.Size = UDim2.new(0, 44, 0, 44)
        avatarImg.Position = UDim2.new(0, 60, 0.5, -22)
        avatarImg.BackgroundColor3 = Color3.fromRGB(30, 32, 40)
        avatarImg.Image = `rbxthumb://type=AvatarHeadShot&id={data.Player.UserId}&w=100&h=100`
        avatarImg.Parent = row

        local avatarCorner = Instance.new("UICorner")
        avatarCorner.CornerRadius = UDim.new(1, 0)
        avatarCorner.Parent = avatarImg

        -- НАЗВА КАНАЛУ (Великий золотистий / білий акцент)
        local channelLabel = Instance.new("TextLabel")
        channelLabel.Size = UDim2.new(1, -290, 0, 28)
        channelLabel.Position = UDim2.new(0, 115, 0, 4)
        channelLabel.BackgroundTransparency = 1
        channelLabel.Font = Enum.Font.GothamBold
        channelLabel.TextSize = 18
        channelLabel.TextColor3 = if rank == 1 then Color3.fromRGB(255, 220, 80) else Color3.fromRGB(255, 255, 255)
        channelLabel.TextXAlignment = Enum.TextXAlignment.Left
        channelLabel.Text = `📺 {data.Channel}`
        channelLabel.TextTruncate = Enum.TextTruncate.AtEnd
        channelLabel.Parent = row

        -- Streamer username
        local authorLabel = Instance.new("TextLabel")
        authorLabel.Size = UDim2.new(1, -290, 0, 20)
        authorLabel.Position = UDim2.new(0, 115, 0, 30)
        authorLabel.BackgroundTransparency = 1
        authorLabel.Font = Enum.Font.Gotham
        authorLabel.TextSize = 13
        authorLabel.TextColor3 = Color3.fromRGB(160, 165, 180)
        authorLabel.TextXAlignment = Enum.TextXAlignment.Left
        authorLabel.Text = `Streamer: @{data.Player.DisplayName}`
        authorLabel.Parent = row

        -- Кількість підписників (Hype)
        local hypeLabel = Instance.new("TextLabel")
        hypeLabel.Size = UDim2.new(0, 160, 1, 0)
        hypeLabel.Position = UDim2.new(1, -170, 0, 0)
        hypeLabel.BackgroundTransparency = 1
        hypeLabel.Font = Enum.Font.GothamBold
        hypeLabel.TextSize = 18
        hypeLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
        hypeLabel.TextXAlignment = Enum.TextXAlignment.Right
        hypeLabel.Text = `⭐ {data.Hype} Subs`
        hypeLabel.Parent = row
    end
end

-- Підключення слухачів для МИТТЄВОГО оновлення при зміні назви каналу чи хайпу
local function bindPlayer(player: Player)
    -- Оновлення при зміні атрибуту ChannelName
    player:GetAttributeChangedSignal("ChannelName"):Connect(function()
        updateLeaderboard()
    end)

    -- Оновлення при зміні Hype
    local leaderstats = player:WaitForChild("leaderstats", 10)
    if leaderstats then
        local hypeObj = leaderstats:WaitForChild("Hype", 10)
        if hypeObj then
            hypeObj.Changed:Connect(function()
                updateLeaderboard()
            end)
        end
    end

    updateLeaderboard()
end

Players.PlayerAdded:Connect(bindPlayer)
for _, p in Players:GetPlayers() do
    task.spawn(bindPlayer, p)
end

Players.PlayerRemoving:Connect(function()
    task.wait(0.2)
    updateLeaderboard()
end)

-- Регулярне фонове оновлення
task.spawn(function()
    task.wait(2)
    updateLeaderboard()
    while true do
        task.wait(3)
        pcall(updateLeaderboard)
    end
end)
