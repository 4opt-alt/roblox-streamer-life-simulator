--!strict
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnvironmentConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("EnvironmentConfig") :: ModuleScript)

Lighting.GeographicLatitude = EnvironmentConfig.GeographicLatitude
Lighting.ClockTime = 12 -- старт ігрового дня о яскравому полудні

--------------------------------------------------------------------------------
-- Sky: небесна сфера з сонцем, місяцем і зірками (вбудований рушій Roblox,
-- сам показує/приховує місяць і зірки залежно від часу доби)
--------------------------------------------------------------------------------
local sky = Lighting:FindFirstChildOfClass("Sky")
if not sky then
    sky = Instance.new("Sky")
    sky.Parent = Lighting
end

--------------------------------------------------------------------------------
-- Atmosphere: серпанок і сяйво навколо сонця/місяця
--------------------------------------------------------------------------------
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
if not atmosphere then
    atmosphere = Instance.new("Atmosphere")
    atmosphere.Parent = Lighting
end
atmosphere.Density = EnvironmentConfig.AtmosphereDensity
atmosphere.Offset = EnvironmentConfig.AtmosphereOffset

--------------------------------------------------------------------------------
-- Глобальні рухомі хмари (вбудований шар Roblox, анімується сам у небі)
--------------------------------------------------------------------------------
local clouds = Workspace:FindFirstChildOfClass("Clouds")
if not clouds then
    clouds = Instance.new("Clouds")
    clouds.Parent = Workspace
end
clouds.Cover = EnvironmentConfig.CloudsCover
clouds.Density = EnvironmentConfig.CloudsDensity

--------------------------------------------------------------------------------
-- Цикл дня і ночі: 45 хв день + 15 хв ніч, з плавним світанком/заходом.
-- Годинник рухається різною швидкістю вдень і вночі (не лінійно по колу),
-- щоб реальний час дня/ночі точно збігався з таймінгом з конфігу.
--------------------------------------------------------------------------------
local function hoursBetween(fromHour: number, toHour: number): number
    -- Кількість годин по колу від fromHour до toHour (з переходом через 24 за потреби)
    local diff = toHour - fromHour
    if diff <= 0 then
        diff += 24
    end
    return diff
end

local nightHours = hoursBetween(EnvironmentConfig.NightStartHour, EnvironmentConfig.NightEndHour)
local dayHours = 24 - nightHours

local dayRatePerSecond = dayHours / EnvironmentConfig.DayLengthSeconds
local nightRatePerSecond = nightHours / EnvironmentConfig.NightLengthSeconds

local function isNightClockTime(clockTime: number): boolean
    if EnvironmentConfig.NightStartHour > EnvironmentConfig.NightEndHour then
        return clockTime >= EnvironmentConfig.NightStartHour or clockTime < EnvironmentConfig.NightEndHour
    else
        return clockTime >= EnvironmentConfig.NightStartHour and clockTime < EnvironmentConfig.NightEndHour
    end
end

-- 0 = повна ніч, 1 = повний день, плавно на межах світанку/заходу
local function getDayFactor(clockTime: number): number
    local sinceDawn = hoursBetween(EnvironmentConfig.NightEndHour, clockTime)
    local transition = math.max(0.01, EnvironmentConfig.TransitionHours)

    if sinceDawn < transition then
        return sinceDawn / transition -- світанок: 0 -> 1
    elseif sinceDawn < dayHours - transition then
        return 1 -- повний день
    elseif sinceDawn < dayHours then
        return (dayHours - sinceDawn) / transition -- захід: 1 -> 0
    else
        return 0 -- повна ніч
    end
end

task.spawn(function()
    while true do
        task.wait(1)

        local night = isNightClockTime(Lighting.ClockTime)
        local rate = night and nightRatePerSecond or dayRatePerSecond
        Lighting.ClockTime = (Lighting.ClockTime + rate) % 24

        local dayFactor = getDayFactor(Lighting.ClockTime)

        Lighting.Ambient = EnvironmentConfig.NightAmbient:Lerp(EnvironmentConfig.DayAmbient, dayFactor)
        Lighting.OutdoorAmbient = EnvironmentConfig.NightOutdoorAmbient:Lerp(EnvironmentConfig.DayOutdoorAmbient, dayFactor)
        Lighting.Brightness = EnvironmentConfig.NightBrightness
            + (EnvironmentConfig.DayBrightness - EnvironmentConfig.NightBrightness) * dayFactor

        atmosphere.Color = EnvironmentConfig.NightAtmosphereColor:Lerp(EnvironmentConfig.DayAtmosphereColor, dayFactor)
        atmosphere.Decay = EnvironmentConfig.NightAtmosphereDecay:Lerp(EnvironmentConfig.DayAtmosphereDecay, dayFactor)
        atmosphere.Glare = EnvironmentConfig.NightAtmosphereGlare
            + (EnvironmentConfig.DayAtmosphereGlare - EnvironmentConfig.NightAtmosphereGlare) * dayFactor
        atmosphere.Haze = EnvironmentConfig.NightAtmosphereHaze
            + (EnvironmentConfig.DayAtmosphereHaze - EnvironmentConfig.NightAtmosphereHaze) * dayFactor

        clouds.Color = EnvironmentConfig.NightCloudsColor:Lerp(EnvironmentConfig.DayCloudsColor, dayFactor)
    end
end)
