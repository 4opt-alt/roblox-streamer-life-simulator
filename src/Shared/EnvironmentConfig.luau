--!strict

export type EnvironmentConfigType = {
    -- Скільки РЕАЛЬНИХ секунд триває день і ніч, і де їхні межі на годиннику
    DayLengthSeconds: number,   -- 45 хв реального часу на весь день
    NightLengthSeconds: number, -- 15 хв реального часу на всю ніч
    NightStartHour: number,     -- 21:00 — початок ночі
    NightEndHour: number,       -- 06:00 — кінець ночі (світанок)
    TransitionHours: number,    -- тривалість плавного світанку/заходу (в годинах ігрового часу)
    GeographicLatitude: number,

    -- Освітлення вдень / вночі (Ambient / Brightness)
    DayAmbient: Color3,
    DayOutdoorAmbient: Color3,
    DayBrightness: number,
    NightAmbient: Color3,
    NightOutdoorAmbient: Color3,
    NightBrightness: number,

    -- Atmosphere вдень / вночі (серпанок, сяйво сонця/місяця)
    AtmosphereDensity: number,
    AtmosphereOffset: number,
    DayAtmosphereColor: Color3,
    DayAtmosphereDecay: Color3,
    DayAtmosphereGlare: number,
    DayAtmosphereHaze: number,
    NightAtmosphereColor: Color3,
    NightAtmosphereDecay: Color3,
    NightAtmosphereGlare: number,
    NightAtmosphereHaze: number,

    -- Глобальні рухомі хмари (колір міняється між днем і ніччю)
    CloudsCover: number,
    CloudsDensity: number,
    DayCloudsColor: Color3,
    NightCloudsColor: Color3,
}

local EnvironmentConfig: EnvironmentConfigType = {
    DayLengthSeconds = 45 * 60,
    NightLengthSeconds = 15 * 60,
    NightStartHour = 21,
    NightEndHour = 6,
    TransitionHours = 0.75,
    GeographicLatitude = 35,

    DayAmbient = Color3.fromRGB(140, 145, 165),
    DayOutdoorAmbient = Color3.fromRGB(150, 165, 195),
    DayBrightness = 2.6,
    NightAmbient = Color3.fromRGB(35, 38, 58),
    NightOutdoorAmbient = Color3.fromRGB(25, 28, 46),
    NightBrightness = 0.9,

    AtmosphereDensity = 0.3,
    AtmosphereOffset = 0.25,
    DayAtmosphereColor = Color3.fromRGB(199, 199, 199),
    DayAtmosphereDecay = Color3.fromRGB(112, 125, 153),
    DayAtmosphereGlare = 0.2,
    DayAtmosphereHaze = 1.3,
    NightAtmosphereColor = Color3.fromRGB(40, 45, 70),
    NightAtmosphereDecay = Color3.fromRGB(18, 20, 35),
    NightAtmosphereGlare = 0,
    NightAtmosphereHaze = 1.7,

    CloudsCover = 0.38,
    CloudsDensity = 0.55,
    DayCloudsColor = Color3.fromRGB(255, 255, 255),
    NightCloudsColor = Color3.fromRGB(120, 130, 160),
}

return EnvironmentConfig
