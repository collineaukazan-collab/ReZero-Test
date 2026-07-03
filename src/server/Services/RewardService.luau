local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local RewardService = {}

local function setupCharacter(player, character, playerDataService)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then
		return
	end

	humanoid.Died:Connect(function()
		local profile = playerDataService:Get(player)
		if not profile then
			return
		end

		local runBestStuds = math.max(0, math.floor(player:GetAttribute("RunBestStuds") or 0))
		local runBestFloor = math.max(0, math.floor(runBestStuds / GameConfig.StairSegmentHeight))
		local multiplier = profile.MoneyMultiplier or GameConfig.DefaultMoneyMultiplier
		local reward = math.floor(runBestStuds * GameConfig.MoneyPerStud * multiplier)

		playerDataService:AddMoney(player, reward)

		player:SetAttribute("LastReward", reward)
		player:SetAttribute("LastRunStuds", runBestStuds)
		player:SetAttribute("LastRunFloor", runBestFloor)
		player:SetAttribute("LastRunMultiplier", multiplier)
	end)
end

function RewardService:Start(playerDataService)
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			setupCharacter(player, character, playerDataService)
		end)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			setupCharacter(player, player.Character, playerDataService)
		end
	end
end

return RewardService