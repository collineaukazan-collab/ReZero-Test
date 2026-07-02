local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local RemoteService = {}

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

	local setGraphicsQuality = remotes:FindFirstChild("SetGraphicsQuality")
	if not setGraphicsQuality then
		setGraphicsQuality = Instance.new("RemoteEvent")
		setGraphicsQuality.Name = "SetGraphicsQuality"
		setGraphicsQuality.Parent = remotes
	end

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
end

return RemoteService
