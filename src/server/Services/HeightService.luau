local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local HeightService = {}

local airborneSince = {}
local airborneStartY = {}
local ragdollStarted = {}
local recoveryScheduled = {}
local fallStartedSent = {}

local ragdollService = nil

local function getFallConfig()
	return GameConfig.FallKillSystem or {}
end

local function getRagdollService()
	if ragdollService ~= nil then
		return ragdollService
	end

	local success, result = pcall(function()
		return require(script.Parent:WaitForChild("RagdollService"))
	end)

	if success and type(result) == "table" then
		ragdollService = result
	else
		warn("[HeightService] RagdollService unavailable:", result)
		ragdollService = false
	end

	return ragdollService
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

local function getRoot(character)
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(character)
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function isRagdolled(character)
	return character and character:GetAttribute("IsRagdolled") == true
end

local function getSpawnY()
	local spawnPosition = GameConfig.SpawnPosition

	if typeof(spawnPosition) == "Vector3" then
		return spawnPosition.Y
	end

	return 0
end

local function getStudsFromY(y)
	return math.max(0, y - getSpawnY())
end

local function getFloorFromStuds(studs)
	local segmentHeight = GameConfig.StairSegmentHeight or 180

	if segmentHeight <= 0 then
		return 0
	end

	return math.max(0, math.floor(studs / segmentHeight))
end

local function updateHeightAttributes(player, root)
	local currentStuds = getStudsFromY(root.Position.Y)
	local currentFloor = getFloorFromStuds(currentStuds)

	local runBestStuds = math.max(
		currentStuds,
		tonumber(player:GetAttribute("RunBestStuds")) or 0
	)

	local bestStuds = math.max(
		runBestStuds,
		tonumber(player:GetAttribute("BestStuds")) or 0
	)

	local bestFloor = math.max(
		currentFloor,
		tonumber(player:GetAttribute("BestFloor")) or 0
	)

	player:SetAttribute("CurrentStuds", currentStuds)
	player:SetAttribute("CurrentFloor", currentFloor)
	player:SetAttribute("RunBestStuds", runBestStuds)
	player:SetAttribute("BestStuds", bestStuds)
	player:SetAttribute("BestFloor", bestFloor)
end

local function sendFallStarted(player)
	if fallStartedSent[player] then
		return
	end

	fallStartedSent[player] = true
	getOrCreateRemoteEvent("FallStarted"):FireClient(player)
end

local function killPlayer(player)
	local character = player.Character
	local humanoid = getHumanoid(character)

	if not humanoid or humanoid.Health <= 0 then
		return
	end

	getOrCreateRemoteEvent("ForceBlackScreen"):FireClient(player)
	humanoid.Health = 0
end

local function ragdollCharacter(player, character)
	if ragdollStarted[player] then
		return
	end

	ragdollStarted[player] = os.clock()

	local service = getRagdollService()

	if service and type(service.RagdollCharacter) == "function" then
		service:RagdollCharacter(character)
	else
		character:SetAttribute("IsRagdolled", true)
	end

	sendFallStarted(player)
end

local function unragdollCharacter(player)
	local character = player.Character

	if not character or not character.Parent then
		return
	end

	local humanoid = getHumanoid(character)

	if not humanoid or humanoid.Health <= 0 then
		return
	end

	local service = getRagdollService()

	if service and type(service.UnragdollCharacter) == "function" then
		service:UnragdollCharacter(character)
	else
		character:SetAttribute("IsRagdolled", false)

		humanoid.PlatformStand = false
		humanoid.AutoRotate = true
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end

	ragdollStarted[player] = nil
	recoveryScheduled[player] = nil
	fallStartedSent[player] = nil

	print("[HeightService] Player recovered from ragdoll:", player.Name)
end

local function shouldActivateRagdoll(player, humanoid, root)
	local config = getFallConfig()

	if config.Enabled == false then
		return false
	end

	if humanoid.Health <= 0 then
		return false
	end

	local currentStuds = tonumber(player:GetAttribute("CurrentStuds")) or 0
	local minimumStuds = config.MinimumStudsBeforeFallKill or GameConfig.MinimumStudsBeforeFallKill or 15

	if currentStuds < minimumStuds then
		return false
	end

	if humanoid.FloorMaterial ~= Enum.Material.Air then
		return false
	end

	local startY = airborneStartY[player] or root.Position.Y
	local fallDistance = math.max(0, startY - root.Position.Y)
	local velocityY = root.AssemblyLinearVelocity.Y

	local minFallDistance = config.MinFallDistanceToRagdoll or 22
	local velocityThreshold = config.VelocityYToRagdoll or -28

	if fallDistance >= minFallDistance then
		return true
	end

	if velocityY <= velocityThreshold then
		return true
	end

	return false
end

local function isGroundedWhileRagdolled(player, character, humanoid, root)
	if not isRagdolled(character) then
		return false
	end

	local startedAt = ragdollStarted[player]

	if not startedAt then
		return false
	end

	-- Évite de se relever immédiatement au moment où le ragdoll vient de s'activer.
	if os.clock() - startedAt < 0.45 then
		return false
	end

	if humanoid.FloorMaterial ~= Enum.Material.Air then
		return true
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	params.IgnoreWater = true

	local result = workspace:Raycast(
		root.Position,
		Vector3.new(0, -5.5, 0),
		params
	)

	if result then
		return true
	end

	return false
end

local function scheduleRecovery(player)
	if recoveryScheduled[player] then
		return
	end

	recoveryScheduled[player] = true

	task.delay(0.65, function()
		local character = player.Character
		local humanoid = getHumanoid(character)
		local root = getRoot(character)

		if not character or not humanoid or not root then
			recoveryScheduled[player] = nil
			return
		end

		if humanoid.Health <= 0 then
			recoveryScheduled[player] = nil
			return
		end

		if isGroundedWhileRagdolled(player, character, humanoid, root) then
			unragdollCharacter(player)
		else
			recoveryScheduled[player] = nil
		end
	end)
end

local function updateAirborneState(player, humanoid, root)
	if isRagdolled(player.Character) then
		return
	end

	if humanoid.FloorMaterial == Enum.Material.Air then
		if not airborneSince[player] then
			airborneSince[player] = os.clock()
			airborneStartY[player] = root.Position.Y
		end
	else
		airborneSince[player] = nil
		airborneStartY[player] = nil
	end
end

local function applyRagdollFallForces(character, dt)
	if not character or character:GetAttribute("IsRagdolled") ~= true then
		return
	end

	local service = getRagdollService()

	if service then
		if type(service.ApplyCenterPull) == "function" then
			service:ApplyCenterPull(character, dt)
		end

		if type(service.ApplyFallPhysics) == "function" then
			service:ApplyFallPhysics(character, dt)
		end
	end
end

local function updatePlayer(player, dt)
	local character = player.Character
	local humanoid = getHumanoid(character)
	local root = getRoot(character)

	if not character or not humanoid or not root then
		return
	end

	if humanoid.Health <= 0 then
		return
	end

	updateHeightAttributes(player, root)

	local config = getFallConfig()
	local absoluteDeathY = config.AbsoluteDeathY or -120

	-- Garde juste une sécurité si le joueur sort totalement de la map.
	if root.Position.Y <= absoluteDeathY then
		killPlayer(player)
		return
	end

	updateAirborneState(player, humanoid, root)

	if not isRagdolled(character) and shouldActivateRagdoll(player, humanoid, root) then
		ragdollCharacter(player, character)
	end

	if isRagdolled(character) then
		applyRagdollFallForces(character, dt)

		if isGroundedWhileRagdolled(player, character, humanoid, root) then
			scheduleRecovery(player)
		end
	end
end

local function resetPlayerFallState(player)
	airborneSince[player] = nil
	airborneStartY[player] = nil
	ragdollStarted[player] = nil
	recoveryScheduled[player] = nil
	fallStartedSent[player] = nil
end

local function setupCharacter(player, character)
	resetPlayerFallState(player)

	character:SetAttribute("IsRagdolled", false)

	local humanoid = character:WaitForChild("Humanoid", 10)

	if humanoid then
		humanoid.PlatformStand = false
		humanoid.AutoRotate = true
		humanoid.RequiresNeck = false

		if humanoid.RigType == Enum.HumanoidRigType.R6 then
			humanoid.HipHeight = 0
		end

		pcall(function()
			humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
			humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, true)
		end)
	end
end

local function setupPlayer(player)
	player:SetAttribute("CurrentStuds", 0)
	player:SetAttribute("CurrentFloor", 0)
	player:SetAttribute("RunBestStuds", 0)

	if player:GetAttribute("BestStuds") == nil then
		player:SetAttribute("BestStuds", 0)
	end

	if player:GetAttribute("BestFloor") == nil then
		player:SetAttribute("BestFloor", 0)
	end

	player.CharacterAdded:Connect(function(character)
		setupCharacter(player, character)
	end)

	player.CharacterRemoving:Connect(function()
		resetPlayerFallState(player)
	end)

	if player.Character then
		setupCharacter(player, player.Character)
	end
end

function HeightService:Start()
	getOrCreateRemoteEvent("FallStarted")
	getOrCreateRemoteEvent("ForceBlackScreen")

	Players.PlayerAdded:Connect(setupPlayer)

	Players.PlayerRemoving:Connect(function(player)
		resetPlayerFallState(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	RunService.Heartbeat:Connect(function(dt)
		for _, player in ipairs(Players:GetPlayers()) do
			updatePlayer(player, dt)
		end
	end)

	print("[HeightService] Started ragdoll recovery system.")
end

return HeightService