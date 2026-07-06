local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local InsanityService = {}

local fullInsanitySince = {}
local ragdollService = nil

local function getRagdollService()
	if ragdollService ~= nil then
		return ragdollService
	end

	local success, result = pcall(function()
		return require(script.Parent:WaitForChild("RagdollService"))
	end)

	if success then
		ragdollService = result
	else
		ragdollService = false
	end

	return ragdollService
end

local function getInsanityConfig()
	return GameConfig.Insanity or {}
end

local function getRestConfig()
	return GameConfig.Rest or {}
end

local function clampInsanity(value)
	local config = getInsanityConfig()
	local maxValue = config.Max or 100

	return math.clamp(value, 0, maxValue)
end

local function getCurrentFloor(player)
	return math.floor(tonumber(player:GetAttribute("CurrentFloor")) or 0)
end

local function isCharacterAlive(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	return humanoid ~= nil and humanoid.Health > 0
end

local function resetPlayerInsanity(player)
	player:SetAttribute("Insanity", 0)
	player:SetAttribute("InsanityActive", false)
	player:SetAttribute("InsanityCollapsed", false)

	fullInsanitySince[player] = nil
end

local function collapsePlayer(player)
	if player:GetAttribute("InsanityCollapsed") == true then
		return
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if not character or not humanoid or humanoid.Health <= 0 then
		return
	end

	player:SetAttribute("InsanityCollapsed", true)
	player:SetAttribute("IsResting", false)

	local service = getRagdollService()

	if service then
		if service.PushPlayerToCenter then
			pcall(function()
				service:PushPlayerToCenter(player)
			end)
		elseif service.RagdollCharacter then
			pcall(function()
				service:RagdollCharacter(character)
			end)
		end
	end

	print("[InsanityService] Collapse:", player.Name)
end

local function calculateGain(player, currentFloor)
	local config = getInsanityConfig()

	local baseGain = config.BaseGainPerSecond or 0
	local gainPerFloor = config.GainPerFloorPerSecond or 0

	local gain = baseGain + currentFloor * gainPerFloor

	-- Wrath : réduit le gain d'insanity.
	gain *= player:GetAttribute("SinInsanityMultiplier") or 1

	return math.max(0, gain)
end

local function updatePlayer(player, dt)
	if not isCharacterAlive(player) then
		return
	end

	local config = getInsanityConfig()
	local restConfig = getRestConfig()

	local maxInsanity = config.Max or 100
	local currentFloor = getCurrentFloor(player)
	local insanity = tonumber(player:GetAttribute("Insanity")) or 0

	if player:GetAttribute("InsanityCollapsed") == true then
		return
	end

	if currentFloor >= 1 then
		local gain = calculateGain(player, currentFloor)
		insanity += gain * dt
	else
		local decay = config.DecayPerSecondAtFloorZero or 0
		insanity -= decay * dt
	end

	-- Le repos réduit l'insanity même si tu es dans les étages.
	if player:GetAttribute("IsResting") == true then
		local restDrain = restConfig.DrainPerSecond or 0
		insanity -= restDrain * dt
	end

	insanity = clampInsanity(insanity)

	player:SetAttribute("Insanity", insanity)
	player:SetAttribute("InsanityActive", currentFloor >= 1 or insanity > 0)

	if insanity >= maxInsanity then
		if not fullInsanitySince[player] then
			fullInsanitySince[player] = os.clock()
		end

		local duration = config.FullDurationBeforeCollapse or 1

		if os.clock() - fullInsanitySince[player] >= duration then
			collapsePlayer(player)
		end
	else
		fullInsanitySince[player] = nil
	end
end

local function setupPlayer(player)
	if player:GetAttribute("Insanity") == nil then
		player:SetAttribute("Insanity", 0)
	end

	if player:GetAttribute("InsanityActive") == nil then
		player:SetAttribute("InsanityActive", false)
	end

	if player:GetAttribute("InsanityCollapsed") == nil then
		player:SetAttribute("InsanityCollapsed", false)
	end

	player.CharacterAdded:Connect(function()
		resetPlayerInsanity(player)
	end)

	player.CharacterRemoving:Connect(function()
		fullInsanitySince[player] = nil
	end)
end

function InsanityService:Start()
	Players.PlayerAdded:Connect(function(player)
		setupPlayer(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		fullInsanitySince[player] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	RunService.Heartbeat:Connect(function(dt)
		for _, player in ipairs(Players:GetPlayers()) do
			updatePlayer(player, dt)
		end
	end)

	print("[InsanityService] Started.")
end

return InsanityService