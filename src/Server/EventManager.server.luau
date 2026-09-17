--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StreamConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("StreamConfig") :: ModuleScript)

-- Ensure EventState Folder in ReplicatedStorage
local eventStateFolder = ReplicatedStorage:FindFirstChild("EventState")
if not eventStateFolder then
    eventStateFolder = Instance.new("Folder")
    eventStateFolder.Name = "EventState"
    eventStateFolder.Parent = ReplicatedStorage
end

local isBoostActiveObj = eventStateFolder:FindFirstChild("IsBoostActive") :: BoolValue?
if not isBoostActiveObj then
    isBoostActiveObj = Instance.new("BoolValue")
    isBoostActiveObj.Name = "IsBoostActive"
    isBoostActiveObj.Value = false
    isBoostActiveObj.Parent = eventStateFolder
end

local remainingSecondsObj = eventStateFolder:FindFirstChild("RemainingSeconds") :: IntValue?
if not remainingSecondsObj then
    remainingSecondsObj = Instance.new("IntValue")
    remainingSecondsObj.Name = "RemainingSeconds"
    remainingSecondsObj.Value = 0
    remainingSecondsObj.Parent = eventStateFolder
end

-- Timing Configuration
local CYCLE_TIME = StreamConfig.EventCycleDurationSeconds or 3600 -- 1 Hour
local BOOST_TIME = StreamConfig.EventBoostDurationSeconds or 600   -- 10 Minutes
local WAIT_TIME = CYCLE_TIME - BOOST_TIME                         -- 50 Minutes

task.spawn(function()
    while true do
        -- 1. Cooldown / Wait phase (50 mins)
        isBoostActiveObj.Value = false
        for sec = WAIT_TIME, 1, -1 do
            remainingSecondsObj.Value = sec
            task.wait(1)
        end

        -- 2. Active Boost Phase (10 mins)
        isBoostActiveObj.Value = true
        for sec = BOOST_TIME, 1, -1 do
            remainingSecondsObj.Value = sec
            task.wait(1)
        end
    end
end)
