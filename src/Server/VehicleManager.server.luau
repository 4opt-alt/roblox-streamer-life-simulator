--!strict
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Remotes (created idempotently — ShopManager may also create ShopItemPurchased first)
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
    remotesFolder = Instance.new("Folder")
    remotesFolder.Name = "Remotes"
    remotesFolder.Parent = ReplicatedStorage
end

local shopResultRemote = remotesFolder:FindFirstChild("ShopItemPurchased") :: RemoteEvent?
if not shopResultRemote then
    shopResultRemote = Instance.new("RemoteEvent")
    shopResultRemote.Name = "ShopItemPurchased"
    shopResultRemote.Parent = remotesFolder
end

-- Клієнт шле throttle/steer, поки стоїть на гіроскутері (замість VehicleSeat)
local hoverInputRemote = remotesFolder:FindFirstChild("HoverboardInput") :: RemoteEvent?
if not hoverInputRemote then
    hoverInputRemote = Instance.new("RemoteEvent")
    hoverInputRemote.Name = "HoverboardInput"
    hoverInputRemote.Parent = remotesFolder
end

-- Клієнт шле цю подію на Space, щоб зійти з гіроскутера
local hoverDismountRemote = remotesFolder:FindFirstChild("HoverboardDismount") :: RemoteEvent?
if not hoverDismountRemote then
    hoverDismountRemote = Instance.new("RemoteEvent")
    hoverDismountRemote.Name = "HoverboardDismount"
    hoverDismountRemote.Parent = remotesFolder
end

-- Сервер повідомляє клієнта: true = зайшов на гіроскутер, false = зійшов
local hoverMountRemote = remotesFolder:FindFirstChild("HoverboardMountChanged") :: RemoteEvent?
if not hoverMountRemote then
    hoverMountRemote = Instance.new("RemoteEvent")
    hoverMountRemote.Name = "HoverboardMountChanged"
    hoverMountRemote.Parent = remotesFolder
end

local HOVERBOARD_ITEM_ID = "Hoverboard"
local HOVER_SPEED = 34    -- відрегульована швидкість (повільніше і безпечніше за машину)
local TURN_SPEED = 3.2    -- швидкість повороту
local MAX_TILT_RADIANS = math.rad(7) -- невеликий нахил вперед/назад при русі (не сильний)

-- Стандартні ідентифікатори базових анімацій "стояти" від Roblox (публічні,
-- вбудовані в кожен стандартний Animate-скрипт) — використовуємо їх, щоб
-- персонаж виглядав так, ніби просто стоїть, а не сидить чи завис у T-позі.
local STAND_ANIM_R15 = "rbxassetid://507766388"
local STAND_ANIM_R6 = "rbxassetid://180435571"

-- Звук їзди на гіроскутері: тихе рівне електричне гудіння двигуна/гіроскопів,
-- що трохи "заводиться" гучніше при прискоренні — так, як звучить реальний
-- електричний гіроскутер/ховерборд, а не тупіт ніг персонажа по підлозі.
-- Перший підібраний звук ("Electrical Humming") виявився занадто гучним і не
-- дуже пасував по характеру — замінено на більш м'який/механічний SFX-звук
-- мотора, і суттєво знижена гучність (idle/max) відносно першої спроби.
-- Якщо цей конкретний звук колись стане недоступний (буває з модерацією Roblox) —
-- заміни ID тут: Studio → Toolbox → Audio → пошук "electric hum" / "hover" / "drone".
local HOVER_SOUND_ID = "rbxassetid://9125699963" -- "Motor Sounds Electric Whir Mechanical Movement (SFX)"
local HOVER_SOUND_IDLE_VOLUME = 0.10
local HOVER_SOUND_MAX_VOLUME = 0.30
local HOVER_SOUND_IDLE_PITCH = 0.85
local HOVER_SOUND_MAX_PITCH = 1.2

-- Стандартні звуки кроків/бігу персонажа (з вбудованого Animate-скрипта Roblox) —
-- їх треба вимкнути на час їзди, інакше чути "тупотіння", хоча персонаж стоїть на дошці.
local DEFAULT_MOVEMENT_SOUND_NAMES = {
    "Climbing", "FreeFalling", "GettingUp", "Jumping", "Landing", "Running", "Splash", "Swimming",
}

local function muteDefaultMovementSounds(character: Model): { [Sound]: number }
    local muted: { [Sound]: number } = {}
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    for _, container in { humanoid, hrp } do
        if container then
            for _, name in DEFAULT_MOVEMENT_SOUND_NAMES do
                local snd = container:FindFirstChild(name)
                if snd and snd:IsA("Sound") and muted[snd] == nil then
                    muted[snd] = snd.Volume
                    snd.Volume = 0
                end
            end
        end
    end
    return muted
end

local function restoreMutedSounds(muted: { [Sound]: number })
    for snd, originalVolume in muted do
        if snd and snd.Parent then
            snd.Volume = originalVolume
        end
    end
end

type RiderData = {
    weld: WeldConstraint,
    animTrack: AnimationTrack?,
    throttle: number,
    steer: number,
    mutedSounds: { [Sound]: number },
}

local function setupHoverboard()
    local board = workspace:WaitForChild("CityWorld", 10) and workspace.CityWorld:WaitForChild("Hoverboard", 10) :: Model?
    if not board then
        board = workspace:WaitForChild("Hoverboard", 5) :: Model?
    end
    if not board then return end

    local deck = board:WaitForChild("HoverboardBody", 5) :: BasePart?
    if not deck then return end

    board.PrimaryPart = deck

    -- Автоматично зварюємо всі деталі гіроскутера разом (WeldConstraint), щоб він не розвалювався!
    for _, part in board:GetDescendants() do
        if part:IsA("BasePart") and part ~= deck then
            part.Anchored = false
            -- Тільки колеса мають колізію з землею. Дека, накладки, LED-смуги CanCollide = false.
            part.CanCollide = (part.Name:find("Wheel") ~= nil)
            part.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.5, 0.5, 70, 100)

            local weld = part:FindFirstChild("HoverWeld") :: WeldConstraint?
            if not weld then
                weld = Instance.new("WeldConstraint")
                weld.Name = "HoverWeld"
                weld.Part0 = deck
                weld.Part1 = part
                weld.Parent = part
            end
        end
    end

    deck.Anchored = false
    deck.CustomPhysicalProperties = PhysicalProperties.new(1.2, 0.6, 0.5, 60, 100)

    local existingBadge = deck:FindFirstChild("HoverBadge") :: BillboardGui?

    -- Надійний ProximityPrompt для посадки (E)
    local ridePrompt = deck:FindFirstChild("RidePrompt") :: ProximityPrompt?
    if not ridePrompt then
        ridePrompt = Instance.new("ProximityPrompt")
        ridePrompt.Name = "RidePrompt"
        ridePrompt.ObjectText = "Galaxy Hoverboard"
        ridePrompt.ActionText = "Ride (E)"
        ridePrompt.HoldDuration = 0
        ridePrompt.MaxActivationDistance = 10
        ridePrompt.KeyboardKeyCode = Enum.KeyCode.E
        ridePrompt.RequiresLineOfSight = false
        ridePrompt.Parent = deck
    end

    local riders: { [Player]: RiderData } = {}

    local function setPromptAvailable(available: boolean)
        ridePrompt.Enabled = available
        if existingBadge then
            existingBadge.Enabled = available
        end
    end

    local function dismountPlayer(player: Player)
        local data = riders[player]
        if not data then return end
        riders[player] = nil

        if data.weld then
            data.weld:Destroy()
        end
        if data.animTrack then
            data.animTrack:Stop()
        end
        restoreMutedSounds(data.mutedSounds)

        local character = player.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid?
            local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
            if humanoid then
                humanoid.PlatformStand = false
                humanoid.AutoRotate = true
            end
            -- Відштовхуємо гравця вбік, щоб він одразу не активував підказку знову
            if hrp then
                hrp.CFrame = hrp.CFrame * CFrame.new(2.5, 0.5, 0)
            end
        end

        setPromptAvailable(true)
        hoverMountRemote:FireClient(player, false)
    end

    local function mountPlayer(player: Player)
        if riders[player] then return end

        local character = player.Character
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid?
        local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
        if not humanoid or not hrp then return end

        -- Ставимо персонажа боком до напрямку руху (як на реальному гіроскутері/скейті),
        -- ногами вздовж дошки — по одній нозі приблизно на кожну чорну накладку
        -- (FootpadFront/FootpadBack), а не обличчям вперед.
        hrp.CFrame = deck.CFrame * CFrame.new(0, deck.Size.Y / 2 + 3.0, 0) * CFrame.Angles(0, math.rad(90), 0)

        humanoid.PlatformStand = true
        humanoid.AutoRotate = false

        local weld = Instance.new("WeldConstraint")
        weld.Name = "HoverboardRiderWeld"
        weld.Part0 = deck
        weld.Part1 = hrp
        weld.Parent = hrp

        -- Програємо анімацію "стояти", інакше персонаж завис би нерухомо в останній позі
        local animTrack: AnimationTrack? = nil
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator then
            local anim = Instance.new("Animation")
            anim.AnimationId = (humanoid.RigType == Enum.HumanoidRigType.R15) and STAND_ANIM_R15 or STAND_ANIM_R6
            local ok, track = pcall(function()
                return animator:LoadAnimation(anim)
            end)
            if ok and track then
                track.Priority = Enum.AnimationPriority.Action
                track.Looped = true
                track:Play()
                animTrack = track
            end
        end

        local mutedSounds = muteDefaultMovementSounds(character)

        riders[player] = { weld = weld, animTrack = animTrack, throttle = 0, steer = 0, mutedSounds = mutedSounds }

        setPromptAvailable(false)
        hoverMountRemote:FireClient(player, true)
    end

    ridePrompt.Triggered:Connect(function(player: Player)
        -- Гейт власності: гіроскутер потрібно спочатку купити в магазині
        if not (player:GetAttribute("Owned_" .. HOVERBOARD_ITEM_ID) == true) then
            shopResultRemote:FireClient(player, HOVERBOARD_ITEM_ID, false, "🛹 Купи Galaxy Hoverboard в магазині, щоб покататись!")
            return
        end
        mountPlayer(player)
    end)

    hoverDismountRemote.OnServerEvent:Connect(function(player: Player)
        dismountPlayer(player)
    end)

    hoverInputRemote.OnServerEvent:Connect(function(player: Player, throttle: any, steer: any)
        local data = riders[player]
        if not data then return end
        if typeof(throttle) ~= "number" or typeof(steer) ~= "number" then return end
        data.throttle = math.clamp(throttle, -1, 1)
        data.steer = math.clamp(steer, -1, 1)
    end)

    Players.PlayerRemoving:Connect(function(player)
        if riders[player] then
            riders[player] = nil
            setPromptAvailable(true)
        end
    end)

    -- Якщо персонаж помер/зреспавнився під час катання — знімаємо його з гіроскутера
    Players.PlayerAdded:Connect(function(player)
        player.CharacterRemoving:Connect(function()
            if riders[player] then
                if riders[player].weld then riders[player].weld:Destroy() end
                riders[player] = nil
                setPromptAvailable(true)
            end
        end)
    end)

    -- Аркадний привід (BodyVelocity + BodyAngularVelocity)
    local bv = deck:FindFirstChild("HoverVelocity") :: BodyVelocity?
    if not bv then
        bv = Instance.new("BodyVelocity")
        bv.Name = "HoverVelocity"
        bv.MaxForce = Vector3.new(0, 0, 0)
        bv.Velocity = Vector3.zero
        bv.Parent = deck
    end

    local bav = deck:FindFirstChild("HoverAngularVelocity") :: BodyAngularVelocity?
    if not bav then
        bav = Instance.new("BodyAngularVelocity")
        bav.Name = "HoverAngularVelocity"
        bav.MaxTorque = Vector3.new(0, 0, 0)
        bav.AngularVelocity = Vector3.zero
        bav.Parent = deck
    end

    -- Стабілізатор горизонтального положення (запобігає перевертанню гіроскутера)
    local bg = deck:FindFirstChild("HoverGyro") :: BodyGyro?
    if not bg then
        bg = Instance.new("BodyGyro")
        bg.Name = "HoverGyro"
        bg.MaxTorque = Vector3.new(4e4, 0, 4e4)
        bg.P = 3000
        bg.Parent = deck
    end

    -- Звук двигуна гіроскутера (замість тупотіння ніг) — рівне гудіння на холостому ході,
    -- трохи гучніше й вище тоном при прискоренні (див. HOVER_SOUND_* константи вище).
    local hoverSound = deck:FindFirstChild("HoverEngineSound") :: Sound?
    if not hoverSound then
        hoverSound = Instance.new("Sound")
        hoverSound.Name = "HoverEngineSound"
        hoverSound.SoundId = HOVER_SOUND_ID
        hoverSound.Looped = true
        hoverSound.Volume = 0
        hoverSound.PlaybackSpeed = HOVER_SOUND_IDLE_PITCH
        hoverSound.RollOffMaxDistance = 60
        hoverSound.Parent = deck
    end

    local spawnPosition = Vector3.new(14, 2.6, -42)

    -- Цикл керування рухом гіроскутера
    RunService.Heartbeat:Connect(function()
        if not deck or not bv or not bav or not bg then return end

        local isRiding = next(riders) ~= nil
        local throttle, steer = 0, 0
        for _, data in riders do
            throttle, steer = data.throttle, data.steer
            break -- гіроскутер одномісний
        end

        -- Звук двигуна: грає весь час поки хтось їде (навіть на холостому ході),
        -- гучнішає й вищає тоном пропорційно до того, наскільки сильно тиснуть газ.
        if hoverSound then
            if isRiding and not hoverSound.IsPlaying then
                hoverSound:Play()
            elseif not isRiding and hoverSound.IsPlaying then
                hoverSound:Stop()
            end
            if isRiding then
                local speedFrac = math.abs(throttle)
                hoverSound.Volume = HOVER_SOUND_IDLE_VOLUME + speedFrac * (HOVER_SOUND_MAX_VOLUME - HOVER_SOUND_IDLE_VOLUME)
                hoverSound.PlaybackSpeed = HOVER_SOUND_IDLE_PITCH + speedFrac * (HOVER_SOUND_MAX_PITCH - HOVER_SOUND_IDLE_PITCH)
            end
        end

        if throttle ~= 0 or steer ~= 0 or isRiding then
            -- Персонаж стоїть боком (розвернутий на 90° від LookVector дошки),
            -- тож "вперед" — це туди, куди дивиться обличчя: вздовж -RightVector,
            -- а не вздовж LookVector (інакше дошка їхала б "як машина" боком).
            local travelVector = -deck.CFrame.RightVector

            bv.MaxForce = Vector3.new(2.2e5, 0, 2.2e5)
            bv.Velocity = travelVector * (throttle * HOVER_SPEED)

            bav.MaxTorque = Vector3.new(0, 2.2e5, 0)
            bav.AngularVelocity = Vector3.new(0, -steer * TURN_SPEED, 0)

            -- Невеликий нахил дошки (і персонажа, бо він до неї приварений) вперед
            -- при русі вперед і назад при русі назад — як на реальному гіроскутері.
            -- Нахил тепер навколо іншої осі (Z), бо рух іде вздовж X, а не вздовж Z.
            local tiltAngle = throttle * MAX_TILT_RADIANS
            bg.CFrame = CFrame.new(deck.Position, deck.Position + deck.CFrame.LookVector) * CFrame.Angles(0, 0, tiltAngle)
        else
            bv.MaxForce = Vector3.new(2.2e5, 0, 2.2e5)
            bv.Velocity = Vector3.zero
            bav.MaxTorque = Vector3.new(0, 2.2e5, 0)
            bav.AngularVelocity = Vector3.zero
        end

        -- Автоматичне повернення гіроскутера, якщо він впав нижче карти
        if deck.Position.Y < -20 then
            deck.CFrame = CFrame.new(spawnPosition)
            deck.AssemblyLinearVelocity = Vector3.zero
            deck.AssemblyAngularVelocity = Vector3.zero
            for player in riders do
                dismountPlayer(player)
            end
        end
    end)
end

task.spawn(setupHoverboard)
