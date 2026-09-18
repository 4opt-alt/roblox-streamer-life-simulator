--!strict
-- Конфіг телефону та "творчої економіки" контент-мейкера.
-- Іконки/назви застосунків навмисно ВИГАДАНІ (не справжні лого TikTok/YouTube/
-- Twitch) — просто емодзі + власні бренди, щоб нічиїх авторських прав не
-- порушувати. ClipZap — аналог TikTok (завжди відкритий), WatchBox — аналог
-- YouTube, LiveWave — аналог Twitch (обидва розблоковуються пізніше, коли
-- набереться достатньо підписників).

export type AppConfig = {
	Id: string,
	DisplayName: string,
	Icon: string,
	AccentColor: Color3,
	UnlockFollowers: number, -- 0 = розблоковано з самого початку
}

local PhoneConfig = {}

PhoneConfig.Apps = {
	{
		Id = "ClipZap",
		DisplayName = "ClipZap",
		Icon = "🎬",
		AccentColor = Color3.fromRGB(255, 45, 110),
		UnlockFollowers = 0,
	} :: AppConfig,
	{
		Id = "WatchBox",
		DisplayName = "WatchBox",
		Icon = "📺",
		AccentColor = Color3.fromRGB(230, 60, 60),
		UnlockFollowers = 100,
	} :: AppConfig,
	{
		Id = "LiveWave",
		DisplayName = "LiveWave",
		Icon = "🎥",
		AccentColor = Color3.fromRGB(150, 90, 255),
		UnlockFollowers = 500,
	} :: AppConfig,
}

-- Баланс "творчої економіки": скільки лайків/підписників приносить одне
-- відео в ClipZap, і скільки доларів капає за кожні N лайків.
PhoneConfig.Economy = {
	LikesPerDollar = 10,
	MinLikesPerVideo = 5,
	MaxLikesPerVideo = 60,
	MinFollowersPerVideo = 1,
	MaxFollowersPerVideo = 8,
	RecordSeconds = 4,   -- скільки триває анімація запису на клієнті
	CooldownSeconds = 2, -- пауза між відео після публікації
}

return PhoneConfig
