local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local RewardService = {}

local pendingSummaryByPlayer = {}
local syncingCurrency = {}

local function getCurrencyName()
	return GameConfig.CurrencyName or "Auracoins"
end

local function formatNumber(value)
	value = math.floor(tonumber(value) or 0)
	return value
end

local function ensureLeaderstats(player)
	local leaderstats = player:FindFirstChild("leaderstats")

	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local auracoins = leaderstats:FindFirstChild("Auracoins")

	if not auracoins then
		auracoins = Instance.new("NumberValue")
		auracoins.Name = "Auracoins"
		auracoins.Parent = leaderstats
	end

	return leaderstats, auracoins
end

local function getCurrentAuracoins(player)
	local auracoins = player:GetAttribute("Auracoins")
	local oldMoney = player:GetAttribute("Money")

	if auracoins == nil and oldMoney ~= nil then
		return formatNumber(oldMoney)
	end

	return formatNumber(auracoins or 0)
end

local function setAuracoins(player, value)
	value = formatNumber(value)

	syncingCurrency[player] = true

	player:SetAttribute("Auracoins", value)

	-- Compatibilité avec tes anciens scripts.
	player:SetAttribute("Money", value)

	local _, leaderAuracoins = ensureLeaderstats(player)
	leaderAuracoins.Value = value

	syncingCurrency[player] = false
end

local function setupCurrencySync(player)
	if player:GetAttribute("Auracoins") == nil then
		local oldMoney = player:GetAttribute("Money")

		if oldMoney ~= nil then
			setAuracoins(player, oldMoney)
		else
			setAuracoins(player, 0)
		end
	else
		setAuracoins(player, player:GetAttribute("Auracoins"))
	end

	player:GetAttributeChangedSignal("Auracoins"):Connect(function()
		if syncingCurrency[player] then
			return
		end

		setAuracoins(player, player:GetAttribute("Auracoins") or 0)
	end)

	player:GetAttributeChangedSignal("Money"):Connect(function()
		if syncingCurrency[player] then
			return
		end

		-- Si un vieux script modifie encore Money, on convertit vers Auracoins.
		setAuracoins(player, player:GetAttribute("Money") or 0)
	end)
end

local function getRunStuds(player)
	local currentStuds = tonumber(player:GetAttribute("CurrentStuds")) or 0
	local bestStuds = tonumber(player:GetAttribute("RunBestStuds")) or 0

	return math.max(currentStuds, bestStuds, 0)
end

local function getRunFloor(player)
	local currentFloor = tonumber(player:GetAttribute("CurrentFloor")) or 0

	return math.max(0, math.floor(currentFloor))
end

local function getRewardMultiplier(player)
	local baseMultiplier = tonumber(player:GetAttribute("MoneyMultiplier"))
		or tonumber(player:GetAttribute("AuracoinsMultiplier"))
		or GameConfig.DefaultMoneyMultiplier
		or 1

	local sinMultiplier = tonumber(player:GetAttribute("SinAuracoinsMultiplier")) or 1

	return math.max(0, baseMultiplier * sinMultiplier)
end

local function calculateReward(player)
	local studs = getRunStuds(player)
	local multiplier = getRewardMultiplier(player)
	local moneyPerStud = GameConfig.MoneyPerStud or 1

	local reward = math.floor(studs * moneyPerStud * multiplier)

	return math.max(0, reward), studs, multiplier
end

local function saveLastRunSummary(player, reward, studs, floor, multiplier)
	local summary = {
		LastReward = reward,
		LastRunStuds = studs,
		LastRunFloor = floor,
		LastRunMultiplier = multiplier,
	}

	pendingSummaryByPlayer[player] = summary

	player:SetAttribute("LastReward", reward)
	player:SetAttribute("LastRunStuds", studs)
	player:SetAttribute("LastRunFloor", floor)
	player:SetAttribute("LastRunMultiplier", multiplier)
end

local function restorePendingSummary(player)
	local summary = pendingSummaryByPlayer[player]

	if not summary then
		return
	end

	player:SetAttribute("LastReward", summary.LastReward or 0)
	player:SetAttribute("LastRunStuds", summary.LastRunStuds or 0)
	player:SetAttribute("LastRunFloor", summary.LastRunFloor or 0)
	player:SetAttribute("LastRunMultiplier", summary.LastRunMultiplier or 1)
end

function RewardService:AwardRun(player, reason)
	if not player or not player.Parent then
		return 0
	end

	local character = player.Character

	if character then
		if character:GetAttribute("RunRewardPaid") == true then
			return 0
		end

		character:SetAttribute("RunRewardPaid", true)
	end

	local reward, studs, multiplier = calculateReward(player)
	local floor = getRunFloor(player)

	saveLastRunSummary(player, reward, studs, floor, multiplier)

	if reward <= 0 then
		return 0
	end

	local current = getCurrentAuracoins(player)
	local newTotal = current + reward

	setAuracoins(player, newTotal)

	print(
		"[RewardService]",
		player.Name,
		"earned",
		reward,
		getCurrencyName(),
		"reason:",
		reason or "run"
	)

	return reward
end

local function setupCharacter(player, character)
	character:SetAttribute("RunRewardPaid", false)

	local humanoid = character:WaitForChild("Humanoid", 10)

	if not humanoid then
		return
	end

	humanoid.Died:Connect(function()
		RewardService:AwardRun(player, "death")
	end)

	-- WorldService peut reset LastReward au respawn.
	-- Donc on restaure le résumé après le respawn pour que l'écran de mort l'affiche bien.
	task.delay(0.25, function()
		restorePendingSummary(player)
	end)

	task.delay(0.85, function()
		restorePendingSummary(player)
	end)
end

function RewardService:Start()
	Players.PlayerAdded:Connect(function(player)
		setupCurrencySync(player)

		player.CharacterAdded:Connect(function(character)
			setupCharacter(player, character)
		end)

		if player.Character then
			setupCharacter(player, player.Character)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		pendingSummaryByPlayer[player] = nil
		syncingCurrency[player] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		setupCurrencySync(player)

		if player.Character then
			setupCharacter(player, player.Character)
		end
	end

	print("[RewardService] Started. Currency =", getCurrencyName())
end

return RewardService