--!strict
-- Керує "творчою економікою" гравця: підписники (Followers) та гроші (Money),
-- які прибувають після запису відео в застосунку ClipZap на телефоні.
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
