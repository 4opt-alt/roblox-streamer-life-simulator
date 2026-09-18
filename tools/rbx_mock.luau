-- Мінімальний мок Roblox API, щоб реально ВИКОНАТИ PhoneController.client.luau
-- поза Roblox Studio і побачити справжню runtime-помилку (не тільки синтаксис).

-- ПРИМІТКА: coroutine.isyieldable() тут НЕ підходить для розрізнення
-- "головного потоку" від task.spawn-корутин, бо сам luau CLI, схоже,
-- виконує весь скрипт уже всередині якоїсь резюмованої корутини (isyieldable
-- повертає true навіть на "верхньому рівні"). Тому порівнюємо сам об'єкт
-- потоку з зафіксованим на старті "кореневим" — так рядки, викликані прямо
-- з драйвера (через :Fire()), НЕ намагаються yield'ити (і не падають з
-- "thread yielded unexpectedly"), а фонові task.spawn-цикли — таки yield'ять.
local ROOT_THREAD = coroutine.running()

local EVENT_NAMES = {
	Changed = true,
	MouseButton1Click = true,
	MouseButton1Down = true,
	MouseButton1Up = true,
	Completed = true,
	OnServerEvent = true,
	OnClientEvent = true,
	RenderStepped = true,
	Heartbeat = true,
	InputBegan = true,
	PlayerAdded = true,
	PlayerRemoving = true,
	FocusLost = true,
}

local function newSignal(tag)
	local listeners = {}
	local signal = {}
	signal._tag = tag
	signal.Connect = function(_, fn)
		table.insert(listeners, fn)
		local conn = {}
		conn.Disconnect = function() end
		return conn
	end
	signal.Wait = function(_)
		-- Деякі цикли (наприклад пульсація REC-крапки) НЕ мають task.wait,
		-- а покладаються лише на tween.Completed:Wait() для темпу — у
		-- справжньому Roblox це займає реальний час, тут же треба хоч раз
		-- "відпустити" корутину, інакше такий while-цикл ніколи не вийде й
		-- зависне тестовий раннер. На головному потоці (не корутина) просто
		-- повертаємось одразу, бо там yield неможливий.
		if coroutine.running() ~= ROOT_THREAD then
			coroutine.yield()
		end
		return
	end
	signal.Fire = function(_, ...)
		local snapshot = {}
		for i, fn in listeners do
			snapshot[i] = fn
		end
		for _, fn in snapshot do
			fn(...)
		end
	end
	return signal
end

-- ВАЖЛИВО: у звичайній Lua/Luau __newindex і __index СПРАЦЬОВУЮТЬ лише для
-- ключів, яких ЩЕ немає як "сирого" (raw) поля в таблиці — щойно ключ хоч
-- раз потрапив у таблицю через rawset, ВСІ подальші читання/записи того ж
-- ключа йдуть напряму, повз метаметоди. Через це перша версія цього мока
-- (яка робила rawset(t, key, value) прямо на видиму таблицю інстанса)
-- ловила подію "Changed" рівно ОДИН раз (при першому .Value = 0), а всі
-- наступні зміни .Value — вже НІКОЛИ не доходили до __newindex і тому
-- Changed більше не фаєрився. Це коштувало кількох годин налагодження.
-- Фікс: властивості інстанса НІКОЛИ не стають "сирими" полями видимої
-- таблиці — вони завжди живуть в окремій прихованій "_props" таблиці, тож
-- __index/__newindex спрацьовують АБСОЛЮТНО щоразу, без винятків.
local InstanceMeta = {}

InstanceMeta.__index = function(t, key)
	local props = rawget(t, "_props")
	local existing = props[key]
	if existing ~= nil then
		return existing
	end
	if EVENT_NAMES[key] then
		local tag = tostring(props.Name) .. "." .. tostring(key)
		local sig = newSignal(tag)
		props[key] = sig
		return sig
	end
	return nil
end

InstanceMeta.__newindex = function(t, key, value)
	local props = rawget(t, "_props")
	if key == "Parent" then
		local old = props.Parent
		if old then
			local oldChildren = rawget(old, "_children")
			if oldChildren then
				for i, child in oldChildren do
					if child == t then
						table.remove(oldChildren, i)
						break
					end
				end
			end
		end
		props.Parent = value
		if value ~= nil then
			local children = rawget(value, "_children")
			table.insert(children, t)
		end
		return
	end
	props[key] = value
	if key == "Value" then
		local changed = props.Changed
		if changed then
			changed:Fire(value)
		end
	end
end

local function attachCommonMethods(inst)
	inst.WaitForChild = function(self, name)
		for _, child in rawget(self, "_children") do
			if child.Name == name then
				return child
			end
		end
		error("MOCK WaitForChild timeout: '" .. tostring(name) .. "' not found under " .. tostring(self.Name))
	end
	inst.FindFirstChild = function(self, name)
		for _, child in rawget(self, "_children") do
			if child.Name == name then
				return child
			end
		end
		return nil
	end
	inst.FindFirstChildOfClass = function(self, className)
		for _, child in rawget(self, "_children") do
			if rawget(child, "_className") == className then
				return child
			end
		end
		return nil
	end
	inst.GetChildren = function(self)
		local copy = {}
		for i, c in rawget(self, "_children") do
			copy[i] = c
		end
		return copy
	end
	inst.IsA = function(self, className)
		return rawget(self, "_className") == className
	end
	inst.Destroy = function(self)
		self.Parent = nil
	end
end

local function newInst(className, name)
	local inst = setmetatable({}, InstanceMeta)
	rawset(inst, "_className", className)
	rawset(inst, "_children", {})
	rawset(inst, "_props", { Name = name or className })
	attachCommonMethods(inst)
	return inst
end

__allInstancesByName = {}
Instance = {}
Instance.new = function(className)
	local inst = newInst(className)
	__allInstancesByName[className] = __allInstancesByName[className] or {}
	table.insert(__allInstancesByName[className], inst)
	return inst
end

-- Enum: будь-яка глибина, мемоізований проксі, стабільна рівність
local function makeEnumProxy(path)
	local cache = {}
	local proxy = newproxy and nil or nil
	local t = {}
	local mt = {}
	mt.__index = function(_, key)
		if cache[key] == nil then
			cache[key] = makeEnumProxy(path .. "." .. tostring(key))
		end
		return cache[key]
	end
	mt.__tostring = function()
		return path
	end
	return setmetatable(t, mt)
end
Enum = makeEnumProxy("Enum")

UDim2 = { new = function(...) return { "UDim2", ... } end }
UDim = { new = function(...) return { "UDim", ... } end }
Vector2 = { new = function(...) return { "Vector2", ... } end }
local Vector3Meta = {}
Vector3Meta.__add = function(a, b)
	return setmetatable({ X = (a.X or 0) + (b.X or 0), Y = (a.Y or 0) + (b.Y or 0), Z = (a.Z or 0) + (b.Z or 0) }, Vector3Meta)
end
Vector3Meta.__sub = function(a, b)
	return setmetatable({ X = (a.X or 0) - (b.X or 0), Y = (a.Y or 0) - (b.Y or 0), Z = (a.Z or 0) - (b.Z or 0) }, Vector3Meta)
end
Vector3Meta.__mul = function(a, b)
	if type(b) == "number" then
		return setmetatable({ X = (a.X or 0) * b, Y = (a.Y or 0) * b, Z = (a.Z or 0) * b }, Vector3Meta)
	end
	return setmetatable({ X = 0, Y = 0, Z = 0 }, Vector3Meta)
end
Vector3 = {
	new = function(x, y, z)
		return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, Vector3Meta)
	end,
}
Color3 = {
	new = function(...) return { "Color3", ... } end,
	fromRGB = function(...) return { "Color3", ... } end,
}
local CFrameMeta = {}
CFrameMeta.__mul = function(a, b)
	return setmetatable({ LookVector = Vector3.new(0, 0, -1) }, CFrameMeta)
end
CFrame = {
	new = function(...) return setmetatable({ LookVector = Vector3.new(0, 0, -1) }, CFrameMeta) end,
	lookAt = function(...) return setmetatable({ LookVector = Vector3.new(0, 0, -1) }, CFrameMeta) end,
}
TweenInfo = { new = function(...) return { "TweenInfo", ... } end }

TweenService = {}
TweenService.Create = function(_, instance, tweenInfo, props)
	local tween = {}
	tween.Completed = newSignal()
	tween.Play = function(self)
		if props then
			for k, v in props do
				instance[k] = v
			end
		end
		self.Completed:Fire()
	end
	return tween
end

RunService = {
	RenderStepped = newSignal(),
	Heartbeat = newSignal(),
	IsClient = function() return true end,
	IsServer = function() return false end,
}

UserInputService = {
	InputBegan = newSignal(),
	InputEnded = newSignal(),
}

task = {
	spawn = function(fn)
		local co = coroutine.create(fn)
		local ok, err = coroutine.resume(co)
		if not ok then
			print("!!! task.spawn coroutine ERROR: " .. tostring(err))
		end
	end,
	wait = function(t)
		coroutine.yield()
	end,
	delay = function(t, fn)
		-- викликаємо синхронно одразу, нам достатньо щоб не впало
	end,
}

local __nativeClock = os and os.clock or function() return 0 end
os = { clock = __nativeClock }

-- ===================== Гравець / сервіси =====================
local LocalPlayer = newInst("Player", "TestPlayer")
LocalPlayer.UserId = 1
-- Мінімальний фейковий персонаж, щоб перевірити startRecordingCamera /
-- WalkSpeed-логіку теж, а не лише UI.
local fakeCharacter = newInst("Model", "TestCharacter")
local fakeHumanoid = newInst("Humanoid", "Humanoid")
fakeHumanoid.WalkSpeed = 16
fakeHumanoid.PlayEmote = function(self, name)
	local track = newInst("AnimationTrack", "Track_" .. name)
	track.Looped = false
	track.Stop = function() end
	return track, name
end
fakeHumanoid.Parent = fakeCharacter
local fakeHead = newInst("Part", "Head")
fakeHead.Position = Vector3.new(0, 5, 0)
fakeHead.Parent = fakeCharacter
local fakeHRP = newInst("Part", "HumanoidRootPart")
fakeHRP.Position = Vector3.new(0, 4, 0)
fakeHRP.CFrame = CFrame.new()
fakeHRP.Parent = fakeCharacter
LocalPlayer.Character = fakeCharacter
LocalPlayer.GetUserThumbnailAsync = function(self, userId, thumbType, thumbSize)
	return "rbxthumb://mock", true
end

local playerGui = newInst("PlayerGui", "PlayerGui")
playerGui.Parent = LocalPlayer

local leaderstats = newInst("Folder", "leaderstats")
leaderstats.Parent = LocalPlayer
local followers = newInst("IntValue", "Followers")
followers.Value = 0
followers.Parent = leaderstats
local money = newInst("IntValue", "Money")
money.Value = 0
money.Parent = leaderstats

local channelStats = newInst("Folder", "ChannelStats")
channelStats.Parent = LocalPlayer
local totalLikes = newInst("IntValue", "TotalLikes")
totalLikes.Value = 0
totalLikes.Parent = channelStats
local videoCount = newInst("IntValue", "VideoCount")
videoCount.Value = 0
videoCount.Parent = channelStats

Players = {
	LocalPlayer = LocalPlayer,
	PlayerAdded = newSignal(),
	PlayerRemoving = newSignal(),
	GetUserThumbnailAsync = function(self, userId, thumbType, thumbSize)
		return "rbxthumb://mock", true
	end,
}

-- ReplicatedStorage: Shared/PhoneConfig + Remotes/RecordVideoRequest/Result
ReplicatedStorage = newInst("ReplicatedStorage", "ReplicatedStorage")
local sharedFolder = newInst("Folder", "Shared")
sharedFolder.Parent = ReplicatedStorage

local phoneConfigModule = newInst("ModuleScript", "PhoneConfig")
phoneConfigModule.Parent = sharedFolder
__phoneConfigModuleInstance = phoneConfigModule

local remotesFolder = newInst("Folder", "Remotes")
remotesFolder.Parent = ReplicatedStorage
local recordVideoRequest = newInst("RemoteEvent", "RecordVideoRequest")
recordVideoRequest.FireServer = function(self, ...) end
recordVideoRequest.Parent = remotesFolder
local recordVideoResult = newInst("RemoteEvent", "RecordVideoResult")
recordVideoResult.FireClient = function(self, ...) end
recordVideoResult.Parent = remotesFolder

workspace = { CurrentCamera = newInst("Camera", "Camera") }

-- ПРИМІТКА: io.open недоступний у пісочниці luau CLI, тому вміст PhoneConfig
-- вставляється ЗАЗДАЛЕГІДЬ (через python-склейку в /tmp/final_test.luau) як
-- __PHONE_CONFIG_RESULT, а require() тут просто повертає його.
require = function(moduleInstance)
	if moduleInstance == __phoneConfigModuleInstance then
		return __PHONE_CONFIG_RESULT
	end
	error("MOCK require: unknown module instance")
end

local services = {
	Players = Players,
	UserInputService = UserInputService,
	TweenService = TweenService,
	RunService = RunService,
	ReplicatedStorage = ReplicatedStorage,
}

game = {
	GetService = function(_, name)
		local svc = services[name]
		assert(svc, "MOCK game:GetService: unknown service '" .. tostring(name) .. "'")
		return svc
	end,
}

print("=== MOCK ENV READY ===")
