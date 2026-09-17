--!strict
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create FlipCar remote if not present
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
    remotesFolder = Instance.new("Folder")
    remotesFolder.Name = "Remotes"
    remotesFolder.Parent = ReplicatedStorage
end

local flipCarRemote = remotesFolder:FindFirstChild("FlipCar") :: RemoteEvent?
if not flipCarRemote then
    flipCarRemote = Instance.new("RemoteEvent")
    flipCarRemote.Name = "FlipCar"
    flipCarRemote.Parent = remotesFolder
end

local function setupCar()
    local car = workspace:WaitForChild("CityWorld", 10) and workspace.CityWorld:WaitForChild("StarterCar", 10) :: Model?
    if not car then
        car = workspace:WaitForChild("StarterCar", 5) :: Model?
    end
    if not car then return end

    local chassis = car:WaitForChild("CarChassis", 5) :: BasePart?
    local seat = car:WaitForChild("VehicleSeat", 5) :: VehicleSeat?
    local passSeat = car:FindFirstChild("PassengerSeat") :: Seat?
    if not chassis or not seat then return end

    car.PrimaryPart = chassis

    -- Автоматично зварюємо всі деталі машини разом (WeldConstraint), щоб вона не розвалювалася!
    for _, part in car:GetDescendants() do
        if part:IsA("BasePart") and part ~= chassis then
            part.Anchored = false
            -- Тільки колеса мають колізію з землею. Кузов, дах і вікна CanCollide = false, щоб гравець не застрягав!
            part.CanCollide = (part.Name:find("Wheel") ~= nil)
            part.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.5, 0.5, 100, 100)

            -- Створюємо WeldConstraint до шасі
            local weld = part:FindFirstChild("CarWeld") :: WeldConstraint?
            if not weld then
                weld = Instance.new("WeldConstraint")
                weld.Name = "CarWeld"
                weld.Part0 = chassis
                weld.Part1 = part
                weld.Parent = part
            end
        end
    end

    chassis.Anchored = false
    chassis.CanCollide = true
    chassis.CustomPhysicalProperties = PhysicalProperties.new(1.8, 0.9, 0.5, 100, 100)

    -- 3D Floating Badge над авто
    local existingBadge = chassis:FindFirstChild("CarBadge") :: BillboardGui?
    if not existingBadge then
        existingBadge = Instance.new("BillboardGui")
        existingBadge.Name = "CarBadge"
        existingBadge.Size = UDim2.new(0, 160, 0, 42)
        existingBadge.StudsOffset = Vector3.new(0, 4.8, 0)
        existingBadge.AlwaysOnTop = true
        existingBadge.MaxDistance = 90
        existingBadge.Parent = chassis

        local badgeFrame = Instance.new("Frame")
        badgeFrame.Size = UDim2.new(1, 0, 1, 0)
        badgeFrame.BackgroundColor3 = Color3.fromRGB(22, 26, 36)
        badgeFrame.BackgroundTransparency = 0.2
        badgeFrame.BorderSizePixel = 0
        badgeFrame.Parent = existingBadge

        local bCorner = Instance.new("UICorner")
        bCorner.CornerRadius = UDim.new(0, 10)
        bCorner.Parent = badgeFrame

        local bStroke = Instance.new("UIStroke")
        bStroke.Color = Color3.fromRGB(231, 76, 60)
        bStroke.Thickness = 2
        bStroke.Parent = badgeFrame

        local bLabel = Instance.new("TextLabel")
        bLabel.Size = UDim2.new(1, 0, 1, 0)
        bLabel.BackgroundTransparency = 1
        bLabel.Font = Enum.Font.GothamBold
        bLabel.TextSize = 14
        bLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        bLabel.Text = "🚗 Starter Sedan [E]"
        bLabel.Parent = badgeFrame
    end

    -- Надійний ProximityPrompt для посадки за кермо (E)
    local drivePrompt = chassis:FindFirstChild("DrivePrompt") :: ProximityPrompt?
    if not drivePrompt then
        drivePrompt = Instance.new("ProximityPrompt")
        drivePrompt.Name = "DrivePrompt"
        drivePrompt.ObjectText = "Starter Sedan"
        drivePrompt.ActionText = "Drive Car (E)"
        drivePrompt.HoldDuration = 0
        drivePrompt.MaxActivationDistance = 14
        drivePrompt.KeyboardKeyCode = Enum.KeyCode.E
        drivePrompt.RequiresLineOfSight = false
        drivePrompt.Parent = chassis
    end

    drivePrompt.Triggered:Connect(function(player: Player)
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid and seat.Occupant == nil then
                seat:Sit(humanoid)
            end
        end
    end)

    seat:GetPropertyChangedSignal("Occupant"):Connect(function()
        if drivePrompt then
            drivePrompt.Enabled = (seat.Occupant == nil)
        end
        if existingBadge then
            existingBadge.Enabled = (seat.Occupant == nil)
        end
    end)

    -- Пасажирське сидіння
    if passSeat then
        local passPrompt = Instance.new("ProximityPrompt")
        passPrompt.Name = "PassengerPrompt"
        passPrompt.ObjectText = "Passenger Seat"
        passPrompt.ActionText = "Sit as Passenger"
        passPrompt.HoldDuration = 0
        passPrompt.MaxActivationDistance = 12
        passPrompt.KeyboardKeyCode = Enum.KeyCode.G
        passPrompt.RequiresLineOfSight = false
        passPrompt.Parent = passSeat

        passPrompt.Triggered:Connect(function(player: Player)
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid and passSeat.Occupant == nil then
                    passSeat:Sit(humanoid)
                end
            end
        end)

        passSeat:GetPropertyChangedSignal("Occupant"):Connect(function()
            passPrompt.Enabled = (passSeat.Occupant == nil)
        end)
    end

    -- Надійний аркадний привід (BodyVelocity + BodyAngularVelocity)
    local bv = chassis:FindFirstChild("CarVelocity") :: BodyVelocity?
    if not bv then
        bv = Instance.new("BodyVelocity")
        bv.Name = "CarVelocity"
        bv.MaxForce = Vector3.new(0, 0, 0)
        bv.Velocity = Vector3.zero
        bv.Parent = chassis
    end

    local bav = chassis:FindFirstChild("CarAngularVelocity") :: BodyAngularVelocity?
    if not bav then
        bav = Instance.new("BodyAngularVelocity")
        bav.Name = "CarAngularVelocity"
        bav.MaxTorque = Vector3.new(0, 0, 0)
        bav.AngularVelocity = Vector3.zero
        bav.Parent = chassis
    end

    -- Стабілізатор горизонтального положення (запобігає перевертанню)
    local bg = chassis:FindFirstChild("CarGyro") :: BodyGyro?
    if not bg then
        bg = Instance.new("BodyGyro")
        bg.Name = "CarGyro"
        bg.MaxTorque = Vector3.new(1e5, 0, 1e5)
        bg.P = 3000
        bg.Parent = chassis
    end

    local CAR_SPEED = 52
    local TURN_SPEED = 2.4
    local spawnPosition = Vector3.new(14, 2.5, -42)

    -- Обробка перевертання авто на клавішу F або при застряганні
    local function flipCar()
        local currentPos = chassis.Position
        local look = chassis.CFrame.LookVector
        chassis.CFrame = CFrame.lookAt(currentPos + Vector3.new(0, 3.5, 0), currentPos + Vector3.new(look.X, 0, look.Z))
        chassis.AssemblyLinearVelocity = Vector3.zero
        chassis.AssemblyAngularVelocity = Vector3.zero
    end

    flipCarRemote.OnServerEvent:Connect(function(player: Player)
        local character = player.Character
        if character and seat and seat.Occupant == character:FindFirstChildOfClass("Humanoid") then
            flipCar()
        end
    end)

    -- Цикл керування рухом автомобіля
    RunService.Heartbeat:Connect(function()
        if not seat or not chassis or not bv or not bav or not bg then return end

        local driver = seat.Occupant
        if driver then
            -- Гравець за кермом: передаємо команди W/S та A/D
            local throttle = seat.ThrottleFloat
            local steer = seat.SteerFloat

            -- Рух вперед/назад
            bv.MaxForce = Vector3.new(3e5, 0, 3e5)
            bv.Velocity = chassis.CFrame.LookVector * (throttle * CAR_SPEED)

            -- Поворот вліво/вправо
            bav.MaxTorque = Vector3.new(0, 3e5, 0)
            bav.AngularVelocity = Vector3.new(0, -steer * TURN_SPEED, 0)

            -- Стабілізація орієнтації
            bg.CFrame = CFrame.new(chassis.Position, chassis.Position + chassis.CFrame.LookVector)

            -- Увімкнення фар
            for _, descendant in car:GetDescendants() do
                if descendant:IsA("SpotLight") then
                    descendant.Enabled = true
                end
            end
        else
            -- Машина пуста: стоїть на ручнику
            bv.MaxForce = Vector3.new(3e5, 0, 3e5)
            bv.Velocity = Vector3.zero
            bav.MaxTorque = Vector3.new(0, 3e5, 0)
            bav.AngularVelocity = Vector3.zero

            -- Вимкнення фар
            for _, descendant in car:GetDescendants() do
                if descendant:IsA("SpotLight") then
                    descendant.Enabled = false
                end
            end
        end

        -- Автоматичне повернення машини, якщо вона впала нижче карти
        if chassis.Position.Y < -20 then
            chassis.CFrame = CFrame.new(spawnPosition)
            chassis.AssemblyLinearVelocity = Vector3.zero
            chassis.AssemblyAngularVelocity = Vector3.zero
        end
    end)
end

task.spawn(setupCar)
