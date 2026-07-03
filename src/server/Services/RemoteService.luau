local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local RemoteService = {}

local function getOrCreateRemoteEvent(folder, name)
	local remote = folder:FindFirstChild(name)

	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
	end

	return remote
end

function RemoteService:Start(playerDataService)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = ReplicatedStorage
	end

	local getPlayerData = remotes:FindFirstChild("GetPlayerData")
	if not getPlayerData then
		getPlayerData = Instance.new("RemoteFunction")
		getPlayerData.Name = "GetPlayerData"
		getPlayerData.Parent = remotes
	end

	local setGraphicsQuality = getOrCreateRemoteEvent(remotes, "SetGraphicsQuality")
	local setResting = getOrCreateRemoteEvent(remotes, "SetResting")

	getPlayerData.OnServerInvoke = function(player)
		local profile = playerDataService:Get(player)

		if not profile then
			return {
				Money = 0,
				BestStuds = 0,
				MoneyMultiplier = GameConfig.DefaultMoneyMultiplier,
				GraphicsQuality = GameConfig.DefaultQuality,
			}
		end

		return {
			Money = profile.Money,
			BestStuds = profile.BestStuds,
			MoneyMultiplier = profile.MoneyMultiplier,
			GraphicsQuality = profile.GraphicsQuality,
		}
	end

	setGraphicsQuality.OnServerEvent:Connect(function(player, quality)
		if type(quality) ~= "string" then
			return
		end

		if not GameConfig.QualitySettings[quality] then
			return
		end

		playerDataService:SetGraphicsQuality(player, quality)
	end)

	setResting.OnServerEvent:Connect(function(player, resting)
		if typeof(resting) ~= "boolean" then
			return
		end

		local character = player.Character
		if character and character:GetAttribute("IsRagdolled") then
			player:SetAttribute("IsResting", false)
			return
		end

		player:SetAttribute("IsResting", resting)
	end)
end

return RemoteService