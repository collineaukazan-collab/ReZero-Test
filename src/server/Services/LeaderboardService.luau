local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local LeaderboardService = {}

local syncing = {}

local function getCurrencyName()
	return GameConfig.CurrencyName or "Auracoins"
end

local function asNumber(value)
	return math.floor(tonumber(value) or 0)
end

local function getOrCreateLeaderstats(player)
	local leaderstats = player:FindFirstChild("leaderstats")

	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	return leaderstats
end

local function getOrCreateNumberValue(parent, name)
	local value = parent:FindFirstChild(name)

	if not value then
		value = Instance.new("NumberValue")
		value.Name = name
		value.Parent = parent
	end

	return value
end

local function syncCurrency(player)
	if syncing[player] then
		return
	end

	syncing[player] = true

	local auracoins = player:GetAttribute("Auracoins")
	local oldMoney = player:GetAttribute("Money")

	if auracoins == nil and oldMoney ~= nil then
		auracoins = oldMoney
	end

	auracoins = asNumber(auracoins or 0)

	player:SetAttribute("Auracoins", auracoins)
	player:SetAttribute("Money", auracoins)

	syncing[player] = false
end

local function updateLeaderboard(player)
	syncCurrency(player)

	local leaderstats = getOrCreateLeaderstats(player)

	local auracoinsValue = getOrCreateNumberValue(leaderstats, "Auracoins")
	local bestFloorValue = getOrCreateNumberValue(leaderstats, "BestFloor")
	local bestStudsValue = getOrCreateNumberValue(leaderstats, "BestStuds")
	local shardsValue = getOrCreateNumberValue(leaderstats, "SinShards")

	local auracoins = asNumber(player:GetAttribute("Auracoins") or player:GetAttribute("Money") or 0)

	local bestStuds = math.max(
		asNumber(player:GetAttribute("BestStuds") or 0),
		asNumber(player:GetAttribute("RunBestStuds") or 0)
	)

	local bestFloor = math.max(
		asNumber(player:GetAttribute("BestFloor") or 0),
		asNumber(player:GetAttribute("CurrentFloor") or 0)
	)

	player:SetAttribute("BestStuds", bestStuds)
	player:SetAttribute("BestFloor", bestFloor)

	auracoinsValue.Value = auracoins
	bestFloorValue.Value = bestFloor
	bestStudsValue.Value = bestStuds
	shardsValue.Value = asNumber(player:GetAttribute("SinShards") or 0)
end

local function setupPlayer(player)
	if player:GetAttribute("Auracoins") == nil then
		player:SetAttribute("Auracoins", player:GetAttribute("Money") or 0)
	end

	if player:GetAttribute("Money") == nil then
		player:SetAttribute("Money", player:GetAttribute("Auracoins") or 0)
	end

	if player:GetAttribute("BestStuds") == nil then
		player:SetAttribute("BestStuds", 0)
	end

	if player:GetAttribute("BestFloor") == nil then
		player:SetAttribute("BestFloor", 0)
	end

	updateLeaderboard(player)

	local watchedAttributes = {
		"Auracoins",
		"Money",
		"BestStuds",
		"BestFloor",
		"RunBestStuds",
		"CurrentFloor",
		"SinShards",
	}

	for _, attributeName in ipairs(watchedAttributes) do
		player:GetAttributeChangedSignal(attributeName):Connect(function()
			updateLeaderboard(player)
		end)
	end
end

function LeaderboardService:Start()
	Players.PlayerAdded:Connect(setupPlayer)

	Players.PlayerRemoving:Connect(function(player)
		syncing[player] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	print("[LeaderboardService] Started. Currency =", getCurrencyName())
end

return LeaderboardService