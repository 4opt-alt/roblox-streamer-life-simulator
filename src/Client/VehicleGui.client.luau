--!strict
-- Гіроскутером керуємо без VehicleSeat (щоб персонаж СТОЯВ, а не сидів),
-- тому клієнт сам зчитує W/A/S/D, поки стоїть на дошці, і шле це на сервер.
-- Ніякої окремої приладової панелі на екрані немає — посадка/зсадка й так
-- підказуються нативним ProximityPrompt ("Ride (E)") та клавішею Space.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
local hoverInputRemote = remotesFolder:WaitForChild("HoverboardInput") :: RemoteEvent
local hoverDismountRemote = remotesFolder:WaitForChild("HoverboardDismount") :: RemoteEvent
local hoverMountRemote = remotesFolder:WaitForChild("HoverboardMountChanged") :: RemoteEvent

local isMounted = false
local keysDown = { W = false, S = false, A = false, D = false }
local lastThrottle, lastSteer = 0, 0

local function sendInputIfChanged()
    local throttle = (keysDown.W and 1 or 0) - (keysDown.S and 1 or 0)
    local steer = (keysDown.D and 1 or 0) - (keysDown.A and 1 or 0)
    if throttle ~= lastThrottle or steer ~= lastSteer then
        lastThrottle, lastSteer = throttle, steer
        hoverInputRemote:FireServer(throttle, steer)
    end
end

local KEY_MAP: { [Enum.KeyCode]: string } = {
    [Enum.KeyCode.W] = "W",
    [Enum.KeyCode.S] = "S",
    [Enum.KeyCode.A] = "A",
    [Enum.KeyCode.D] = "D",
}

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or not isMounted then return end

    if input.KeyCode == Enum.KeyCode.Space then
        hoverDismountRemote:FireServer()
        return
    end

    local key = KEY_MAP[input.KeyCode]
    if key then
        keysDown[key] = true
        sendInputIfChanged()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    local key = KEY_MAP[input.KeyCode]
    if key then
        keysDown[key] = false
        sendInputIfChanged()
    end
end)

hoverMountRemote.OnClientEvent:Connect(function(mounted: boolean)
    isMounted = mounted
    if not mounted then
        keysDown.W, keysDown.S, keysDown.A, keysDown.D = false, false, false, false
        lastThrottle, lastSteer = 0, 0
    end
end)
