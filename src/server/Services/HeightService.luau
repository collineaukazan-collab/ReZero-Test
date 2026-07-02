local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local HeightService = {}

local ragdollService = nil

local function getHorizontalDistanceFromTower(root)
local position = root.Position
return Vector2.new(position.X, position.Z).Magnitude
end

local function isPlayerFallingOutsideTower(character, currentStuds)
local root = character:FindFirstChild("HumanoidRootPart")
if not root then
return false
end

if currentStuds < GameConfig.MinimumStudsBeforeFallKill then
return false
end

local distance = getHorizontalDistanceFromTower(root)
return distance > GameConfig.TowerSafeRadius
end

local function hasTouchedBottom(root)
return root.Position.Y <= GameConfig.FallDeathY
end

function HeightService:Start(playerDataService, injectedRagdollService)
ragdollService = injectedRagdollService

task.spawn(function()
while true do
for _, player in ipairs(Players:GetPlayers()) do
local character = player.Character
local root = character and character:FindFirstChild("HumanoidRootPart")
local humanoid = character and character:FindFirstChildOfClass("Humanoid")

if root and humanoid and humanoid.Health > 0 then
local currentStuds = math.max(0, math.floor(root.Position.Y - GameConfig.SpawnPosition.Y))
local currentFloor = math.max(0, math.floor(currentStuds / GameConfig.StairSegmentHeight))
local runBestStuds = math.max(player:GetAttribute("RunBestStuds") or 0, currentStuds)

player:SetAttribute("CurrentStuds", currentStuds)
player:SetAttribute("CurrentFloor", currentFloor)
player:SetAttribute("RunBestStuds", runBestStuds)

playerDataService:SetBestStuds(player, runBestStuds)

if GameConfig.KillWhenOutsideTowerRadius and isPlayerFallingOutsideTower(character, currentStuds) then
if ragdollService then
ragdollService:RagdollPlayer(player)
end
end

if hasTouchedBottom(root) then
humanoid.Health = 0
end
end
end

task.wait(GameConfig.HeightUpdateInterval)
end
end)
end

return HeightService
