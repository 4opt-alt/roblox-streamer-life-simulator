--!strict
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnvironmentConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("EnvironmentConfig") :: ModuleScript)

--------------------------------------------------------------------------------
-- Базове освітлення дня (Ambient / Brightness / широта сонця)
--------------------------------------------------------------------------------
Lighting.Ambient = EnvironmentConfig.AmbientColor
Lighting.OutdoorAmbient = EnvironmentConfig.OutdoorAmbientColor
Lighting.Brightness = EnvironmentConfig.Brightness
Lighting.GeographicLatitude = EnvironmentConfig.GeographicLatitude

--------------------------------------------------------------------------------
-- Atmosphere: серпанок + сяйво навколо сонця (глибина і кінематографічність)
--------------------------------------------------------------------------------
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
if not atmosphere then
    atmosphere = Instance.new("Atmosphere")
    atmosphere.Parent = Lighting
end
atmosphere.Density = EnvironmentConfig.AtmosphereDensity
atmosphere.Offset = EnvironmentConfig.AtmosphereOffset
atmosphere.Color = EnvironmentConfig.AtmosphereColor
atmosphere.Decay = EnvironmentConfig.AtmosphereDecay
atmosphere.Glare = EnvironmentConfig.AtmosphereGlare
atmosphere.Haze = EnvironmentConfig.AtmosphereHaze

--------------------------------------------------------------------------------
-- Глобальні рухомі хмари (вбудований рушій Roblox сам анімує їх у небі,
-- видно з будь-якої точки карти, без жодних додаткових Part/Tween)
--------------------------------------------------------------------------------
local clouds = Workspace:FindFirstChildOfClass("Clouds")
if not clouds then
    clouds = Instance.new("Clouds")
    clouds.Parent = Workspace
end
clouds.Color = EnvironmentConfig.CloudsColor
clouds.Cover = EnvironmentConfig.CloudsCover
clouds.Density = EnvironmentConfig.CloudsDensity

--------------------------------------------------------------------------------
-- Повільний рух сонця по небу: коливається між ранком і золотою годиною,
-- ніколи не йде в повну ніч, щоб не заважати стрімінгу/видимості на карті.
--------------------------------------------------------------------------------
task.spawn(function()
    local minHour = EnvironmentConfig.SunMinClockTime
    local maxHour = EnvironmentConfig.SunMaxClockTime
    local sweepSeconds = math.max(1, EnvironmentConfig.SunSweepSeconds)
    local hoursPerSecond = (maxHour - minHour) / sweepSeconds

    if Lighting.ClockTime < minHour or Lighting.ClockTime > maxHour then
        Lighting.ClockTime = (minHour + maxHour) / 2
    end

    local direction = 1
    while true do
        task.wait(1)
        Lighting.ClockTime += hoursPerSecond * direction

        if Lighting.ClockTime >= maxHour then
            Lighting.ClockTime = maxHour
            direction = -1
        elseif Lighting.ClockTime <= minHour then
            Lighting.ClockTime = minHour
            direction = 1
        end
    end
end)
