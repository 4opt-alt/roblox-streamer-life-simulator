--!strict

export type EnvironmentConfigType = {
    -- Базове освітлення дня
    AmbientColor: Color3,
    OutdoorAmbientColor: Color3,
    Brightness: number,
    GeographicLatitude: number,

    -- Повільний рух сонця по небу (день <-> золота година, без повної ночі)
    SunMinClockTime: number,
    SunMaxClockTime: number,
    SunSweepSeconds: number, -- скільки секунд займає прохід від Min до Max

    -- Atmosphere: серпанок і сяйво навколо сонця
    AtmosphereDensity: number,
    AtmosphereOffset: number,
    AtmosphereColor: Color3,
    AtmosphereDecay: Color3,
    AtmosphereGlare: number,
    AtmosphereHaze: number,

    -- Глобальні рухомі хмари (вбудований шар Roblox, анімується самостійно)
    CloudsColor: Color3,
    CloudsCover: number,
    CloudsDensity: number,
}

local EnvironmentConfig: EnvironmentConfigType = {
    AmbientColor = Color3.fromRGB(140, 145, 165),
    OutdoorAmbientColor = Color3.fromRGB(150, 165, 195),
    Brightness = 2.6,
    GeographicLatitude = 35,

    SunMinClockTime = 9,
    SunMaxClockTime = 18,
    SunSweepSeconds = 24 * 60, -- 24 хв в один бік -> ~48 хв повний цикл

    AtmosphereDensity = 0.3,
    AtmosphereOffset = 0.25,
    AtmosphereColor = Color3.fromRGB(199, 199, 199),
    AtmosphereDecay = Color3.fromRGB(112, 125, 153),
    AtmosphereGlare = 0.2,
    AtmosphereHaze = 1.3,

    CloudsColor = Color3.fromRGB(255, 255, 255),
    CloudsCover = 0.38,
    CloudsDensity = 0.55,
}

return EnvironmentConfig
