local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local InsanityService = {}

local ragdollService = nil
local fullSince = {}

local function resetPlayer(player)
	player:SetAttribute("Insanity", 0)
	player:SetAttribute("InsanityActive", false)
	player:SetAttribute("InsanityCollapsed", false)
	player:SetAttribute("IsResting", false)
	fullSince[player] = nil
end

local function updatePlayer(player, deltaTime)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if not character or not humanoid or humanoid.Health <= 0 then
		return
	end

	if character:GetAttribute("IsRagdolled") then
		player:SetAttribute("IsResting", false)
		return
	end

	if player:GetAttribute("InsanityCollapsed") then
		player:SetAttribute("IsResting", false)
		return
	end

	local floor = math.floor(player:GetAttribute("CurrentFloor") or 0)
	local current = player:GetAttribute("Insanity") or 0
	local isResting = player:GetAttribute("IsResting") == true

	if floor < 1 then
		current = current - GameConfig.Insanity.DecayPerSecondAtFloorZero * deltaTime
	else
		local gain = GameConfig.Insanity.BaseGainPerSecond
			+ (floor * GameConfig.Insanity.GainPerFloorPerSecond)

		current = current + gain * deltaTime
	end

	if isResting then
		current = current - GameConfig.Rest.DrainPerSecond * deltaTime
	end

	current = math.clamp(current, 0, GameConfig.Insanity.Max)

	player:SetAttribute("Insanity", current)
	player:SetAttribute("InsanityActive", current > 0)

	if current >= GameConfig.Insanity.Max then
		if not fullSince[player] then
			fullSince[player] = os.clock()
			return
		end

		if os.clock() - fullSince[player] >= GameConfig.Insanity.FullDurationBeforeCollapse then
			player:SetAttribute("InsanityCollapsed", true)
			player:SetAttribute("IsResting", false)

			if ragdollService then
				ragdollService:PushPlayerToCenter(
					player,
					GameConfig.Insanity.CollapsePushSpeed,
					GameConfig.Insanity.CollapseDownSpeed
				)
			end
		end
	else
		fullSince[player] = nil
	end
end

function InsanityService:Start(injectedRagdollService)
	ragdollService = injectedRagdollService

	Players.PlayerAdded:Connect(function(player)
		resetPlayer(player)

		player.CharacterAdded:Connect(function()
			resetPlayer(player)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		fullSince[player] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		resetPlayer(player)

		player.CharacterAdded:Connect(function()
			resetPlayer(player)
		end)
	end

	task.spawn(function()
		local lastTime = os.clock()

		while true do
			local now = os.clock()
			local deltaTime = now - lastTime
			lastTime = now

			for _, player in ipairs(Players:GetPlayers()) do
				updatePlayer(player, deltaTime)
			end

			task.wait(0.1)
		end
	end)
end

return InsanityService