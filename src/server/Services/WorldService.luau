local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local WorldService = {}

local function createSpawn()
	local existingSpawn = workspace:FindFirstChild("BottomSpawn")
	if existingSpawn then
		return existingSpawn
	end

	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "BottomSpawn"
	spawnLocation.Anchored = true
	spawnLocation.Neutral = true
	spawnLocation.Duration = 0
	spawnLocation.Size = Vector3.new(28, 1, 28)
	spawnLocation.Position = GameConfig.SpawnPlatformPosition
	spawnLocation.Parent = workspace

	return spawnLocation
end

local function teleportToBottom(character)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root then
		return
	end

	root.CFrame = CFrame.new(GameConfig.SpawnPosition)
end

function WorldService:Start()
	createSpawn()

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			task.wait(0.1)
			teleportToBottom(character)

			player:SetAttribute("CurrentStuds", 0)
			player:SetAttribute("CurrentFloor", 0)
			player:SetAttribute("RunBestStuds", 0)
			player:SetAttribute("LastReward", 0)
		end)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			task.spawn(function()
				teleportToBottom(player.Character)
			end)
		end
	end
end

return WorldService
