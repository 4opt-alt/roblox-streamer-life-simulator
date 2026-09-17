--!strict
local Players = game:GetService("Players")

local function setupLeaderstats(player: Player)
    -- Якщо leaderstats вже існує, не дублюємо
    if player:FindFirstChild("leaderstats") then
        return
    end

    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local StreamConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("StreamConfig") :: ModuleScript)

    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"

    -- Змінна Money (Гроші) - $15 на старті для виживання
    local money = Instance.new("IntValue")
    money.Name = "Money"
    money.Value = StreamConfig.StarterMoney
    money.Parent = leaderstats

    -- Змінна Hype (Підписники / Хайп)
    local hype = Instance.new("IntValue")
    hype.Name = "Hype"
    hype.Value = 0 -- Стартовий хайп
    hype.Parent = leaderstats

    -- Змінна Rebirths (Рівень Ребірсу)
    local rebirths = Instance.new("IntValue")
    rebirths.Name = "Rebirths"
    rebirths.Value = 0
    rebirths.Parent = leaderstats

    leaderstats.Parent = player

    -- Окремі лічильники підписників для кожної платформи
    local yt = (player:GetAttribute("YouTubeSubs") :: number?) or 0
    local tw = (player:GetAttribute("TwitchSubs") :: number?) or 0
    local tt = (player:GetAttribute("TikTokSubs") :: number?) or 0
    if yt == 0 and tw == 0 and tt == 0 and hype.Value > 0 then
        yt = hype.Value
    end
    player:SetAttribute("YouTubeSubs", yt)
    player:SetAttribute("TwitchSubs", tw)
    player:SetAttribute("TikTokSubs", tt)
end

-- Обробка нових гравців
Players.PlayerAdded:Connect(setupLeaderstats)

-- Для гравців, які вже підключилися (актуально під час тестування в Studio)
for _, player in Players:GetPlayers() do
    task.spawn(setupLeaderstats, player)
end
