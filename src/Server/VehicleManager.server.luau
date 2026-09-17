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

local HOVERBOARD_ITEM_ID = "Hoverboard"

local function setupHoverboard()
    local board = workspace:WaitForChild("CityWorld", 10) and workspace.CityWorld:WaitForChild("Hoverboard", 10) :: Model?
    if not board then
        board = workspace:WaitForChild("Hoverboard", 5) :: Model?
    end
    if not board then return end

    local deck = board:WaitForChild("HoverboardBody", 5) :: BasePart?
    local seat = board:WaitForChild("VehicleSeat", 5) :: VehicleSeat?
    if not deck or not seat then return end

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
    deck.CanCollide = false
    deck.CustomPhysicalProperties = PhysicalProperties.new(1.2, 0.6, 0.5, 60, 100)

    -- 3D Floating Badge над гіроскутером
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

    ridePrompt.Triggered:Connect(function(player: Player)
        -- Гейт власності: гіроскутер потрібно спочатку купити в магазині
        if not (player:GetAttribute("Owned_" .. HOVERBOARD_ITEM_ID) == true) then
            shopResultRemote:FireClient(player, HOVERBOARD_ITEM_ID, false, "🛹 Купи Galaxy Hoverboard в магазині, щоб покататись!")
            return
        end

        local character = player.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid and seat.Occupant == nil then
                seat:Sit(humanoid)
            end
        end
    end)

    seat:GetPropertyChangedSignal("Occupant"):Connect(function()
        if ridePrompt then
            ridePrompt.Enabled = (seat.Occupant == nil)
        end
        if existingBadge then
            existingBadge.Enabled = (seat.Occupant == nil)
        end
    end)

    -- Аркадний привід (BodyVelocity + BodyAngularVelocity), відрегульована швидкість гіроскутера
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

    local HOVER_SPEED = 34    -- відрегульована швидкість (повільніше і безпечніше за машину)
    local TURN_SPEED = 3.2    -- швидкість повороту
    local spawnPosition = Vector3.new(14, 2.6, -42)

    -- Цикл керування рухом гіроскутера
    RunService.Heartbeat:Connect(function()
        if not seat or not deck or not bv or not bav or not bg then return end

        local rider = seat.Occupant
        if rider then
            -- Гравець на гіроскутері: передаємо команди W/S та A/D
            local throttle = seat.ThrottleFloat
            local steer = seat.SteerFloat

            -- Рух вперед/назад
            bv.MaxForce = Vector3.new(2.2e5, 0, 2.2e5)
            bv.Velocity = deck.CFrame.LookVector * (throttle * HOVER_SPEED)

            -- Поворот вліво/вправо
            bav.MaxTorque = Vector3.new(0, 2.2e5, 0)
            bav.AngularVelocity = Vector3.new(0, -steer * TURN_SPEED, 0)

            -- Стабілізація орієнтації (рівний гіроскутер)
            bg.CFrame = CFrame.new(deck.Position, deck.Position + deck.CFrame.LookVector)
        else
            -- Гіроскутер пустий: стоїть на місці
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
        end
    end)
end

task.spawn(setupHoverboard)
