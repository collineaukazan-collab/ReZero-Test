local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local PlayerDataService = {}

PlayerDataService.Profiles = {}

local dataStore = DataStoreService:GetDataStore(GameConfig.DataStoreName)

local DEFAULT_PROFILE = {
	Money = 0,
	BestStuds = 0,
	MoneyMultiplier = GameConfig.DefaultMoneyMultiplier,
	GraphicsQuality = GameConfig.DefaultQuality,
}

local function copyDefaultProfile()
	return {
		Money = DEFAULT_PROFILE.Money,
		BestStuds = DEFAULT_PROFILE.BestStuds,
		MoneyMultiplier = DEFAULT_PROFILE.MoneyMultiplier,
		GraphicsQuality = DEFAULT_PROFILE.GraphicsQuality,
	}
end

local function getKey(player)
	return "Player_" .. tostring(player.UserId)
end

local function normalizeProfile(data)
	local profile = copyDefaultProfile()

	if type(data) == "table" then
		if type(data.Money) == "number" then
			profile.Money = math.max(0, math.floor(data.Money))
		end

		if type(data.BestStuds) == "number" then
			profile.BestStuds = math.max(0, math.floor(data.BestStuds))
		end

		if type(data.MoneyMultiplier) == "number" then
			profile.MoneyMultiplier = math.max(1, data.MoneyMultiplier)
		end

		if type(data.GraphicsQuality) == "string" and GameConfig.QualitySettings[data.GraphicsQuality] then
			profile.GraphicsQuality = data.GraphicsQuality
		end
	end

	return profile
end

local function syncAttributes(player, profile)
	player:SetAttribute("Money", profile.Money)
	player:SetAttribute("BestStuds", profile.BestStuds)
	player:SetAttribute("MoneyMultiplier", profile.MoneyMultiplier)
	player:SetAttribute("GraphicsQuality", profile.GraphicsQuality)
end

function PlayerDataService:Get(player)
	return self.Profiles[player]
end

function PlayerDataService:Load(player)
	local loadedData = nil

	local success, result = pcall(function()
		return dataStore:GetAsync(getKey(player))
	end)

	if success then
		loadedData = result
	else
		warn("[PlayerDataService] DataStore load failed for", player.Name, result)
	end

	local profile = normalizeProfile(loadedData)
	self.Profiles[player] = profile
	syncAttributes(player, profile)

	return profile
end

function PlayerDataService:Save(player)
	local profile = self.Profiles[player]
	if not profile then
		return
	end

	local dataToSave = {
		Money = profile.Money,
		BestStuds = profile.BestStuds,
		MoneyMultiplier = profile.MoneyMultiplier,
		GraphicsQuality = profile.GraphicsQuality,
	}

	local success, result = pcall(function()
		dataStore:SetAsync(getKey(player), dataToSave)
	end)

	if not success then
		warn("[PlayerDataService] DataStore save failed for", player.Name, result)
	end
end

function PlayerDataService:AddMoney(player, amount)
	local profile = self.Profiles[player]
	if not profile then
		return
	end

	amount = math.max(0, math.floor(amount))
	profile.Money += amount
	player:SetAttribute("Money", profile.Money)
end

function PlayerDataService:SetBestStuds(player, studs)
	local profile = self.Profiles[player]
	if not profile then
		return
	end

	studs = math.max(0, math.floor(studs))

	if studs > profile.BestStuds then
		profile.BestStuds = studs
		player:SetAttribute("BestStuds", profile.BestStuds)
	end
end

function PlayerDataService:SetGraphicsQuality(player, quality)
	local profile = self.Profiles[player]
	if not profile then
		return
	end

	if not GameConfig.QualitySettings[quality] then
		return
	end

	profile.GraphicsQuality = quality
	player:SetAttribute("GraphicsQuality", profile.GraphicsQuality)
end

function PlayerDataService:Start()
	Players.PlayerAdded:Connect(function(player)
		self:Load(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:Save(player)
		self.Profiles[player] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			self:Load(player)
		end)
	end

	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do
			self:Save(player)
		end
	end)
end

return PlayerDataService
