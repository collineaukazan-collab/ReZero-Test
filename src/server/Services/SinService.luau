local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local SinService = {}

local remotesFolder = nil
local rollSinRemote = nil
local getSinStateRemote = nil
local equipSinRemote = nil
local sinStateChangedRemote = nil
local openSinMenuRemote = nil

local snapshots = {}
local pendingEnvyRewind = {}
local lastSnapshotAt = {}

local function getSinsConfig()
	return GameConfig.Sins or {}
end

local function getDefinitions()
	local config = getSinsConfig()
	return config.Definitions or {}
end

local function getRollOrder()
	local config = getSinsConfig()
	return config.RollOrder or {}
end

local function getRemotesFolder()
	local folder = ReplicatedStorage:FindFirstChild("Remotes")

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end

	return folder
end

local function getOrCreateRemoteFunction(name)
	local folder = getRemotesFolder()
	local remote = folder:FindFirstChild(name)

	if not remote then
		remote = Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = folder
	end

	return remote
end

local function getOrCreateRemoteEvent(name)
	local folder = getRemotesFolder()
	local remote = folder:FindFirstChild(name)

	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
	end

	return remote
end

local function setupRemotes()
	remotesFolder = getRemotesFolder()

	rollSinRemote = getOrCreateRemoteFunction("RollSin")
	getSinStateRemote = getOrCreateRemoteFunction("GetSinState")
	equipSinRemote = getOrCreateRemoteEvent("EquipSin")
	sinStateChangedRemote = getOrCreateRemoteEvent("SinStateChanged")
	openSinMenuRemote = getOrCreateRemoteEvent("OpenSinMenu")
end

local function getSlotName(index)
	return "SinSlot" .. tostring(index)
end

local function getPlayerSinSlots(player)
	local config = getSinsConfig()
	local slotCount = config.SlotCount or 3

	local slots = {}

	for index = 1, slotCount do
		local value = player:GetAttribute(getSlotName(index))

		if type(value) == "string" and value ~= "" then
			table.insert(slots, value)
		else
			table.insert(slots, "")
		end
	end

	return slots
end

local function hasSin(player, sinName)
	for _, slotValue in ipairs(getPlayerSinSlots(player)) do
		if slotValue == sinName then
			return true
		end
	end

	return false
end

local function sendState(player)
	if sinStateChangedRemote then
		sinStateChangedRemote:FireClient(player, SinService:GetState(player))
	end
end

local function applySinEffects(player)
	local definitions = getDefinitions()
	local slots = getPlayerSinSlots(player)

	local walkSpeedMultiplier = 1
	local runSpeedMultiplier = 1
	local staminaMultiplier = 1
	local auracoinsMultiplier = 1
	local insanityMultiplier = 1

	for _, sinName in ipairs(slots) do
		local definition = definitions[sinName]

		if definition then
			walkSpeedMultiplier *= definition.WalkSpeedMultiplier or 1
			runSpeedMultiplier *= definition.RunSpeedMultiplier or 1
			staminaMultiplier *= definition.StaminaMultiplier or 1
			auracoinsMultiplier *= definition.AuracoinsMultiplier or 1
			insanityMultiplier *= definition.InsanityMultiplier or 1
		end
	end

	player:SetAttribute("SinWalkSpeedMultiplier", walkSpeedMultiplier)
	player:SetAttribute("SinRunSpeedMultiplier", runSpeedMultiplier)
	player:SetAttribute("SinStaminaMultiplier", staminaMultiplier)
	player:SetAttribute("SinAuracoinsMultiplier", auracoinsMultiplier)
	player:SetAttribute("SinInsanityMultiplier", insanityMultiplier)
end

local function chooseRandomSin()
	local definitions = getDefinitions()
	local order = getRollOrder()

	local totalWeight = 0

	for _, sinName in ipairs(order) do
		local definition = definitions[sinName]

		if definition then
			totalWeight += definition.Weight or 0
		end
	end

	if totalWeight <= 0 then
		return nil
	end

	local roll = Random.new():NextNumber(0, totalWeight)
	local current = 0

	for _, sinName in ipairs(order) do
		local definition = definitions[sinName]

		if definition then
			current += definition.Weight or 0

			if roll <= current then
				return sinName
			end
		end
	end

	return order[#order]
end

local function setupPlayerDefaults(player)
	if player:GetAttribute("SinShards") == nil then
		local config = getSinsConfig()
		player:SetAttribute("SinShards", config.StartingSinShards or 0)
	end

	if player:GetAttribute("LastSinShardMilestone") == nil then
		player:SetAttribute("LastSinShardMilestone", 0)
	end

	if player:GetAttribute("LastEnvyUse") == nil then
		player:SetAttribute("LastEnvyUse", -999999)
	end

	local config = getSinsConfig()
	local slotCount = config.SlotCount or 3

	for index = 1, slotCount do
		if player:GetAttribute(getSlotName(index)) == nil then
			player:SetAttribute(getSlotName(index), "")
		end
	end

	applySinEffects(player)
end

function SinService:GetState(player)
	local config = getSinsConfig()
	local definitions = getDefinitions()

	local publicDefinitions = {}

	for _, sinName in ipairs(config.RollOrder or {}) do
		local definition = definitions[sinName]

		if definition then
			publicDefinitions[sinName] = {
				DisplayName = definition.DisplayName or sinName,
				Weight = definition.Weight or 0,
				Description = definition.Description or "",
				Color = definition.Color or Color3.new(1, 1, 1),
			}
		end
	end

	return {
		Shards = player:GetAttribute("SinShards") or 0,
		Slots = getPlayerSinSlots(player),
		Definitions = publicDefinitions,
		RollOrder = config.RollOrder or {},
		RollCost = config.RollCost or 1,
		CurrencyName = GameConfig.CurrencyName or "Auracoins",
	}
end

function SinService:Roll(player, slotIndex)
	setupPlayerDefaults(player)

	local config = getSinsConfig()
	local cost = config.RollCost or 1
	local shards = player:GetAttribute("SinShards") or 0

	slotIndex = math.floor(tonumber(slotIndex) or 1)
	slotIndex = math.clamp(slotIndex, 1, config.SlotCount or 3)

	if shards < cost then
		return {
			Success = false,
			Message = "Not enough SinShards.",
			State = self:GetState(player),
		}
	end

	local rolledSin = chooseRandomSin()

	if not rolledSin then
		return {
			Success = false,
			Message = "No sins configured.",
			State = self:GetState(player),
		}
	end

	player:SetAttribute("SinShards", shards - cost)
	player:SetAttribute(getSlotName(slotIndex), rolledSin)

	applySinEffects(player)
	sendState(player)

	return {
		Success = true,
		RolledSin = rolledSin,
		SlotIndex = slotIndex,
		State = self:GetState(player),
	}
end

local function addShardProgress(player)
	local config = getSinsConfig()
	local every = config.ShardEveryFloors or 5

	if every <= 0 then
		return
	end

	local currentFloor = math.floor(player:GetAttribute("CurrentFloor") or 0)
	local currentMilestone = math.floor(currentFloor / every)
	local lastMilestone = player:GetAttribute("LastSinShardMilestone") or 0

	if currentFloor <= 0 then
		if lastMilestone ~= 0 then
			player:SetAttribute("LastSinShardMilestone", 0)
		end

		return
	end

	if currentMilestone > lastMilestone then
		local gained = currentMilestone - lastMilestone
		player:SetAttribute("LastSinShardMilestone", currentMilestone)
		player:SetAttribute("SinShards", (player:GetAttribute("SinShards") or 0) + gained)
		sendState(player)
	end
end

local function saveSnapshot(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")

	if not root then
		return
	end

	local now = os.clock()

	if lastSnapshotAt[player] and now - lastSnapshotAt[player] < 2 then
		return
	end

	lastSnapshotAt[player] = now

	snapshots[player] = snapshots[player] or {}

	table.insert(snapshots[player], {
		Time = now,
		CFrame = root.CFrame,
		CurrentFloor = player:GetAttribute("CurrentFloor") or 0,
		CurrentStuds = player:GetAttribute("CurrentStuds") or 0,
		RunBestStuds = player:GetAttribute("RunBestStuds") or 0,
		Insanity = player:GetAttribute("Insanity") or 0,
		Stamina = player:GetAttribute("Stamina") or 100,
	})

	while #snapshots[player] > 45 do
		table.remove(snapshots[player], 1)
	end
end

local function getSnapshotFromSecondsAgo(player, secondsAgo)
	local list = snapshots[player]

	if not list or #list == 0 then
		return nil
	end

	local targetTime = os.clock() - secondsAgo
	local best = list[1]
	local bestDelta = math.abs(best.Time - targetTime)

	for _, snapshot in ipairs(list) do
		local delta = math.abs(snapshot.Time - targetTime)

		if delta < bestDelta then
			best = snapshot
			bestDelta = delta
		end
	end

	return best
end

local function tryPrepareEnvyRewind(player)
	if not hasSin(player, "Envy") then
		return
	end

	local config = getSinsConfig()
	local cooldown = config.EnvyCooldown or 180
	local lastUse = player:GetAttribute("LastEnvyUse") or -999999
	local now = os.clock()

	if cooldown > 0 and now - lastUse < cooldown then
		return
	end

	local snapshot = getSnapshotFromSecondsAgo(player, config.EnvyRewindSeconds or 60)

	if not snapshot then
		return
	end

	player:SetAttribute("LastEnvyUse", now)

	pendingEnvyRewind[player] = snapshot
end

local function applyPendingEnvyRewind(player, character)
	local snapshot = pendingEnvyRewind[player]

	if not snapshot then
		return
	end

	pendingEnvyRewind[player] = nil

	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root then
		return
	end

	task.wait(0.45)

	root.CFrame = snapshot.CFrame + Vector3.new(0, 4, 0)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero

	player:SetAttribute("CurrentFloor", snapshot.CurrentFloor or 0)
	player:SetAttribute("CurrentStuds", snapshot.CurrentStuds or 0)
	player:SetAttribute("RunBestStuds", snapshot.RunBestStuds or 0)
	player:SetAttribute("Insanity", snapshot.Insanity or 0)
	player:SetAttribute("Stamina", snapshot.Stamina or 100)

	print("[SinService] Envy rewind applied for", player.Name)
end

local function rewardGluttonyIfPushKill(victimPlayer)
	local pushedByUserId = victimPlayer:GetAttribute("LastPushedByUserId")
	local pushedAt = victimPlayer:GetAttribute("LastPushedAt")

	if not pushedByUserId or not pushedAt then
		return
	end

	local config = getSinsConfig()
	local window = config.GluttonyPushKillWindow or 8

	if os.clock() - pushedAt > window then
		return
	end

	local pusher = Players:GetPlayerByUserId(pushedByUserId)

	if not pusher then
		return
	end

	if not hasSin(pusher, "Gluttony") then
		return
	end

	pusher:SetAttribute("Stamina", 100)
	pusher:SetAttribute("Insanity", 0)

	sendState(pusher)

	print("[SinService] Gluttony reward applied to", pusher.Name)
end

local function setupCharacter(player, character)
	applyPendingEnvyRewind(player, character)

	local humanoid = character:WaitForChild("Humanoid", 10)

	if humanoid then
		humanoid.Died:Connect(function()
			tryPrepareEnvyRewind(player)
			rewardGluttonyIfPushKill(player)
		end)
	end
end

local function updateLustAuras()
	local definitions = getDefinitions()
	local lust = definitions.Lust

	if not lust then
		return
	end

	local radius = lust.LustRadius or 40
	local boost = lust.LustRunSpeedMultiplier or 1.03

	for _, player in ipairs(Players:GetPlayers()) do
		player:SetAttribute("SinLustRunSpeedMultiplier", 1)
	end

	local lustPlayers = {}

	for _, player in ipairs(Players:GetPlayers()) do
		if hasSin(player, "Lust") then
			table.insert(lustPlayers, player)
		end
	end

	for _, sourcePlayer in ipairs(lustPlayers) do
		local sourceRoot = sourcePlayer.Character and sourcePlayer.Character:FindFirstChild("HumanoidRootPart")

		if sourceRoot then
			for _, targetPlayer in ipairs(Players:GetPlayers()) do
				local targetRoot = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")

				if targetRoot and (targetRoot.Position - sourceRoot.Position).Magnitude <= radius then
					local current = targetPlayer:GetAttribute("SinLustRunSpeedMultiplier") or 1
					targetPlayer:SetAttribute("SinLustRunSpeedMultiplier", math.max(current, boost))
				end
			end
		end
	end
end

function SinService:Start()
	setupRemotes()

	getSinStateRemote.OnServerInvoke = function(player)
		setupPlayerDefaults(player)
		return self:GetState(player)
	end

	rollSinRemote.OnServerInvoke = function(player, slotIndex)
		return self:Roll(player, slotIndex)
	end

	equipSinRemote.OnServerEvent:Connect(function(player)
		setupPlayerDefaults(player)
		applySinEffects(player)
		sendState(player)
	end)

	Players.PlayerAdded:Connect(function(player)
		setupPlayerDefaults(player)

		player.CharacterAdded:Connect(function(character)
			setupCharacter(player, character)
		end)

		if player.Character then
			setupCharacter(player, player.Character)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		snapshots[player] = nil
		pendingEnvyRewind[player] = nil
		lastSnapshotAt[player] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayerDefaults(player)

		if player.Character then
			setupCharacter(player, player.Character)
		end
	end

	local lustTimer = 0

	RunService.Heartbeat:Connect(function(dt)
		lustTimer += dt

		for _, player in ipairs(Players:GetPlayers()) do
			addShardProgress(player)
			saveSnapshot(player)
		end

		if lustTimer >= 1 then
			lustTimer = 0
			updateLustAuras()
		end
	end)

	print("[SinService] Started.")
end

return SinService