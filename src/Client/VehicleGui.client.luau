--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui

-- ScreenGui for Driving HUD
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "VehicleGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

-- Main Dashboard Container (Bottom Center)
local dashFrame = Instance.new("Frame")
dashFrame.Name = "DashboardFrame"
dashFrame.Size = UDim2.new(0, 360, 0, 75)
dashFrame.Position = UDim2.new(0.5, -180, 1, 100) -- Hidden initially
dashFrame.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
dashFrame.BackgroundTransparency = 0.2
dashFrame.BorderSizePixel = 0
dashFrame.Parent = screenGui

local dashCorner = Instance.new("UICorner")
dashCorner.CornerRadius = UDim.new(0, 14)
dashCorner.Parent = dashFrame

local dashStroke = Instance.new("UIStroke")
dashStroke.Color = Color3.fromRGB(60, 170, 255)
dashStroke.Thickness = 2
dashStroke.Parent = dashFrame

-- Speedometer Label
local speedLabel = Instance.new("TextLabel")
speedLabel.Name = "SpeedLabel"
speedLabel.Size = UDim2.new(0, 130, 0, 42)
speedLabel.Position = UDim2.new(0, 15, 0, 8)
speedLabel.BackgroundTransparency = 1
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextSize = 28
speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Text = "0 <font size=\"14\" color=\"#aaaaaa\">KM/H</font>"
speedLabel.RichText = true
speedLabel.Parent = dashFrame

-- Vehicle Name / Status
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(0, 130, 0, 18)
statusLabel.Position = UDim2.new(0, 15, 0, 48)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.TextSize = 12
statusLabel.TextColor3 = Color3.fromRGB(60, 170, 255)
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Text = "🛹 GALAXY HOVERBOARD"
statusLabel.Parent = dashFrame

-- Controls Reminder Text
local controlsLabel = Instance.new("TextLabel")
controlsLabel.Name = "ControlsLabel"
controlsLabel.Size = UDim2.new(0, 195, 0, 58)
controlsLabel.Position = UDim2.new(1, -205, 0, 8)
controlsLabel.BackgroundTransparency = 1
controlsLabel.Font = Enum.Font.Gotham
controlsLabel.TextSize = 11
controlsLabel.TextColor3 = Color3.fromRGB(210, 215, 230)
controlsLabel.TextXAlignment = Enum.TextXAlignment.Right
controlsLabel.TextYAlignment = Enum.TextYAlignment.Center
controlsLabel.TextWrapped = true
controlsLabel.Text = "<b>[W/S]</b> Move / Reverse\n<b>[A/D]</b> Turn Left / Right\n<b>[Space]</b> Get Off Hoverboard"
controlsLabel.RichText = true
controlsLabel.Parent = dashFrame

local currentSeat: VehicleSeat? = nil
local speedConn: RBXScriptConnection? = nil

local function showDashboard()
    TweenService:Create(dashFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -180, 1, -95),
    }):Play()
end

local function hideDashboard()
    TweenService:Create(dashFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Position = UDim2.new(0.5, -180, 1, 100),
    }):Play()
end

local function onSeated(active: boolean, seatPart: Instance?)
    if active and seatPart and seatPart:IsA("VehicleSeat") then
        currentSeat = seatPart
        showDashboard()

        if speedConn then speedConn:Disconnect() end
        speedConn = RunService.RenderStepped:Connect(function()
            if not currentSeat or not currentSeat.Parent then return end
            local chassis = currentSeat.Parent:FindFirstChild("HoverboardBody") :: BasePart?
            if chassis then
                local speedStudsPerSec = chassis.AssemblyLinearVelocity.Magnitude
                -- 1 stud ≈ 0.28 meters -> speed * 0.28 * 3.6 ≈ speed * 1.0 km/h
                local kmh = math.floor(speedStudsPerSec * 1.05)
                local colorHex = if kmh > 50 then "#FF5555" elseif kmh > 25 then "#FFAA00" else "#FFFFFF"
                speedLabel.Text = `<font color="{colorHex}">{kmh}</font> <font size="14" color="#aaaaaa">KM/H</font>`
            end
        end)
    else
        currentSeat = nil
        if speedConn then
            speedConn:Disconnect()
            speedConn = nil
        end
        hideDashboard()
    end
end

local function bindCharacter(char: Model)
    local humanoid = char:WaitForChild("Humanoid") :: Humanoid
    humanoid.Seated:Connect(onSeated)
end

if LocalPlayer.Character then
    bindCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(bindCharacter)
