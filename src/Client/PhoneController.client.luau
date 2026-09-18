--!strict
-- Телефон гравця: маленька підказка "▲ Take out phone", сам телефон, який
-- живе з ПРАВОГО боку екрана (не закриває вид на персонажа), з 3 іконками
-- застосунків (ClipZap відкритий одразу, WatchBox і LiveWave розблоковуються
-- пізніше за підписниками) і механіка запису відео в ClipZap: під час зйомки
-- камера перемикається на "селфі"-ракурс перед персонажем, персонаж танцює
-- один із стандартних танців Roblox, і на екрані з'являється REC-індикатор —
-- щоб виглядало так, ніби гравець реально знімає контент. За відео капають
-- лайки -> підписники + гроші (кожні 10 лайків = $1).
--
-- ПРИМІТКА: усі тексти, які бачить гравець, тепер англійською (стандартне
-- правило проєкту від Illia). Коментарі лишаються українською.

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

-- ============================================================
-- Стан
-- ============================================================
local phoneOpen = false
local isAnimating = false
local recording = false
local cooldownUntil = 0

local showPage: (string) -> ()
local refreshStats: () -> ()
local recordButton: TextButton
local recordStatusLabel: TextLabel

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

local hintArrow = Instance.new("TextLabel")
hintArrow.Name = "Arrow"
hintArrow.AnchorPoint = Vector2.new(0, 0.5)
hintArrow.Position = UDim2.new(0, 16, 0.5, 0)
hintArrow.Size = UDim2.new(0, 18, 0, 18)
hintArrow.BackgroundTransparency = 1
hintArrow.Font = Enum.Font.GothamBold
hintArrow.Text = "▲"
hintArrow.TextSize = 16
hintArrow.TextColor3 = Color3.fromRGB(120, 210, 255)
hintArrow.Parent = hintButton

local hintText = Instance.new("TextLabel")
hintText.Name = "Label"
hintText.AnchorPoint = Vector2.new(0, 0.5)
hintText.Position = UDim2.new(0, 40, 0.5, 0)
hintText.Size = UDim2.new(0, 140, 0, 20)
hintText.BackgroundTransparency = 1
hintText.Font = Enum.Font.Gotham
hintText.Text = "Take out phone"
hintText.TextSize = 14
hintText.TextColor3 = Color3.fromRGB(235, 238, 245)
hintText.TextXAlignment = Enum.TextXAlignment.Left
hintText.Parent = hintButton

-- Легка пульсація стрілочки — привертає погляд, але не дратує
task.spawn(function()
	while hintArrow.Parent do
		local up = TweenService:Create(hintArrow, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Position = UDim2.new(0, 16, 0.5, -4) })
		local down = TweenService:Create(hintArrow, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Position = UDim2.new(0, 16, 0.5, 0) })
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
-- "Селфі"-камера + танець персонажа під час зйомки відео
-- ============================================================
local DANCE_EMOTES = { "dance1", "dance2", "dance3" }

local selfieConnection: RBXScriptConnection? = nil
local activeEmoteTrack: AnimationTrack? = nil
local originalCameraType: Enum.CameraType? = nil

local function startSelfieRecording()
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local head = character and character:FindFirstChild("Head") :: BasePart?
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not (character and humanoid and head and hrp) then
		return
	end

	-- Один із стандартних танців персонажа Roblox — випадковий щоразу,
	-- щоб не набридало. Використовуємо PlayEmote (а не жорстко вбитий
	-- AnimationId), бо стандартні танці вже є в будь-якого персонажа за
	-- замовчуванням і повертають трек, який можна коректно зупинити.
	local emoteName = DANCE_EMOTES[math.random(1, #DANCE_EMOTES)]
	local ok, track = pcall(function()
		return (humanoid :: Humanoid):PlayEmote(emoteName)
	end)
	if ok and track then
		activeEmoteTrack = track :: AnimationTrack
	end

	local camera = workspace.CurrentCamera
	if camera then
		originalCameraType = camera.CameraType
		camera.CameraType = Enum.CameraType.Scriptable
		selfieConnection = RunService.RenderStepped:Connect(function()
			if not (head.Parent and hrp.Parent) then
				return
			end
			-- Камера висить попереду персонажа й дивиться назад на нього —
			-- класичний "селфі на телефон" ракурс блогера.
			local lookVector = hrp.CFrame.LookVector
			local camPos = head.Position + lookVector * 6 + Vector3.new(0, 1.1, 0)
			local focusPos = head.Position + Vector3.new(0, 0.2, 0)
			camera.CFrame = CFrame.lookAt(camPos, focusPos)
		end)
	end
end

local function stopSelfieRecording()
	if selfieConnection then
		selfieConnection:Disconnect()
		selfieConnection = nil
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

-- ---- Сторінка ClipZap: запис відео (з "селфі"-камерою й танцем) ----
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
	startSelfieRecording()

	task.spawn(function()
		for i = Economy.RecordSeconds, 1, -1 do
			recordButton.Text = `⏺ Filming... {i}`
			recLabel.Text = `REC {i}s`
			task.wait(1)
		end
		recordButton.Text = "📤 Uploading..."
		recLabel.Text = "UPLOADING"
		recordStatusLabel.Text = "Waiting for the audience's reaction..."
		recordVideoRequest:FireServer()
	end)
end

local function buildClipZapPage(app: PhoneConfig.AppConfig)
	local page = Instance.new("Frame")
	page.Name = app.Id
	page.Size = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency = 1
	page.Visible = false
	page.Parent = screen
	buildBackHeader(page, `{app.Icon} {app.DisplayName}`)

	recordButton = Instance.new("TextButton")
	recordButton.Size = UDim2.new(0, 150, 0, 150)
	recordButton.AnchorPoint = Vector2.new(0.5, 0.5)
	recordButton.Position = UDim2.new(0.5, 0, 0.46, 0)
	recordButton.BackgroundColor3 = app.AccentColor
	recordButton.BorderSizePixel = 0
	recordButton.Font = Enum.Font.GothamBold
	recordButton.TextSize = 15
	recordButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	recordButton.TextWrapped = true
	recordButton.Text = "🔴 Record video"
	recordButton.Parent = page
	local recordCorner = Instance.new("UICorner")
	recordCorner.CornerRadius = UDim.new(1, 0)
	recordCorner.Parent = recordButton
	local recordStroke = Instance.new("UIStroke")
	recordStroke.Thickness = 3
	recordStroke.Color = Color3.fromRGB(255, 255, 255)
	recordStroke.Transparency = 0.6
	recordStroke.Parent = recordButton

	recordStatusLabel = Instance.new("TextLabel")
	recordStatusLabel.Size = UDim2.new(1, -30, 0, 70)
	recordStatusLabel.AnchorPoint = Vector2.new(0.5, 0)
	recordStatusLabel.Position = UDim2.new(0.5, 0, 0.76, 0)
	recordStatusLabel.BackgroundTransparency = 1
	recordStatusLabel.Font = Enum.Font.Gotham
	recordStatusLabel.TextSize = 13
	recordStatusLabel.TextWrapped = true
	recordStatusLabel.TextColor3 = Color3.fromRGB(200, 204, 214)
	recordStatusLabel.Text = "Tap to film a new video!"
	recordStatusLabel.Parent = page

	recordButton.MouseButton1Click:Connect(startRecording)
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

hintButton.MouseButton1Click:Connect(function()
	setPhoneOpen(true)
end)
closeButton.MouseButton1Click:Connect(function()
	setPhoneOpen(false)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.Up then
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
end

followersStat.Changed:Connect(refreshStats)
moneyStat.Changed:Connect(refreshStats)
refreshStats()

-- ============================================================
-- Результат запису відео — тут же вимикаємо селфі-камеру, танець і REC-хад
-- ============================================================
recordVideoResult.OnClientEvent:Connect(function(result)
	recording = false
	recordButton.AutoButtonColor = true
	recordButton.Text = "🔴 Record video"

	stopSelfieRecording()
	recHud.Visible = false
	recBorder.Visible = false

	if result.Success then
		recordStatusLabel.Text = `🔥 +{result.Likes} likes → +${result.Money}, +{result.Followers} followers!`
		cooldownUntil = os.clock() + Economy.CooldownSeconds
	else
		recordStatusLabel.Text = "Wait a bit before your next video"
	end
end)
