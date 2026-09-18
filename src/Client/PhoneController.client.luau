--!strict
-- Телефон гравця: маленька підказка "[P] Take out phone", сам телефон, який
-- живе з ПРАВОГО боку екрана (не закриває вид на персонажа), з 3 іконками
-- застосунків (ClipZap відкритий одразу, WatchBox і LiveWave розблоковуються
-- пізніше за підписниками) і механіка запису відео в ClipZap: під час зйомки
-- камера випадково обирає один із 3 ракурсів (селфі/оберт навколо/знизу), а
-- персонаж — одну з 7 стандартних емоцій Roblox, і на екрані з'являється
-- REC-індикатор — щоб виглядало так, ніби гравець реально знімає контент, і
-- щоб відео не здавались однотипними. За відео капають лайки -> підписники +
-- гроші (кожні 10 лайків = $1).
--
-- ClipZap відкривається профілем каналу: аватарка (справжній аватар гравця
-- Roblox), нікнейм, який гравець вписує сам при ПЕРШОМУ відкритті ClipZap
-- (і більше не питається — той самий нік потім "переноситься" й на WatchBox/
-- LiveWave), і статистика (лайки/підписники/відео).
--
-- ПРИМІТКА: усі тексти, які бачить гравець, англійською (стандартне правило
-- проєкту від Illia). Коментарі лишаються українською.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PhoneConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PhoneConfig"))
local Economy = PhoneConfig.Economy

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local recordVideoRequest = remotes:WaitForChild("RecordVideoRequest") :: RemoteEvent
local recordVideoResult = remotes:WaitForChild("RecordVideoResult") :: RemoteEvent

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui
local leaderstats = LocalPlayer:WaitForChild("leaderstats")
local followersStat = leaderstats:WaitForChild("Followers") :: IntValue
local moneyStat = leaderstats:WaitForChild("Money") :: IntValue

-- Профільна статистика каналу (окрема папка, не leaderstats, щоб не
-- засмічувати стандартний Roblox-лідерборд зайвими колонками).
local channelStats = LocalPlayer:WaitForChild("ChannelStats")
local totalLikesStat = channelStats:WaitForChild("TotalLikes") :: IntValue
local videoCountStat = channelStats:WaitForChild("VideoCount") :: IntValue

-- ============================================================
-- Стан
-- ============================================================
local phoneOpen = false
local isAnimating = false
local recording = false
local cooldownUntil = 0

-- Нікнейм каналу — гравець вписує його сам при першому відкритті ClipZap,
-- і той самий нік потім використовується і в WatchBox, і в LiveWave.
-- Зберігається лише локально на клієнті (не надсилається на сервер і не
-- видно іншим гравцям), тому фільтрація чату (TextService) тут не потрібна.
local channelNickname: string? = nil

local showPage: (string) -> ()
local refreshStats: () -> ()
local refreshClipZapView: () -> ()
local rebuildVideoGrid: () -> ()
local recordButton: TextButton
local recordStatusLabel: TextLabel
local avatarImage: ImageLabel
local nicknameLabel: TextLabel
local likesStatLabel: TextLabel
local channelFollowersLabel: TextLabel
local videosStatLabel: TextLabel
local nicknameSetupFrame: Frame
local channelContent: Frame
local nicknameBox: TextBox
local setupError: TextLabel
local videoGrid: ScrollingFrame
local lastRenderedVideoCount = -1

-- Сторінки WatchBox/LiveWave підписуються сюди, щоб дізнатись, коли гравець
-- нарешті вписав нік у ClipZap, і оновити свій "@нік перенесеться" напис.
local nicknameWatchers: { () -> () } = {}

-- Аватарка каналу — беремо справжній аватар гравця Roblox (офіційний API,
-- жодного підбору asset-ID). Запускаємо запит одразу, а не чекаємо, поки
-- гравець відкриє ClipZap, щоб на момент відкриття картинка вже була готова.
local avatarContent = ""
task.spawn(function()
	local ok, content = pcall(function()
		return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
	end)
	if ok and content then
		avatarContent = content
		if avatarImage then
			avatarImage.Image = content
		end
	end
end)

-- ============================================================
-- Корінь GUI
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PhoneGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

-- ============================================================
-- Вступний тост при спавні — на 1 сесію, ненав'язливий, зникає сам
-- ============================================================
local introToast = Instance.new("TextLabel")
introToast.Name = "IntroToast"
introToast.Size = UDim2.new(0, 380, 0, 54)
introToast.AnchorPoint = Vector2.new(0.5, 0)
introToast.Position = UDim2.new(0.5, 0, 0, 22)
introToast.BackgroundColor3 = Color3.fromRGB(16, 18, 24)
introToast.BorderSizePixel = 0
introToast.Font = Enum.Font.Gotham
introToast.TextSize = 14
introToast.TextWrapped = true
introToast.TextColor3 = Color3.fromRGB(230, 233, 240)
introToast.TextTransparency = 1
introToast.BackgroundTransparency = 1
introToast.Text = "You woke up at the scrapyard without a penny. Time to film videos on ClipZap and become a star! 🎬"
introToast.Parent = screenGui
local introCorner = Instance.new("UICorner")
introCorner.CornerRadius = UDim.new(0, 14)
introCorner.Parent = introToast

task.spawn(function()
	task.wait(1.2)
	TweenService:Create(introToast, TweenInfo.new(0.5), { TextTransparency = 0, BackgroundTransparency = 0.15 }):Play()
	task.wait(6.5)
	TweenService:Create(introToast, TweenInfo.new(0.6), { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
end)

-- ============================================================
-- Підказка: "▲ Take out phone" — маленька, приємна, клікабельна, в
-- нижньому правому куті (там-таки, звідки виїжджає сам телефон)
-- ============================================================
local hintButton = Instance.new("TextButton")
hintButton.Name = "PhoneHint"
hintButton.Size = UDim2.new(0, 190, 0, 40)
hintButton.AnchorPoint = Vector2.new(1, 1)
hintButton.Position = UDim2.new(1, -20, 1, -26)
hintButton.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
hintButton.BackgroundTransparency = 0.28
hintButton.BorderSizePixel = 0
hintButton.AutoButtonColor = false
hintButton.Text = ""
hintButton.Parent = screenGui

local hintCorner = Instance.new("UICorner")
hintCorner.CornerRadius = UDim.new(1, 0)
hintCorner.Parent = hintButton

local hintStroke = Instance.new("UIStroke")
hintStroke.Color = Color3.fromRGB(255, 255, 255)
hintStroke.Transparency = 0.75
hintStroke.Thickness = 1
hintStroke.Parent = hintButton

-- Раніше тут була стрілка "▲" (стрілка вверх), але саму стрілку вверх Roblox
-- за замовчуванням перехоплює як клавішу руху персонажа (аналог W) — тобто
-- UserInputService бачить її як "gameProcessed = true" і наш обробник нижче
-- її просто ігнорував. Тому підказку й сам бінд перенесли на клавішу "P",
-- яка нічим стандартним не зайнята. Малюємо її як маленьку "клавішу-кнопку".
local hintArrow = Instance.new("TextLabel")
hintArrow.Name = "KeyBadge"
hintArrow.AnchorPoint = Vector2.new(0, 0.5)
hintArrow.Position = UDim2.new(0, 14, 0.5, 0)
hintArrow.Size = UDim2.new(0, 22, 0, 22)
hintArrow.BackgroundColor3 = Color3.fromRGB(120, 210, 255)
hintArrow.BackgroundTransparency = 0.05
hintArrow.BorderSizePixel = 0
hintArrow.Font = Enum.Font.GothamBold
hintArrow.Text = "P"
hintArrow.TextSize = 15
hintArrow.TextColor3 = Color3.fromRGB(14, 16, 22)
hintArrow.Parent = hintButton

local hintArrowCorner = Instance.new("UICorner")
hintArrowCorner.CornerRadius = UDim.new(0, 6)
hintArrowCorner.Parent = hintArrow

local hintText = Instance.new("TextLabel")
hintText.Name = "Label"
hintText.AnchorPoint = Vector2.new(0, 0.5)
hintText.Position = UDim2.new(0, 46, 0.5, 0)
hintText.Size = UDim2.new(0, 140, 0, 20)
hintText.BackgroundTransparency = 1
hintText.Font = Enum.Font.Gotham
hintText.Text = "Take out phone"
hintText.TextSize = 14
hintText.TextColor3 = Color3.fromRGB(235, 238, 245)
hintText.TextXAlignment = Enum.TextXAlignment.Left
hintText.Parent = hintButton

-- Легка пульсація значка клавіші — привертає погляд, але не дратує
task.spawn(function()
	while hintArrow.Parent do
		local up = TweenService:Create(hintArrow, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Position = UDim2.new(0, 14, 0.5, -4) })
		local down = TweenService:Create(hintArrow, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Position = UDim2.new(0, 14, 0.5, 0) })
		up:Play()
		up.Completed:Wait()
		down:Play()
		down.Completed:Wait()
		task.wait(0.5)
	end
end)

-- ============================================================
-- REC-індикатор і червона рамка — з'являються під час зйомки, щоб було
-- видно, що персонаж реально щось знімає (Illia попросив саме це)
-- ============================================================
local recHud = Instance.new("Frame")
recHud.Name = "RecordingHud"
recHud.Size = UDim2.new(0, 130, 0, 38)
recHud.AnchorPoint = Vector2.new(0.5, 0)
recHud.Position = UDim2.new(0.5, 0, 0, 22)
recHud.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
recHud.BackgroundTransparency = 0.2
recHud.BorderSizePixel = 0
recHud.Visible = false
recHud.Parent = screenGui
local recHudCorner = Instance.new("UICorner")
recHudCorner.CornerRadius = UDim.new(1, 0)
recHudCorner.Parent = recHud

local recDot = Instance.new("Frame")
recDot.Name = "Dot"
recDot.AnchorPoint = Vector2.new(0, 0.5)
recDot.Position = UDim2.new(0, 14, 0.5, 0)
recDot.Size = UDim2.new(0, 12, 0, 12)
recDot.BackgroundColor3 = Color3.fromRGB(255, 45, 60)
recDot.BorderSizePixel = 0
recDot.Parent = recHud
local recDotCorner = Instance.new("UICorner")
recDotCorner.CornerRadius = UDim.new(1, 0)
recDotCorner.Parent = recDot

local recLabel = Instance.new("TextLabel")
recLabel.Name = "Label"
recLabel.AnchorPoint = Vector2.new(0, 0.5)
recLabel.Position = UDim2.new(0, 34, 0.5, 0)
recLabel.Size = UDim2.new(0, 90, 0, 22)
recLabel.BackgroundTransparency = 1
recLabel.Font = Enum.Font.GothamBold
recLabel.TextSize = 14
recLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
recLabel.TextXAlignment = Enum.TextXAlignment.Left
recLabel.Text = "REC"
recLabel.Parent = recHud

-- Тонка пульсуюча червона рамка по краях екрана — легкий "camera app" вайб
local recBorder = Instance.new("Frame")
recBorder.Name = "RecordingBorder"
recBorder.Size = UDim2.new(1, 0, 1, 0)
recBorder.BackgroundTransparency = 1
recBorder.Visible = false
recBorder.Parent = screenGui
local recBorderStroke = Instance.new("UIStroke")
recBorderStroke.Color = Color3.fromRGB(255, 40, 60)
recBorderStroke.Thickness = 4
recBorderStroke.Transparency = 0.4
recBorderStroke.Parent = recBorder

local recDotPulseRunning = false
local function startRecDotPulse()
	if recDotPulseRunning then
		return
	end
	recDotPulseRunning = true
	task.spawn(function()
		while recHud.Visible do
			local fadeOut = TweenService:Create(recDot, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { BackgroundTransparency = 0.75 })
			fadeOut:Play()
			fadeOut.Completed:Wait()
			if not recHud.Visible then
				break
			end
			local fadeIn = TweenService:Create(recDot, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { BackgroundTransparency = 0 })
			fadeIn:Play()
			fadeIn.Completed:Wait()
		end
		recDot.BackgroundTransparency = 0
		recDotPulseRunning = false
	end)
end

-- ============================================================
-- Камера + анімація персонажа під час зйомки відео. Illia попросив
-- різноманіття, щоб відео не здавались однотипними — тому тут і набір із
-- 7 РІЗНИХ стандартних емоцій Roblox (не тільки танці), і 3 РІЗНІ ракурси
-- камери, обидва обираються випадково щоразу -> 21 унікальна комбінація.
--
-- Свідомо використовуємо ТІЛЬКИ Humanoid:PlayEmote() з іменами, які вже
-- зареєстровані в стандартному Animate-скрипті будь-якого персонажа Roblox
-- за замовчуванням (а не жорстко вбиті AnimationId) — це гарантовано existing
-- і безпечно, без ризику "не той asset" (як було раніше з підбором звуку
-- для гіроскутера в цьому ж проєкті).
-- ============================================================
local ACTION_EMOTES = { "dance1", "dance2", "dance3", "wave", "point", "laugh", "cheer" }
local CAMERA_STYLES = { "selfie", "orbit", "lowAngle" }

local cameraConnection: RBXScriptConnection? = nil
local activeEmoteTrack: AnimationTrack? = nil
local originalCameraType: Enum.CameraType? = nil
local recordingHumanoid: Humanoid? = nil
local savedWalkSpeed: number? = nil

-- Рахує CFrame камери для обраного ракурсу; progress іде 0 -> 1 протягом
-- усієї зйомки (потрібен для "orbit", який плавно облітає персонажа).
local function computeCameraCFrame(style: string, head: BasePart, hrp: BasePart, progress: number): CFrame
	local lookVector = hrp.CFrame.LookVector
	if style == "orbit" then
		-- Камера оператора, що повільно облітає персонажа по колу.
		local angle = math.rad(progress * 200 - 40)
		local radius = 9
		local orbitOffset = Vector3.new(math.cos(angle) * radius, 2.6, math.sin(angle) * radius)
		local camPos = hrp.Position + orbitOffset
		return CFrame.lookAt(camPos, head.Position)
	elseif style == "lowAngle" then
		-- Драматичний нижній ракурс, як у кліпах — камера знизу-спереду.
		local camPos = head.Position + lookVector * 5 - Vector3.new(0, 2.6, 0)
		return CFrame.lookAt(camPos, head.Position + Vector3.new(0, 0.6, 0))
	else
		-- "selfie": камера висить попереду персонажа й дивиться назад —
		-- класичний ракурс "зняв себе на телефон".
		local camPos = head.Position + lookVector * 6 + Vector3.new(0, 1.1, 0)
		local focusPos = head.Position + Vector3.new(0, 0.2, 0)
		return CFrame.lookAt(camPos, focusPos)
	end
end

local function startRecordingCamera(recordSeconds: number)
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local head = character and character:FindFirstChild("Head") :: BasePart?
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not (character and humanoid and head and hrp) then
		return
	end

	-- Illia сказав, що бачив тільки зміну кута камери, а сам персонаж
	-- виглядав так, ніби нічого не робить. Причина: деякі стандартні емоції
	-- (wave/point/laugh/cheer) — короткі, одноразові, і завершуються ще ДО
	-- кінця 4-секундного запису, тому персонаж встигав повернутись у Idle
	-- посеред зйомки. Фікс: примусово ставимо track.Looped = true одразу
	-- після старту — тоді емоція просто повторюється по колу аж до самого
	-- :Stop() у stopRecordingCamera(), і рух видно ввесь час запису.
	local emoteName = ACTION_EMOTES[math.random(1, #ACTION_EMOTES)]
	local ok, track = pcall(function()
		return (humanoid :: Humanoid):PlayEmote(emoteName)
	end)
	if ok and track then
		local realTrack = track :: AnimationTrack
		realTrack.Looped = true
		activeEmoteTrack = realTrack
	end

	-- Також фіксуємо швидкість ходьби на 0 на час зйомки — інакше гравець
	-- може піти вбік і "затерти" анімацію емоції рухом, і виглядатиме так,
	-- ніби персонаж узагалі нічого не робить.
	-- (Окрема локальна змінна тут ще й рятує від класичної Luau-пастки:
	-- рядок, що починається з "(", інакше "приклеївся" б до попереднього
	-- виразу як виклик функції — SyntaxError "ambiguous syntax".)
	local humanoidRef = humanoid :: Humanoid
	recordingHumanoid = humanoidRef
	savedWalkSpeed = humanoidRef.WalkSpeed
	humanoidRef.WalkSpeed = 0

	local cameraStyle = CAMERA_STYLES[math.random(1, #CAMERA_STYLES)]
	local startClock = os.clock()

	local camera = workspace.CurrentCamera
	if camera then
		originalCameraType = camera.CameraType
		camera.CameraType = Enum.CameraType.Scriptable
		cameraConnection = RunService.RenderStepped:Connect(function()
			if not (head.Parent and hrp.Parent) then
				return
			end
			local progress = math.clamp((os.clock() - startClock) / recordSeconds, 0, 1)
			camera.CFrame = computeCameraCFrame(cameraStyle, head, hrp, progress)
		end)
	end
end

local function stopRecordingCamera()
	if cameraConnection then
		cameraConnection:Disconnect()
		cameraConnection = nil
	end
	local camera = workspace.CurrentCamera
	if camera and originalCameraType then
		camera.CameraType = originalCameraType
	end
	originalCameraType = nil
	if activeEmoteTrack then
		activeEmoteTrack:Stop(0.3)
		activeEmoteTrack = nil
	end
	if recordingHumanoid and savedWalkSpeed then
		recordingHumanoid.WalkSpeed = savedWalkSpeed
	end
	recordingHumanoid = nil
	savedWalkSpeed = nil
end

-- ============================================================
-- Сам телефон — тепер живе з ПРАВОГО боку екрана (не закриває вид на
-- персонажа під час зйомки), а не по центру на весь екран
-- ============================================================
local PHONE_OPEN_POSITION = UDim2.new(1, -14, 0.5, 0)
local PHONE_CLOSED_POSITION = UDim2.new(1, 300, 0.5, 0)

local phoneFrame = Instance.new("Frame")
phoneFrame.Name = "Phone"
phoneFrame.Size = UDim2.new(0, 260, 0, 440)
phoneFrame.AnchorPoint = Vector2.new(1, 0.5)
phoneFrame.Position = PHONE_CLOSED_POSITION -- за межами екрана справа
phoneFrame.BackgroundColor3 = Color3.fromRGB(14, 15, 20)
phoneFrame.BorderSizePixel = 0
phoneFrame.Visible = false
phoneFrame.Parent = screenGui

local phoneCorner = Instance.new("UICorner")
phoneCorner.CornerRadius = UDim.new(0, 32)
phoneCorner.Parent = phoneFrame

local phoneStroke = Instance.new("UIStroke")
phoneStroke.Color = Color3.fromRGB(70, 75, 90)
phoneStroke.Thickness = 3
phoneStroke.Parent = phoneFrame

local notch = Instance.new("Frame")
notch.Name = "Notch"
notch.Size = UDim2.new(0, 90, 0, 16)
notch.AnchorPoint = Vector2.new(0.5, 0)
notch.Position = UDim2.new(0.5, 0, 0, 9)
notch.BackgroundColor3 = Color3.fromRGB(6, 6, 9)
notch.BorderSizePixel = 0
notch.ZIndex = 5
notch.Parent = phoneFrame
local notchCorner = Instance.new("UICorner")
notchCorner.CornerRadius = UDim.new(1, 0)
notchCorner.Parent = notch

local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -10, 0, 8)
closeButton.BackgroundColor3 = Color3.fromRGB(32, 34, 44)
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "✕"
closeButton.TextSize = 14
closeButton.TextColor3 = Color3.fromRGB(220, 222, 230)
closeButton.ZIndex = 6
closeButton.Parent = phoneFrame
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1, 0)
closeCorner.Parent = closeButton

local screen = Instance.new("Frame")
screen.Name = "Screen"
screen.Size = UDim2.new(1, -18, 1, -46)
screen.Position = UDim2.new(0, 9, 0, 36)
screen.BackgroundColor3 = Color3.fromRGB(24, 26, 34)
screen.BorderSizePixel = 0
screen.ClipsDescendants = true
screen.Parent = phoneFrame
local screenCorner = Instance.new("UICorner")
screenCorner.CornerRadius = UDim.new(0, 24)
screenCorner.Parent = screen

-- ============================================================
-- Сторінки всередині екрана
-- ============================================================
local pages: { [string]: Frame } = {}

showPage = function(id: string)
	for pageId, page in pages do
		page.Visible = (pageId == id)
	end
end

-- ---- Домашня сторінка ----
local homePage = Instance.new("Frame")
homePage.Name = "Home"
homePage.Size = UDim2.new(1, 0, 1, 0)
homePage.BackgroundTransparency = 1
homePage.Parent = screen
pages["home"] = homePage

local statsBar = Instance.new("Frame")
statsBar.Size = UDim2.new(1, -20, 0, 40)
statsBar.Position = UDim2.new(0, 10, 0, 12)
statsBar.BackgroundColor3 = Color3.fromRGB(30, 32, 42)
statsBar.BorderSizePixel = 0
statsBar.Parent = homePage
local statsCorner = Instance.new("UICorner")
statsCorner.CornerRadius = UDim.new(0, 14)
statsCorner.Parent = statsBar

local statsFollowersLabel = Instance.new("TextLabel")
statsFollowersLabel.Size = UDim2.new(0.5, 0, 1, 0)
statsFollowersLabel.BackgroundTransparency = 1
statsFollowersLabel.Font = Enum.Font.GothamBold
statsFollowersLabel.TextSize = 15
statsFollowersLabel.TextColor3 = Color3.fromRGB(120, 210, 255)
statsFollowersLabel.Text = "👥 0"
statsFollowersLabel.Parent = statsBar

local statsMoneyLabel = Instance.new("TextLabel")
statsMoneyLabel.Size = UDim2.new(0.5, 0, 1, 0)
statsMoneyLabel.Position = UDim2.new(0.5, 0, 0, 0)
statsMoneyLabel.BackgroundTransparency = 1
statsMoneyLabel.Font = Enum.Font.GothamBold
statsMoneyLabel.TextSize = 15
statsMoneyLabel.TextColor3 = Color3.fromRGB(120, 255, 160)
statsMoneyLabel.Text = "💵 $0"
statsMoneyLabel.Parent = statsBar

local homeTitle = Instance.new("TextLabel")
homeTitle.Size = UDim2.new(1, -20, 0, 20)
homeTitle.Position = UDim2.new(0, 10, 0, 62)
homeTitle.BackgroundTransparency = 1
homeTitle.Font = Enum.Font.Gotham
homeTitle.TextSize = 13
homeTitle.TextColor3 = Color3.fromRGB(160, 164, 176)
homeTitle.TextXAlignment = Enum.TextXAlignment.Left
homeTitle.Text = "Apps"
homeTitle.Parent = homePage

local appsRow = Instance.new("Frame")
appsRow.Size = UDim2.new(1, -20, 0, 90)
appsRow.Position = UDim2.new(0, 10, 0, 90)
appsRow.BackgroundTransparency = 1
appsRow.Parent = homePage
local appsLayout = Instance.new("UIListLayout")
appsLayout.FillDirection = Enum.FillDirection.Horizontal
appsLayout.Padding = UDim.new(0, 12)
appsLayout.Parent = appsRow

local appButtons: { [string]: { Button: TextButton, LockOverlay: Frame } } = {}

local function isAppUnlocked(app: PhoneConfig.AppConfig): boolean
	return followersStat.Value >= app.UnlockFollowers
end

local function buildAppIcon(app: PhoneConfig.AppConfig, layoutOrder: number)
	local btn = Instance.new("TextButton")
	btn.Name = app.Id
	btn.Size = UDim2.new(0, 72, 0, 88)
	btn.BackgroundColor3 = Color3.fromRGB(32, 34, 44)
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = true
	btn.Text = ""
	btn.LayoutOrder = layoutOrder
	btn.Parent = appsRow
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 18)
	corner.Parent = btn

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(1, 0, 0, 44)
	iconLabel.Position = UDim2.new(0, 0, 0, 8)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.Text = app.Icon
	iconLabel.TextSize = 30
	iconLabel.Parent = btn

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -6, 0, 18)
	nameLabel.Position = UDim2.new(0, 3, 0, 56)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextSize = 11
	nameLabel.TextColor3 = Color3.fromRGB(220, 222, 230)
	nameLabel.Text = app.DisplayName
	nameLabel.Parent = btn

	local accentBar = Instance.new("Frame")
	accentBar.Size = UDim2.new(1, -16, 0, 4)
	accentBar.Position = UDim2.new(0, 8, 1, -8)
	accentBar.BackgroundColor3 = app.AccentColor
	accentBar.BorderSizePixel = 0
	accentBar.Parent = btn
	local accentCorner = Instance.new("UICorner")
	accentCorner.CornerRadius = UDim.new(1, 0)
	accentCorner.Parent = accentBar

	local lockOverlay = Instance.new("Frame")
	lockOverlay.Name = "LockOverlay"
	lockOverlay.Size = UDim2.new(1, 0, 1, 0)
	lockOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	lockOverlay.BackgroundTransparency = 0.35
	lockOverlay.BorderSizePixel = 0
	lockOverlay.Visible = app.UnlockFollowers > 0
	lockOverlay.ZIndex = 3
	lockOverlay.Parent = btn
	local lockCorner = Instance.new("UICorner")
	lockCorner.CornerRadius = UDim.new(0, 18)
	lockCorner.Parent = lockOverlay

	local lockIcon = Instance.new("TextLabel")
	lockIcon.Size = UDim2.new(1, 0, 0, 26)
	lockIcon.Position = UDim2.new(0, 0, 0, 2)
	lockIcon.BackgroundTransparency = 1
	lockIcon.Font = Enum.Font.GothamBold
	lockIcon.Text = "🔒"
	lockIcon.TextSize = 18
	lockIcon.ZIndex = 4
	lockIcon.Parent = lockOverlay

	local lockText = Instance.new("TextLabel")
	lockText.Size = UDim2.new(1, -6, 0, 40)
	lockText.Position = UDim2.new(0, 3, 0, 28)
	lockText.BackgroundTransparency = 1
	lockText.Font = Enum.Font.Gotham
	lockText.TextSize = 9
	lockText.TextWrapped = true
	lockText.TextColor3 = Color3.fromRGB(230, 230, 235)
	lockText.Text = `{app.UnlockFollowers}+ followers`
	lockText.ZIndex = 4
	lockText.Parent = lockOverlay

	btn.MouseButton1Click:Connect(function()
		if isAppUnlocked(app) then
			showPage(app.Id)
		else
			local basePos = btn.Position
			local shake = TweenService:Create(
				btn,
				TweenInfo.new(0.05, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 3, true),
				{ Position = basePos + UDim2.new(0, 5, 0, 0) }
			)
			shake:Play()
		end
	end)

	appButtons[app.Id] = { Button = btn, LockOverlay = lockOverlay }
end

local function refreshLockedApps()
	for _, app in PhoneConfig.Apps do
		local entry = appButtons[app.Id]
		if entry then
			entry.LockOverlay.Visible = not isAppUnlocked(app)
		end
	end
end

-- ---- Спільний заголовок з кнопкою "назад" для сторінок застосунків ----
local function buildBackHeader(parent: Frame, titleText: string)
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 46)
	header.BackgroundTransparency = 1
	header.Parent = parent

	local backBtn = Instance.new("TextButton")
	backBtn.Size = UDim2.new(0, 34, 0, 34)
	backBtn.Position = UDim2.new(0, 8, 0, 6)
	backBtn.BackgroundColor3 = Color3.fromRGB(32, 34, 44)
	backBtn.BorderSizePixel = 0
	backBtn.Font = Enum.Font.GothamBold
	backBtn.Text = "←"
	backBtn.TextSize = 18
	backBtn.TextColor3 = Color3.fromRGB(230, 230, 235)
	backBtn.Parent = header
	local backCorner = Instance.new("UICorner")
	backCorner.CornerRadius = UDim.new(1, 0)
	backCorner.Parent = backBtn
	backBtn.MouseButton1Click:Connect(function()
		showPage("home")
	end)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -100, 0, 34)
	titleLabel.Position = UDim2.new(0, 50, 0, 6)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 16
	titleLabel.TextColor3 = Color3.fromRGB(235, 238, 245)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Text = titleText
	titleLabel.Parent = header
end

-- ---- Сторінка ClipZap: запис відео (з різноманітними камерою й анімацією) ----
local function startRecording()
	if recording then
		return
	end
	if os.clock() < cooldownUntil then
		return
	end
	recording = true
	recordButton.AutoButtonColor = false

	recHud.Visible = true
	recBorder.Visible = true
	startRecDotPulse()
	startRecordingCamera(Economy.RecordSeconds)

	-- Кнопка запису тепер маленька (60x60) — довгий текст туди не влізе,
	-- тому на самій кнопці лишаємо тільки цифру/іконку, а опис ("Filming...",
	-- "Uploading...") показуємо в окремому тонкому рядку recordStatusLabel.
	recordStatusLabel.Text = "⏺ Filming..."
	task.spawn(function()
		for i = Economy.RecordSeconds, 1, -1 do
			recordButton.Text = `{i}`
			recLabel.Text = `REC {i}s`
			recordStatusLabel.Text = `⏺ Filming... {i}s`
			task.wait(1)
		end
		recordButton.Text = "📤"
		recLabel.Text = "UPLOADING"
		recordStatusLabel.Text = "Waiting for the audience's reaction..."
		recordVideoRequest:FireServer()
	end)
end

-- Скільки символів максимум приймаємо в нікнейм каналу (просто розумний
-- ліміт для верстки, не пов'язано з жодним зовнішнім правилом).
local MAX_NICKNAME_LENGTH = 20

local function buildClipZapPage(app: PhoneConfig.AppConfig)
	local page = Instance.new("Frame")
	page.Name = app.Id
	page.Size = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency = 1
	page.Visible = false
	page.Parent = screen
	buildBackHeader(page, `{app.Icon} {app.DisplayName}`)

	-- ---- Стан 1: вибір нікнейму (показується, поки channelNickname == nil) ----
	nicknameSetupFrame = Instance.new("Frame")
	nicknameSetupFrame.Name = "NicknameSetup"
	nicknameSetupFrame.Size = UDim2.new(1, -20, 1, -56)
	nicknameSetupFrame.Position = UDim2.new(0, 10, 0, 52)
	nicknameSetupFrame.BackgroundTransparency = 1
	nicknameSetupFrame.Visible = true
	nicknameSetupFrame.Parent = page

	local setupIcon = Instance.new("TextLabel")
	setupIcon.Size = UDim2.new(1, 0, 0, 40)
	setupIcon.BackgroundTransparency = 1
	setupIcon.Font = Enum.Font.GothamBold
	setupIcon.TextSize = 32
	setupIcon.Text = app.Icon
	setupIcon.Parent = nicknameSetupFrame

	local setupTitle = Instance.new("TextLabel")
	setupTitle.Size = UDim2.new(1, 0, 0, 46)
	setupTitle.Position = UDim2.new(0, 0, 0, 46)
	setupTitle.BackgroundTransparency = 1
	setupTitle.Font = Enum.Font.GothamBold
	setupTitle.TextSize = 15
	setupTitle.TextWrapped = true
	setupTitle.TextColor3 = Color3.fromRGB(235, 238, 245)
	setupTitle.Text = "Choose your creator name to get started!"
	setupTitle.Parent = nicknameSetupFrame

	nicknameBox = Instance.new("TextBox")
	nicknameBox.Size = UDim2.new(1, 0, 0, 40)
	nicknameBox.Position = UDim2.new(0, 0, 0, 100)
	nicknameBox.BackgroundColor3 = Color3.fromRGB(32, 34, 44)
	nicknameBox.BorderSizePixel = 0
	nicknameBox.Font = Enum.Font.Gotham
	nicknameBox.TextSize = 14
	nicknameBox.TextColor3 = Color3.fromRGB(235, 238, 245)
	nicknameBox.PlaceholderText = "e.g. SkyDancer99"
	nicknameBox.PlaceholderColor3 = Color3.fromRGB(130, 134, 146)
	nicknameBox.Text = ""
	nicknameBox.ClearTextOnFocus = false
	nicknameBox.Parent = nicknameSetupFrame
	local nicknameBoxCorner = Instance.new("UICorner")
	nicknameBoxCorner.CornerRadius = UDim.new(0, 12)
	nicknameBoxCorner.Parent = nicknameBox

	setupError = Instance.new("TextLabel")
	setupError.Size = UDim2.new(1, 0, 0, 20)
	setupError.Position = UDim2.new(0, 0, 0, 144)
	setupError.BackgroundTransparency = 1
	setupError.Font = Enum.Font.Gotham
	setupError.TextSize = 12
	setupError.TextColor3 = Color3.fromRGB(255, 130, 130)
	setupError.Text = ""
	setupError.Parent = nicknameSetupFrame

	local confirmButton = Instance.new("TextButton")
	confirmButton.Size = UDim2.new(1, 0, 0, 42)
	confirmButton.Position = UDim2.new(0, 0, 0, 172)
	confirmButton.BackgroundColor3 = app.AccentColor
	confirmButton.BorderSizePixel = 0
	confirmButton.Font = Enum.Font.GothamBold
	confirmButton.TextSize = 15
	confirmButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	confirmButton.Text = "✅ Confirm"
	confirmButton.Parent = nicknameSetupFrame
	local confirmCorner = Instance.new("UICorner")
	confirmCorner.CornerRadius = UDim.new(0, 14)
	confirmCorner.Parent = confirmButton

	local function trySetNickname()
		local trimmed = nicknameBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
		if trimmed == "" then
			setupError.Text = "Please enter a name first!"
			return
		end
		if #trimmed > MAX_NICKNAME_LENGTH then
			trimmed = trimmed:sub(1, MAX_NICKNAME_LENGTH)
		end
		channelNickname = trimmed
		setupError.Text = ""
		refreshClipZapView()
		for _, watcher in nicknameWatchers do
			watcher()
		end
	end

	confirmButton.MouseButton1Click:Connect(trySetNickname)
	nicknameBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			trySetNickname()
		end
	end)

	-- ---- Стан 2: сам канал — профіль + статистика + запис відео ----
	channelContent = Instance.new("Frame")
	channelContent.Name = "ChannelContent"
	channelContent.Size = UDim2.new(1, 0, 1, -46)
	channelContent.Position = UDim2.new(0, 0, 0, 46)
	channelContent.BackgroundTransparency = 1
	channelContent.Visible = false
	channelContent.Parent = page

	local profileHeader = Instance.new("Frame")
	profileHeader.Size = UDim2.new(1, -20, 0, 62)
	profileHeader.Position = UDim2.new(0, 10, 0, 4)
	profileHeader.BackgroundTransparency = 1
	profileHeader.Parent = channelContent

	avatarImage = Instance.new("ImageLabel")
	avatarImage.Size = UDim2.new(0, 56, 0, 56)
	avatarImage.Position = UDim2.new(0, 0, 0, 2)
	avatarImage.BackgroundColor3 = Color3.fromRGB(40, 42, 54)
	avatarImage.BorderSizePixel = 0
	avatarImage.Image = avatarContent
	avatarImage.Parent = profileHeader
	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = UDim.new(1, 0)
	avatarCorner.Parent = avatarImage
	local avatarStroke = Instance.new("UIStroke")
	avatarStroke.Color = app.AccentColor
	avatarStroke.Thickness = 2
	avatarStroke.Parent = avatarImage

	nicknameLabel = Instance.new("TextLabel")
	nicknameLabel.Size = UDim2.new(1, -68, 0, 24)
	nicknameLabel.Position = UDim2.new(0, 68, 0, 8)
	nicknameLabel.BackgroundTransparency = 1
	nicknameLabel.Font = Enum.Font.GothamBold
	nicknameLabel.TextSize = 16
	nicknameLabel.TextColor3 = Color3.fromRGB(235, 238, 245)
	nicknameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nicknameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nicknameLabel.Text = "@creator"
	nicknameLabel.Parent = profileHeader

	local editNicknameButton = Instance.new("TextButton")
	editNicknameButton.Size = UDim2.new(0, 80, 0, 18)
	editNicknameButton.Position = UDim2.new(0, 68, 0, 34)
	editNicknameButton.BackgroundTransparency = 1
	editNicknameButton.Font = Enum.Font.Gotham
	editNicknameButton.TextSize = 11
	editNicknameButton.TextColor3 = Color3.fromRGB(150, 200, 255)
	editNicknameButton.TextXAlignment = Enum.TextXAlignment.Left
	editNicknameButton.Text = "✏️ Edit name"
	editNicknameButton.Parent = profileHeader
	editNicknameButton.MouseButton1Click:Connect(function()
		nicknameBox.Text = channelNickname or ""
		setupError.Text = ""
		channelContent.Visible = false
		nicknameSetupFrame.Visible = true
	end)

	local statsRow = Instance.new("Frame")
	statsRow.Size = UDim2.new(1, -20, 0, 38)
	statsRow.Position = UDim2.new(0, 10, 0, 72)
	statsRow.BackgroundTransparency = 1
	statsRow.Parent = channelContent
	-- ЗНАЙДЕНИЙ СПРАВЖНІЙ БАГ (не клавіша!): "SpaceEvenly" — це значення
	-- Enum.UIFlexAlignment і належить властивості HorizontalFlex, а НЕ
	-- Enum.HorizontalAlignment (у якого є лише Left/Center/Right). Стара
	-- версія коду присвоювала неіснуюче значення властивості
	-- HorizontalAlignment — у справжньому Roblox це кидає помилку одразу
	-- при побудові сторінки ClipZap (яка виконується ще на старті скрипта,
	-- в циклі build всіх сторінок), тож ВЕСЬ LocalScript зупинявся на цьому
	-- рядку — і підключення клавіші/кліку внизу файлу просто ніколи не
	-- виконувались. Ось чому ні "P", ні клік мишкою не працювали, хоча
	-- підказка (яка будується РАНІШЕ за цей рядок) — з'являлась нормально.
	local statsLayout = Instance.new("UIListLayout")
	statsLayout.FillDirection = Enum.FillDirection.Horizontal
	statsLayout.HorizontalFlex = Enum.UIFlexAlignment.SpaceEvenly
	statsLayout.Parent = statsRow

	local function buildStatCell(caption: string): TextLabel
		local cell = Instance.new("Frame")
		cell.Size = UDim2.new(0, 68, 1, 0)
		cell.BackgroundTransparency = 1
		cell.Parent = statsRow

		local valueLabel = Instance.new("TextLabel")
		valueLabel.Size = UDim2.new(1, 0, 0, 20)
		valueLabel.BackgroundTransparency = 1
		valueLabel.Font = Enum.Font.GothamBold
		valueLabel.TextSize = 14
		valueLabel.TextColor3 = Color3.fromRGB(235, 238, 245)
		valueLabel.Text = "0"
		valueLabel.Parent = cell

		local captionLabel = Instance.new("TextLabel")
		captionLabel.Size = UDim2.new(1, 0, 0, 16)
		captionLabel.Position = UDim2.new(0, 0, 0, 20)
		captionLabel.BackgroundTransparency = 1
		captionLabel.Font = Enum.Font.Gotham
		captionLabel.TextSize = 10
		captionLabel.TextColor3 = Color3.fromRGB(160, 164, 176)
		captionLabel.Text = caption
		captionLabel.Parent = cell

		return valueLabel
	end

	likesStatLabel = buildStatCell("❤️ Likes")
	channelFollowersLabel = buildStatCell("👥 Followers")
	videosStatLabel = buildStatCell("🎬 Videos")

	-- Короткий рядок статусу (був частиною великої кнопки запису, тепер
	-- кнопка маленька — тому статус живе окремим тонким написом зверху).
	recordStatusLabel = Instance.new("TextLabel")
	recordStatusLabel.Size = UDim2.new(1, -20, 0, 18)
	recordStatusLabel.Position = UDim2.new(0, 10, 0, 116)
	recordStatusLabel.BackgroundTransparency = 1
	recordStatusLabel.Font = Enum.Font.Gotham
	recordStatusLabel.TextSize = 12
	recordStatusLabel.TextTruncate = Enum.TextTruncate.AtEnd
	recordStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
	recordStatusLabel.TextColor3 = Color3.fromRGB(200, 204, 214)
	recordStatusLabel.Text = "Tap 🔴 to film a new video!"
	recordStatusLabel.Parent = channelContent

	-- Illia попросив: кнопку запису зробити МЕНШОЮ, а на тому місці, де вона
	-- була, показати ніби "стрічку" вже знятих відео (іконки-картки, скільки
	-- відео гравець уже зняв). Реальних відеофайлів немає — це умовне
	-- відображення VideoCount у вигляді карток "🎬 #N".
	local videoSectionLabel = Instance.new("TextLabel")
	videoSectionLabel.Size = UDim2.new(1, -20, 0, 16)
	videoSectionLabel.Position = UDim2.new(0, 10, 0, 138)
	videoSectionLabel.BackgroundTransparency = 1
	videoSectionLabel.Font = Enum.Font.GothamBold
	videoSectionLabel.TextSize = 11
	videoSectionLabel.TextXAlignment = Enum.TextXAlignment.Left
	videoSectionLabel.TextColor3 = Color3.fromRGB(160, 164, 176)
	videoSectionLabel.Text = "YOUR VIDEOS"
	videoSectionLabel.Parent = channelContent

	videoGrid = Instance.new("ScrollingFrame")
	videoGrid.Name = "VideoGrid"
	videoGrid.Size = UDim2.new(1, -20, 1, -158)
	videoGrid.Position = UDim2.new(0, 10, 0, 158)
	videoGrid.BackgroundTransparency = 1
	videoGrid.BorderSizePixel = 0
	videoGrid.ScrollBarThickness = 4
	videoGrid.ScrollingDirection = Enum.ScrollingDirection.Y
	videoGrid.CanvasSize = UDim2.new(0, 0, 0, 0)
	videoGrid.AutomaticCanvasSize = Enum.AutomaticSize.Y
	videoGrid.Parent = channelContent

	local videoGridLayout = Instance.new("UIGridLayout")
	videoGridLayout.CellSize = UDim2.new(0, 50, 0, 50)
	videoGridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
	videoGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	videoGridLayout.Parent = videoGrid

	-- Невеликий запас знизу-справа, щоб плаваюча кнопка запису не
	-- перекривала останній ряд карток відео.
	local videoGridPadding = Instance.new("UIPadding")
	videoGridPadding.PaddingBottom = UDim.new(0, 56)
	videoGridPadding.Parent = videoGrid

	local emptyVideosLabel = Instance.new("TextLabel")
	emptyVideosLabel.Name = "EmptyHint"
	emptyVideosLabel.Size = UDim2.new(1, 0, 0, 40)
	emptyVideosLabel.BackgroundTransparency = 1
	emptyVideosLabel.Font = Enum.Font.Gotham
	emptyVideosLabel.TextSize = 12
	emptyVideosLabel.TextWrapped = true
	emptyVideosLabel.TextColor3 = Color3.fromRGB(140, 144, 156)
	emptyVideosLabel.Text = "No videos yet — film your first one!"
	emptyVideosLabel.LayoutOrder = 0
	emptyVideosLabel.Parent = videoGrid

	rebuildVideoGrid = function()
		local count = videoCountStat.Value
		if count == lastRenderedVideoCount then
			return
		end
		lastRenderedVideoCount = count
		for _, child in videoGrid:GetChildren() do
			if child:IsA("Frame") and child.Name == "VideoCard" then
				child:Destroy()
			end
		end
		emptyVideosLabel.Visible = count == 0
		for i = count, 1, -1 do
			-- Найновіше відео — першою карткою (LayoutOrder за спаданням i).
			local card = Instance.new("Frame")
			card.Name = "VideoCard"
			card.BackgroundColor3 = Color3.fromRGB(32, 34, 44)
			card.BorderSizePixel = 0
			card.LayoutOrder = count - i + 1
			card.Parent = videoGrid
			local cardCorner = Instance.new("UICorner")
			cardCorner.CornerRadius = UDim.new(0, 10)
			cardCorner.Parent = card

			local cardIcon = Instance.new("TextLabel")
			cardIcon.Size = UDim2.new(1, 0, 1, -14)
			cardIcon.BackgroundTransparency = 1
			cardIcon.Font = Enum.Font.GothamBold
			cardIcon.TextSize = 18
			cardIcon.Text = "🎬"
			cardIcon.Parent = card

			local cardLabel = Instance.new("TextLabel")
			cardLabel.Size = UDim2.new(1, 0, 0, 14)
			cardLabel.Position = UDim2.new(0, 0, 1, -14)
			cardLabel.BackgroundTransparency = 1
			cardLabel.Font = Enum.Font.Gotham
			cardLabel.TextSize = 9
			cardLabel.TextColor3 = Color3.fromRGB(160, 164, 176)
			cardLabel.Text = `#{i}`
			cardLabel.Parent = card
		end
	end
	rebuildVideoGrid()

	-- Маленька кругла кнопка запису — тепер "плаває" в правому нижньому куті
	-- поверх стрічки відео (як кнопка запису в реальних застосунках), а не
	-- займає майже весь екран, як раніше.
	recordButton = Instance.new("TextButton")
	recordButton.Size = UDim2.new(0, 60, 0, 60)
	recordButton.AnchorPoint = Vector2.new(1, 1)
	recordButton.Position = UDim2.new(1, -4, 1, -4)
	recordButton.BackgroundColor3 = app.AccentColor
	recordButton.BorderSizePixel = 0
	recordButton.Font = Enum.Font.GothamBold
	recordButton.TextSize = 20
	recordButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	recordButton.TextWrapped = true
	recordButton.Text = "🔴"
	recordButton.ZIndex = 5
	recordButton.Parent = channelContent
	local recordCorner = Instance.new("UICorner")
	recordCorner.CornerRadius = UDim.new(1, 0)
	recordCorner.Parent = recordButton
	local recordStroke = Instance.new("UIStroke")
	recordStroke.Thickness = 3
	recordStroke.Color = Color3.fromRGB(255, 255, 255)
	recordStroke.Transparency = 0.6
	recordStroke.Parent = recordButton

	recordButton.MouseButton1Click:Connect(startRecording)

	refreshClipZapView = function()
		local hasNickname = channelNickname ~= nil
		nicknameSetupFrame.Visible = not hasNickname
		channelContent.Visible = hasNickname
		if hasNickname then
			nicknameLabel.Text = `@{channelNickname}`
		end
	end
	refreshClipZapView()

	pages[app.Id] = page
end

-- ---- Сторінка-заглушка для WatchBox / LiveWave, поки їх немає ----
local function buildComingSoonPage(app: PhoneConfig.AppConfig)
	local page = Instance.new("Frame")
	page.Name = app.Id
	page.Size = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency = 1
	page.Visible = false
	page.Parent = screen
	buildBackHeader(page, `{app.Icon} {app.DisplayName}`)

	local msg = Instance.new("TextLabel")
	msg.Size = UDim2.new(1, -40, 0, 100)
	msg.AnchorPoint = Vector2.new(0.5, 0.5)
	msg.Position = UDim2.new(0.5, 0, 0.5, 0)
	msg.BackgroundTransparency = 1
	msg.Font = Enum.Font.Gotham
	msg.TextSize = 14
	msg.TextWrapped = true
	msg.TextColor3 = Color3.fromRGB(190, 194, 204)
	msg.Text = `🚧 {app.DisplayName} unlocks later as you grow!`
	msg.Parent = page

	-- Той самий нік з ClipZap "чекатиме" тут, щоб було видно, що канал
	-- переноситься на всі платформи, а не створюється заново.
	local carryOverLabel = Instance.new("TextLabel")
	carryOverLabel.Size = UDim2.new(1, -40, 0, 20)
	carryOverLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	carryOverLabel.Position = UDim2.new(0.5, 0, 0.5, 56)
	carryOverLabel.BackgroundTransparency = 1
	carryOverLabel.Font = Enum.Font.GothamBold
	carryOverLabel.TextSize = 13
	carryOverLabel.TextColor3 = app.AccentColor
	carryOverLabel.Text = ""
	carryOverLabel.Parent = page

	local function refreshCarryOverLabel()
		carryOverLabel.Text = if channelNickname then `@{channelNickname} will carry over` else ""
	end
	refreshCarryOverLabel()
	table.insert(nicknameWatchers, refreshCarryOverLabel)

	pages[app.Id] = page
end

for i, app in PhoneConfig.Apps do
	buildAppIcon(app, i)
	if app.Id == "ClipZap" then
		buildClipZapPage(app)
	else
		buildComingSoonPage(app)
	end
end

-- ============================================================
-- Відкриття / закриття телефону (тепер виїжджає СПРАВА, а не знизу)
-- ============================================================
local function setPhoneOpen(open: boolean)
	if isAnimating or open == phoneOpen then
		return
	end
	if not open and recording then
		-- Не даємо ховати телефон посеред зйомки — інакше REC-камера й
		-- танець лишаться без екрана статусу, на якому видно прогрес.
		return
	end
	isAnimating = true
	phoneOpen = open

	if open then
		phoneFrame.Visible = true
		showPage("home")
		hintButton.Visible = false
		local tween = TweenService:Create(
			phoneFrame,
			TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Position = PHONE_OPEN_POSITION }
		)
		tween:Play()
		tween.Completed:Wait()
	else
		local tween = TweenService:Create(
			phoneFrame,
			TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = PHONE_CLOSED_POSITION }
		)
		tween:Play()
		tween.Completed:Wait()
		phoneFrame.Visible = false
		hintButton.Visible = true
	end

	isAnimating = false
end

-- Клік мишкою по підказці теж дістає телефон (не тільки клавіша "P") —
-- Illia попросив мати обидва способи. AutoButtonColor вимкнено вище, тому
-- додаємо власний маленький "натискальний" відгук (стискається й повертається),
-- щоб було візуально видно, що по підказці справді можна клікнути.
hintButton.MouseButton1Down:Connect(function()
	TweenService:Create(hintButton, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.05,
	}):Play()
end)
hintButton.MouseButton1Up:Connect(function()
	TweenService:Create(hintButton, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.28,
	}):Play()
end)
hintButton.MouseButton1Click:Connect(function()
	setPhoneOpen(true)
end)
closeButton.MouseButton1Click:Connect(function()
	setPhoneOpen(false)
end)

-- КЛЮЧОВЕ ВИПРАВЛЕННЯ: Enum.KeyCode.Up (стрілка вверх) — це один зі стандартних
-- клавіш руху персонажа Roblox (еквівалент W), тож стандартний контрол-скрипт
-- гри перехоплював її ПЕРШИМ і виставляв gameProcessed = true — наш обробник
-- нижче через це взагалі ніколи не спрацьовував. "P" — вільна клавіша, нічим
-- стандартним не зайнята, тож gameProcessed для неї коректно false.
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.P or input.KeyCode == Enum.KeyCode.Up then
		setPhoneOpen(not phoneOpen)
	end
end)

-- ============================================================
-- Синхронізація статистики (Followers / Money) з leaderstats
-- ============================================================
refreshStats = function()
	statsFollowersLabel.Text = `👥 {followersStat.Value}`
	statsMoneyLabel.Text = `💵 ${moneyStat.Value}`
	refreshLockedApps()

	if likesStatLabel then
		likesStatLabel.Text = tostring(totalLikesStat.Value)
	end
	if channelFollowersLabel then
		channelFollowersLabel.Text = tostring(followersStat.Value)
	end
	if videosStatLabel then
		videosStatLabel.Text = tostring(videoCountStat.Value)
	end
	if rebuildVideoGrid then
		rebuildVideoGrid()
	end
end

followersStat.Changed:Connect(refreshStats)
moneyStat.Changed:Connect(refreshStats)
totalLikesStat.Changed:Connect(refreshStats)
videoCountStat.Changed:Connect(refreshStats)
refreshStats()

-- ============================================================
-- Результат запису відео — тут же вимикаємо селфі-камеру, танець і REC-хад
-- ============================================================
recordVideoResult.OnClientEvent:Connect(function(result)
	recording = false
	recordButton.AutoButtonColor = true
	recordButton.Text = "🔴"

	stopRecordingCamera()
	recHud.Visible = false
	recBorder.Visible = false

	if result.Success then
		recordStatusLabel.Text = `🔥 +{result.Likes} likes → +${result.Money}, +{result.Followers} followers!`
		cooldownUntil = os.clock() + Economy.CooldownSeconds
	else
		recordStatusLabel.Text = "Wait a bit before your next video"
	end
end)
