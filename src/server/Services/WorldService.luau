local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local WorldService = {}

local function moveSpawnLocations()
	for _, instance in ipairs(workspace:GetDescendants()) do
		if instance:IsA("SpawnLocation") then
			instance.Position = GameConfig.SpawnPosition
		end
	end
end

local function resetRunAttributes(player)
	player:SetAttribute("CurrentStuds", 0)
	player:SetAttribute("CurrentFloor", 0)
	player:SetAttribute("RunBestStuds", 0)

	player:SetAttribute("LastReward", 0)
	player:SetAttribute("LastRunStuds", 0)
	player:SetAttribute("LastRunFloor", 0)
	player:SetAttribute("LastRunMultiplier", 1)

	player:SetAttribute("Insanity", 0)
	player:SetAttribute("InsanityActive", false)
	player:SetAttribute("InsanityCollapsed", false)
end

function WorldService:Start()
	moveSpawnLocations()

	workspace.DescendantAdded:Connect(function(instance)
		if instance:IsA("SpawnLocation") then
			task.wait()
			instance.Position = GameConfig.SpawnPosition
		end
	end)

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			resetRunAttributes(player)

			local root = character:WaitForChild("HumanoidRootPart", 10)
			if root then
				task.wait(0.1)
				root.CFrame = CFrame.new(GameConfig.SpawnPosition)
			end
		end)
	end)
end

return WorldService