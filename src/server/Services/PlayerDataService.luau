local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local PlayerDataService = {}

local storeName = (GameConfig.DataStoreName or "ReZeroLoopData_v1") .. "_PlayerData_v2"
local dataStore = DataStoreService:GetDataStore(storeName)

local saving = {}
local loaded = {}

local function getSinsConfig()
	return GameConfig.Sins or {}
end

local function makeKey(player)
	return "Player_" .. tostring(player.UserId)
end

local function getDefaultData()
	local sinsConfig = getSinsConfig()

	return {
		Auracoins = 0,
		Money = 0,

		BestStuds = 0,
		BestFloor = 0,

		SinShards = sinsConfig.StartingSinShards or 0,

		SinSlot1 = "",
		SinSlot2 = "",
		SinSlot3 = "",

		GraphicsQuality = GameConfig.DefaultQuality or "Medium",
	}
end

local function numberOrDefault(value, default)
	if typeof(value) == "number" then
		return value
	end

	return default
end

local function stringOrDefault(value, default)
	if typeof(value) == "string" then
		return value
	end

	return default
end

local function applyData(player, data)
	local defaultData = getDefaultData()
	data = type(data) == "table" and data or defaultData

	local auracoins = numberOrDefault(data.Auracoins, numberOrDefault(data.Money, defaultData.Auracoins))

	player:SetAttribute("Auracoins", auracoins)
	player:SetAttribute("Money", auracoins)

	player:SetAttribute("BestStuds", numberOrDefault(data.BestStuds, defaultData.BestStuds))
	player:SetAttribute("BestFloor", numberOrDefault(data.BestFloor, defaultData.BestFloor))

	player:SetAttribute("SinShards", numberOrDefault(data.SinShards, defaultData.SinShards))

	player:SetAttribute("SinSlot1", stringOrDefault(data.SinSlot1, ""))
	player:SetAttribute("SinSlot2", stringOrDefault(data.SinSlot2, ""))
	player:SetAttribute("SinSlot3", stringOrDefault(data.SinSlot3, ""))

	player:SetAttribute("GraphicsQuality", stringOrDefault(data.GraphicsQuality, defaultData.GraphicsQuality))
end

local function collectData(player)
	local auracoins = player:GetAttribute("Auracoins") or player:GetAttribute("Money") or 0

	return {
		Auracoins = auracoins,
		Money = auracoins,

		BestStuds = player:GetAttribute("BestStuds") or 0,
		BestFloor = player:GetAttribute("BestFloor") or 0,

		SinShards = player:GetAttribute("SinShards") or 0,

		SinSlot1 = player:GetAttribute("SinSlot1") or "",
		SinSlot2 = player:GetAttribute("SinSlot2") or "",
		SinSlot3 = player:GetAttribute("SinSlot3") or "",

		GraphicsQuality = player:GetAttribute("GraphicsQuality") or GameConfig.DefaultQuality or "Medium",
	}
end

function PlayerDataService:LoadPlayer(player)
	local key = makeKey(player)

	local success, data = pcall(function()
		return dataStore:GetAsync(key)
	end)

	if success then
		applyData(player, data)
		loaded[player] = true
		print("[PlayerDataService] Loaded data for", player.Name)
	else
		warn("[PlayerDataService] Failed to load data for", player.Name, data)
		applyData(player, nil)
		loaded[player] = true
	end
end

function PlayerDataService:SavePlayer(player)
	if not player or not player.Parent then
		return
	end

	if saving[player] then
		return
	end

	saving[player] = true

	local key = makeKey(player)
	local data = collectData(player)

	local success, err = pcall(function()
		dataStore:SetAsync(key, data)
	end)

	if success then
		print("[PlayerDataService] Saved data for", player.Name)
	else
		warn("[PlayerDataService] Failed to save data for", player.Name, err)
	end

	saving[player] = nil
end

function PlayerDataService:Start()
	Players.PlayerAdded:Connect(function(player)
		self:LoadPlayer(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:SavePlayer(player)
		loaded[player] = nil
		saving[player] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		self:LoadPlayer(player)
	end

	task.spawn(function()
		while true do
			task.wait(60)

			for _, player in ipairs(Players:GetPlayers()) do
				self:SavePlayer(player)
			end
		end
	end)

	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do
			self:SavePlayer(player)
		end
	end)

	print("[PlayerDataService] Started:", storeName)
end

return PlayerDataService