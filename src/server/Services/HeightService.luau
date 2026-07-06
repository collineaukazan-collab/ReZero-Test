local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local HeightService = {}

local airborneSince = {}
local airborneStartY = {}
local fallStartedSent = {}

local ragdollService = nil

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
		warn("[HeightService] RagdollService not available:", result)
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

local function isRagdolled(character)
	return character and character:GetAttribute("IsRagdolled") == true
end

local function basicRagdollFallback(character)
	local humanoid = getHumanoid(character)
	local root = getRoot(character)

	if not humanoid or not root then
		return
	end

	character:SetAttribute("IsRagdolled", true)

	humanoid.PlatformStand = true
	humanoid.AutoRotate = false
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)

	pcall(function()
		humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	end)

	root.AssemblyAngularVelocity = Vector3.new(
		math.random(-4, 4),
		math.random(-4, 4),
		math.random(-4, 4)
	)
end

local function callRagdollService(player, character)
	local service = getRagdollService()

	if not service then
		basicRagdollFallback(character)
		return
	end

	local called = false

	local possibleCalls = {
		function()
			if type(service.RagdollPlayer) == "function" then
				service:RagdollPlayer(player)
				return true
			end
		end,

		function()
			if type(service.RagdollCharacter) == "function" then
				service:RagdollCharacter(character)
				return true
			end
		end,

		function()
			if type(service.RagdollCharacter) == "function" then
				service:RagdollCharacter(player, character)
				return true
			end
		end,

		function()
			if type(service.ragdollCharacter) == "function" then
				service:ragdollCharacter(character)
				return true
			end
		end,
	}

	for _, callback in ipairs(possibleCalls) do
		local success, result = pcall(callback)

		if success and result == true then
			called = true
			break
		end
	end

	task.delay(0.05, function()
		if character and character.Parent and character:GetAttribute("IsRagdolled") ~= true then
			basicRagdollFallback(character)
		end
	end)

	if not called then
		basicRagdollFallback(character)
	end
end

local function shouldStartRagdoll(player, character, humanoid, root)
	if isRagdolled(character) then
		return false
	end

	if humanoid.Health <= 0 then
		return false
	end

	local currentStuds = tonumber(player:GetAttribute("CurrentStuds")) or 0
	local minimumStuds = GameConfig.MinimumStudsBeforeFallKill or 15

	if currentStuds < minimumStuds then
		return false
	end

	local airTime = 0

	if airborneSince[player] then
		airTime = os.clock() - airborneSince[player]
	end

	local startY = airborneStartY[player] or root.Position.Y
	local fallDistance = math.max(0, startY - root.Position.Y)
	local velocityY = root.AssemblyLinearVelocity.Y

	if airTime < (GameConfig.RagdollMinAirTime or 0.35) then
		return false
	end

	if fallDistance < (GameConfig.RagdollMinFallDistance or 18) then
		return false
	end

	if velocityY > (GameConfig.FallingVelocityToRagdoll or -22) then
		return false
	end

	return true
end

local function startRagdoll(player, character)
	callRagdollService(player, character)

	if not fallStartedSent[player] then
		fallStartedSent[player] = true

		local fallStartedRemote = getOrCreateRemoteEvent("FallStarted")
		fallStartedRemote:FireClient(player)
	end
end

local function getFastestDownwardSpeed(root)
	return math.max(0, -root.AssemblyLinearVelocity.Y)
end

local function getDynamicGroundDeathY(root)
	local base = GameConfig.GroundDeathY or 7

	if GameConfig.DynamicGroundDeathEnabled == false then
		return base
	end

	local speed = getFastestDownwardSpeed(root)
	local minSpeed = GameConfig.DynamicGroundDeathMinSpeed or 80
	local maxBonus = GameConfig.DynamicGroundDeathMaxBonus or 45
	local multiplier = GameConfig.DynamicGroundDeathSpeedMultiplier or 0.22

	local bonus = math.clamp((speed - minSpeed) * multiplier, 0, maxBonus)

	return base + bonus
end

local function shouldDieFromFall(player, character, humanoid, root)
	if humanoid.Health <= 0 then
		return false
	end

	if root.Position.Y <= (GameConfig.FallDeathY or -25) then
		return true
	end

	if not isRagdolled(character) then
		return false
	end

	local currentStuds = tonumber(player:GetAttribute("CurrentStuds")) or 0
	local minimumStuds = GameConfig.MinimumStudsBeforeFallKill or 15

	if currentStuds < minimumStuds then
		return false
	end

	local groundDeathY = getDynamicGroundDeathY(root)

	return root.Position.Y <= groundDeathY
end

local function applyFallForces(character, dt)
	if not isRagdolled(character) then
		return
	end

	local service = getRagdollService()

	if service then
		if type(service.ApplyCenterPull) == "function" then
			pcall(function()
				service:ApplyCenterPull(character, dt)
			end)
		end

		if type(service.ApplyFallPhysics) == "function" then
			pcall(function()
				service:ApplyFallPhysics(character, dt)
			end)
		end
	end

	local root = getRoot(character)

	if root and GameConfig.FallAccelerationEnabled ~= false then
		local velocity = root.AssemblyLinearVelocity
		local maxFallSpeed = GameConfig.MaxFallSpeed or -420
		local acceleration = GameConfig.FallAcceleration or 120

		local newY = math.max(maxFallSpeed, math.min(velocity.Y, 0) - acceleration * dt)

		root.AssemblyLinearVelocity = Vector3.new(
			velocity.X,
			newY,
			velocity.Z
		)
	end
end

local function killFromFall(player, humanoid)
	local blackScreenRemote = getOrCreateRemoteEvent("ForceBlackScreen")
	blackScreenRemote:FireClient(player)

	humanoid.Health = 0
end

local function updateAirborneState(player, humanoid, root)
	if humanoid.FloorMaterial == Enum.Material.Air then
		if not airborneSince[player] then
			airborneSince[player] = os.clock()
			airborneStartY[player] = root.Position.Y
		end
	else
		airborneSince[player] = nil
		airborneStartY[player] = nil
		fallStartedSent[player] = nil
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
	updateAirborneState(player, humanoid, root)

	if shouldStartRagdoll(player, character, humanoid, root) then
		startRagdoll(player, character)
	end

	applyFallForces(character, dt)

	if shouldDieFromFall(player, character, humanoid, root) then
		killFromFall(player, humanoid)
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
		airborneSince[player] = nil
		airborneStartY[player] = nil
		fallStartedSent[player] = nil

		character:SetAttribute("IsRagdolled", false)

		local humanoid = character:WaitForChild("Humanoid", 10)

		if humanoid then
			humanoid.PlatformStand = false
			humanoid.AutoRotate = true

			pcall(function()
				humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
			end)
		end
	end)

	player.CharacterRemoving:Connect(function()
		airborneSince[player] = nil
		airborneStartY[player] = nil
		fallStartedSent[player] = nil
	end)
end

function HeightService:Start()
	getOrCreateRemoteEvent("FallStarted")
	getOrCreateRemoteEvent("ForceBlackScreen")

	Players.PlayerAdded:Connect(setupPlayer)

	Players.PlayerRemoving:Connect(function(player)
		airborneSince[player] = nil
		airborneStartY[player] = nil
		fallStartedSent[player] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	RunService.Heartbeat:Connect(function(dt)
		for _, player in ipairs(Players:GetPlayers()) do
			updatePlayer(player, dt)
		end
	end)

	print("[HeightService] Started.")
end

return HeightService