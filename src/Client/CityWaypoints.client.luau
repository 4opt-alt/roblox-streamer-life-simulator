--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CityWaypointsGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

type WaypointData = {
    Name: string,
    Icon: string,
    Color: Color3,
    GetPosition: () -> Vector3?,
}

local waypoints: { WaypointData } = {
    {
        Name = "My Studio",
        Icon = "🏠",
        Color = Color3.fromRGB(52, 152, 219),
        GetPosition = function() return Vector3.new(0, 6, -62) end,
    },
    {
        Name = "Galaxy Hoverboard",
        Icon = "🛹",
        Color = Color3.fromRGB(60, 170, 255),
        GetPosition = function()
            local board = workspace:FindFirstChild("Hoverboard", true) :: Model?
            local deck = board and board:FindFirstChild("HoverboardBody") :: BasePart?
            return deck and (deck.Position + Vector3.new(0, 3, 0))
        end,
    },
    {
        Name = "CyberByte Tech",
        Icon = "💻",
        Color = Color3.fromRGB(0, 242, 254),
        GetPosition = function() return Vector3.new(46, 7, 40) end,
    },
    {
        Name = "Burger & Snacks",
        Icon = "🍔",
        Color = Color3.fromRGB(243, 156, 18),
        GetPosition = function() return Vector3.new(-46, 7, 40) end,
    },
    {
        Name = "Wall of Fame",
        Icon = "🏆",
        Color = Color3.fromRGB(255, 215, 0),
        GetPosition = function() return Vector3.new(-46, 12, 130) end,
    },
    {
        Name = "SkyGlide Boards",
        Icon = "🛹",
        Color = Color3.fromRGB(60, 150, 255),
        GetPosition = function() return Vector3.new(46, 7, 250) end,
    },
    {
        Name = "Splash Street Pool",
        Icon = "🏊",
        Color = Color3.fromRGB(60, 190, 255),
        GetPosition = function() return Vector3.new(-46, 4, 250) end,
    },
    {
        Name = "Colosseum",
        Icon = "🏛️",
        Color = Color3.fromRGB(255, 215, 0),
        GetPosition = function() return Vector3.new(0, 12, 460) end,
    },
    {
        Name = "Wild Stream Zoo",
        Icon = "🦁",
        Color = Color3.fromRGB(120, 220, 100),
        GetPosition = function() return Vector3.new(130, 7, 320) end,
    },
    {
        Name = "Celebrity Row",
        Icon = "🏡",
        Color = Color3.fromRGB(255, 200, 80),
        GetPosition = function() return Vector3.new(0, 7, -190) end,
    },
}

-- Create Screen Markers
local markerFrames: { [string]: Frame } = {}

for _, wp in waypoints do
    local frame = Instance.new("Frame")
    frame.Name = `Marker_{wp.Name}`
    frame.Size = UDim2.new(0, 130, 0, 26)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
    frame.BackgroundTransparency = 0.25
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = wp.Color
    stroke.Thickness = 1.5
    stroke.Parent = frame

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Text = `{wp.Icon} {wp.Name}`
    label.Parent = frame

    markerFrames[wp.Name] = frame
end

RunService.RenderStepped:Connect(function()
    local camera = workspace.CurrentCamera
    if not camera then return end

    local char = LocalPlayer.Character
    local myPos = char and char:FindFirstChild("HumanoidRootPart") and (char.HumanoidRootPart :: BasePart).Position

    for _, wp in waypoints do
        local targetPos = wp.GetPosition()
        local frame = markerFrames[wp.Name]
        if not targetPos or not frame then
            if frame then frame.Visible = false end
            continue
        end

        local screenPos, onScreen = camera:WorldToViewportPoint(targetPos)
        local dist = if myPos then math.floor((targetPos - myPos).Magnitude) else 0

        -- Show waypoint if on screen and further than 14 studs
        if onScreen and dist > 14 and screenPos.Z > 0 then
            frame.Visible = true
            frame.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y - 20)
            local label = frame:FindFirstChild("Label") :: TextLabel?
            if label then
                label.Text = `{wp.Icon} {wp.Name} ({dist}m)`
            end
        else
            frame.Visible = false
        end
    end
end)
