--!strict
-- Керує "творчою економікою" гравця: підписники (Followers) та гроші (Money)
-- у leaderstats, плюс ChannelStats (TotalLikes, VideoCount) для профілю
-- каналу на телефоні — усе це прибуває після запису відео в ClipZap.
-- Сервер — єдине джерело правди для випадкових чисел (лайки/підписники за
-- відео) і для кулдауну, щоб клієнт нічого не міг підробити чи проспамити.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PhoneConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PhoneConfig"))
local Economy = PhoneConfig.Economy

-- Remotes створюються тут же в рантаймі (не потрібно запікати їх в XML мапи) —
-- клієнтський PhoneController.client.luau просто чекає на них через WaitForChild.
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local recordVideoRequest = Instance.new("RemoteEvent")
recordVideoRequest.Name = "RecordVideoRequest"
recordVideoRequest.Parent = remotes

local recordVideoResult = Instance.new("RemoteEvent")
recordVideoResult.Name = "RecordVideoResult"
recordVideoResult.Parent = remotes

-- userId -> момент часу (os.clock()), коли гравцю знову можна записувати відео
local nextRecordAllowedAt: { [number]: number } = {}

Players.PlayerAdded:Connect(function(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	-- Illia попросив: гравець "прокидається бідняком" — стартові 0 підписників, 0$.
	local followers = Instance.new("IntValue")
	followers.Name = "Followers"
	followers.Value = 0
	followers.Parent = leaderstats

	local money = Instance.new("IntValue")
	money.Name = "Money"
	money.Value = 0
	money.Parent = leaderstats

	-- Окрема папка (НЕ leaderstats) для профілю каналу на телефоні — щоб не
	-- додавати зайві колонки в стандартний Roblox-лідерборд. Ці значення
	-- показуються в шапці ClipZap (❤️ лайки, 👥 підписники, 🎬 відео).
	local channelStats = Instance.new("Folder")
	channelStats.Name = "ChannelStats"
	channelStats.Parent = player

	local totalLikes = Instance.new("IntValue")
	totalLikes.Name = "TotalLikes"
	totalLikes.Value = 0
	totalLikes.Parent = channelStats

	local videoCount = Instance.new("IntValue")
	videoCount.Name = "VideoCount"
	videoCount.Value = 0
	videoCount.Parent = channelStats
end)

Players.PlayerRemoving:Connect(function(player: Player)
	nextRecordAllowedAt[player.UserId] = nil
end)

recordVideoRequest.OnServerEvent:Connect(function(player: Player)
	local now = os.clock()
	local readyAt = nextRecordAllowedAt[player.UserId] or 0
	if now < readyAt then
		-- Ще на кулдауні (або клієнт намагається спамити) — тихо відмовляємо.
		recordVideoResult:FireClient(player, { Success = false })
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end
	local followers = leaderstats:FindFirstChild("Followers") :: IntValue?
	local money = leaderstats:FindFirstChild("Money") :: IntValue?
	if not followers or not money then
		return
	end

	local likes = math.random(Economy.MinLikesPerVideo, Economy.MaxLikesPerVideo)
	local gainedFollowers = math.random(Economy.MinFollowersPerVideo, Economy.MaxFollowersPerVideo)
	local gainedMoney = math.floor(likes / Economy.LikesPerDollar)

	followers.Value += gainedFollowers
	money.Value += gainedMoney

	local channelStats = player:FindFirstChild("ChannelStats")
	if channelStats then
		local totalLikes = channelStats:FindFirstChild("TotalLikes") :: IntValue?
		local videoCount = channelStats:FindFirstChild("VideoCount") :: IntValue?
		if totalLikes then
			totalLikes.Value += likes
		end
		if videoCount then
			videoCount.Value += 1
		end
	end

	-- Кулдаун рахуємо від моменту публікації, а не запиту — щоб врахувати і
	-- саму "зйомку" на клієнті, і паузу між відео.
	nextRecordAllowedAt[player.UserId] = now + Economy.RecordSeconds + Economy.CooldownSeconds

	recordVideoResult:FireClient(player, {
		Success = true,
		Likes = likes,
		Followers = gainedFollowers,
		Money = gainedMoney,
	})
end)
