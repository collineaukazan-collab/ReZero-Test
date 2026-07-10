local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local HeightService = {}

local airborneSince = {}
local airborneHighestY = {}
local previousPartPositions = {}

local fallStartedSent = {}
local ragdollStartedAt = {}
local deathDebounce = {}
local touchConnections = {}

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

	local runBestStuds = math.max(currentStuds, tonumber(player:GetAttribute("RunBestStuds")) or 0)
	local bestStuds = math.max(runBestStuds, tonumber(player:GetAttribute("BestStuds")) or 0)
	local bestFloor = math.max(currentFloor, tonumber(player:GetAttribute("BestFloor")) or 0)

	player:SetAttribute("CurrentStuds", currentStuds)
	player:SetAttribute("CurrentFloor", currentFloor)
	player:SetAttribute("RunBestStuds", runBestStuds)
	player:SetAttribute("BestStuds", bestStuds)
	player:SetAttribute("BestFloor", bestFloor)
end

local function getImpactFolder()
	local folder = workspace:FindFirstChild("ImpactMarks")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "ImpactMarks"
		folder.Parent = workspace
	end
	return folder
end

local function getCorpseFolder()
	local folder = workspace:FindFirstChild("Corpses")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Corpses"
		folder.Parent = workspace
	end
	return folder
end

local function createImpactMark(position)
	local config = GameConfig.ImpactMarks or {}
	if config.Enabled == false then
		return
	end

	local folder = getImpactFolder()
	local size = config.Size or 6

	local mark = Instance.new("Part")
	mark.Name = "ImpactMark"
	mark.Shape = Enum.PartType.Cylinder
	mark.Anchored = true
	mark.CanCollide = false
	mark.CanTouch = false
	mark.CanQuery = false
	mark.Size = Vector3.new(0.06, size, size)
	mark.CFrame = CFrame.new(position + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, 0, math.rad(90))
	mark.Material = Enum.Material.SmoothPlastic
	mark.Color = (config.Color or Color3.fromRGB(145, 12, 18))
	mark.Transparency = config.Transparency or 0.08
	mark.Parent = folder

	Debris:AddItem(mark, config.Lifetime or 120)
end

local function isOtherCharacterPart(hit)
	local model = hit and hit:FindFirstAncestorOfClass("Model")
	if not model then
		return false
	end
	return Players:GetPlayerFromCharacter(model) ~= nil
end

local function isValidGroundHit(character, hit)
	if not hit then
		return false
	end

	if hit == workspace.Terrain then
		return true
	end

	if hit:IsDescendantOf(character) then
		return false
	end

	if isOtherCharacterPart(hit) then
		return false
	end

	if hit:IsA("BasePart") then
		return hit.CanCollide == true
	end

	return false
end

local function canGroundKill(player, character)
	if not isRagdolled(character) then
		return false
	end

	local startedAt = ragdollStartedAt[player]
	if not startedAt then
		return false
	end

	local config = getFallConfig()
	local delayTime = config.RagdollGroundKillDelay or 0.12

	return os.clock() - startedAt >= delayTime
end

local function makeCorpse(character, impactPosition)
	if not character or not character.Parent then
		return
	end

	if typeof(impactPosition) ~= "Vector3" then
		return
	end

	local corpseFolder = getCorpseFolder()

	local oldArchivable = character.Archivable
	character.Archivable = true

	local clone = nil

	local success, result = pcall(function()
		return character:Clone()
	end)

	character.Archivable = oldArchivable

	if success then
		clone = result
	end

	if not clone then
		warn("[HeightService] Corpse clone failed:", character.Name)
		return
	end

	clone.Name = character.Name .. "_Corpse"
	clone.Parent = corpseFolder

	for _, obj in ipairs(clone:GetDescendants()) do
		if obj:IsA("Script") or obj:IsA("LocalScript") then
			obj:Destroy()
		elseif obj:IsA("Humanoid") then
			obj.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			obj.Health = 0
			obj.BreakJointsOnDeath = false
			obj.PlatformStand = true
		elseif obj:IsA("BasePart") then
			obj.Anchored = true
			obj.CanCollide = true
			obj.CanTouch = false
			obj.CanQuery = true
			obj.AssemblyLinearVelocity = Vector3.zero
			obj.AssemblyAngularVelocity = Vector3.zero

			pcall(function()
				obj.CollisionGroup = "Default"
			end)
		end
	end

	-- On garde la pose actuelle du ragdoll,
	-- puis on pose tout le clone sur le sol.
	local lowestY = math.huge

	for _, obj in ipairs(clone:GetDescendants()) do
		if obj:IsA("BasePart") then
			local bottomY = obj.Position.Y - (obj.Size.Y / 2)
			if bottomY < lowestY then
				lowestY = bottomY
			end
		end
	end

	if lowestY == math.huge then
		clone:Destroy()
		return
	end

	local offsetY = (impactPosition.Y + 0.08) - lowestY

	for _, obj in ipairs(clone:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Position += Vector3.new(0, offsetY, 0)
		end
	end

	Debris:AddItem(clone, 120)
end

local function killPlayer(player, impactPosition)
	if deathDebounce[player] then
		return
	end

	deathDebounce[player] = true

	local character = player.Character
	local humanoid = getHumanoid(character)

	if not humanoid or humanoid.Health <= 0 then
		return
	end

	if typeof(impactPosition) == "Vector3" then
		pcall(function()
			createImpactMark(impactPosition)
		end)

		pcall(function()
			makeCorpse(character, impactPosition)
		end)
	end

	getOrCreateRemoteEvent("ForceBlackScreen"):FireClient(player)

	-- La mort doit toujours arriver, même si corpse/impact bug.
	humanoid.Health = 0

	task.delay(0.1, function()
		if humanoid and humanoid.Parent and humanoid.Health > 0 then
			humanoid.Health = 0
		end
	end)
end

local function disconnectTouches(player)
	local connections = touchConnections[player]
	if connections then
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
	end
	touchConnections[player] = nil
end

local function setupTouchDeath(player, character)
	disconnectTouches(player)
	touchConnections[player] = {}

	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanTouch = true
			part.CanQuery = true

			local connection = part.Touched:Connect(function(hit)
				if not canGroundKill(player, character) then
					return
				end

				if not isValidGroundHit(character, hit) then
					return
				end

				killPlayer(player, part.Position)
			end)

			table.insert(touchConnections[player], connection)
		end
	end
end

local function segmentPartImpactKill(player, character)
	if not canGroundKill(player, character) then
		return false
	end

	local previousMap = previousPartPositions[player]
	if not previousMap then
		return false
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	params.IgnoreWater = true

	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			local previous = previousMap[part]
			local current = part.Position

			if previous then
				local direction = current - previous
				if direction.Magnitude > 0.1 then
					local result = workspace:Raycast(previous, direction, params)
					if result and isValidGroundHit(character, result.Instance) then
						return result.Position
					end
				end
			end
		end
	end

	return false
end

local function raycastGroundKill(player, character)
	if not canGroundKill(player, character) then
		return false
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	params.IgnoreWater = true

	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			local distance = math.clamp(part.Size.Magnitude * 0.9, 5, 14)
			local result = workspace:Raycast(
				part.Position + Vector3.new(0, 1.5, 0),
				Vector3.new(0, -distance, 0),
				params
			)

			if result and isValidGroundHit(character, result.Instance) then
				return result.Position
			end
		end
	end

	return false
end

local function overlapGroundKill(player, character)
	if not canGroundKill(player, character) then
		return false
	end

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }

	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			local touching = workspace:GetPartBoundsInBox(
				part.CFrame,
				part.Size + Vector3.new(0.55, 0.55, 0.55),
				params
			)

			for _, hit in ipairs(touching) do
				if isValidGroundHit(character, hit) then
					return part.Position
				end
			end
		end
	end

	return false
end

local function updatePreviousPartPositions(player, character)
	local map = {}
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			map[part] = part.Position
		end
	end
	previousPartPositions[player] = map
end

local function sendFallStarted(player)
	if fallStartedSent[player] then
		return
	end

	fallStartedSent[player] = true
	getOrCreateRemoteEvent("FallStarted"):FireClient(player)
end

local function startRagdoll(player, character)
	if ragdollStartedAt[player] then
		return
	end

	ragdollStartedAt[player] = os.clock()

	local service = getRagdollService()
	if service and type(service.RagdollCharacter) == "function" then
		pcall(function()
			service:RagdollCharacter(character)
		end)
	elseif service and type(service.RagdollPlayer) == "function" then
		pcall(function()
			service:RagdollPlayer(player)
		end)
	else
		character:SetAttribute("IsRagdolled", true)
	end

	character:SetAttribute("IsRagdolled", true)
	setupTouchDeath(player, character)
	sendFallStarted(player)
end

local function registerExternalRagdoll(player, character)
	if ragdollStartedAt[player] then
		return
	end

	ragdollStartedAt[player] = os.clock()
	setupTouchDeath(player, character)
	sendFallStarted(player)
end

local function shouldStartRagdoll(player, humanoid, root)
	local config = getFallConfig()

	if config.Enabled == false then
		return false
	end

	if humanoid.Health <= 0 then
		return false
	end

	local currentStuds = tonumber(player:GetAttribute("CurrentStuds")) or 0
	local minimumStuds = config.MinimumStudsBeforeFallKill or 5

	if currentStuds < minimumStuds then
		return false
	end

	if humanoid.FloorMaterial ~= Enum.Material.Air then
		return false
	end

	local airStart = airborneSince[player]
	local highestY = airborneHighestY[player] or root.Position.Y

	if not airStart then
		return false
	end

	local airTime = os.clock() - airStart
	local fallDistance = math.max(0, highestY - root.Position.Y)
	local velocityY = root.AssemblyLinearVelocity.Y

	local minAirTime = config.MinimumAirTime or 0.45
	local minFallDistance = config.MinFallDistanceToRagdoll or 24
	local velocityThreshold = config.VelocityYToRagdoll or -32

	if airTime < minAirTime then
		return false
	end

	if fallDistance < minFallDistance then
		return false
	end

	if velocityY > velocityThreshold then
		return false
	end

	return true
end

local function updateAirborneState(player, humanoid, root)
	if isRagdolled(player.Character) then
		return
	end

	if humanoid.FloorMaterial == Enum.Material.Air then
		if not airborneSince[player] then
			airborneSince[player] = os.clock()
			airborneHighestY[player] = root.Position.Y
		else
			airborneHighestY[player] = math.max(airborneHighestY[player] or root.Position.Y, root.Position.Y)
		end
	else
		airborneSince[player] = nil
		airborneHighestY[player] = nil
	end
end

local function applyRagdollFallForces(character, dt)
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
	local absoluteDeathY = config.AbsoluteDeathY or -160

	if root.Position.Y <= absoluteDeathY then
		killPlayer(player, root.Position)
		return
	end

	updateAirborneState(player, humanoid, root)

	if not isRagdolled(character) and shouldStartRagdoll(player, humanoid, root) then
		startRagdoll(player, character)
	end

	if isRagdolled(character) then
		if not ragdollStartedAt[player] then
			registerExternalRagdoll(player, character)
		end

		applyRagdollFallForces(character, dt)

		local impact =
			segmentPartImpactKill(player, character)
			or raycastGroundKill(player, character)
			or overlapGroundKill(player, character)

		if impact then
			killPlayer(player, impact)
		end
	end

	updatePreviousPartPositions(player, character)
end

local function resetPlayerState(player)
	airborneSince[player] = nil
	airborneHighestY[player] = nil
	previousPartPositions[player] = nil
	fallStartedSent[player] = nil
	ragdollStartedAt[player] = nil
	deathDebounce[player] = nil
	disconnectTouches(player)
end

local function setupCharacter(player, character)
	resetPlayerState(player)

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
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
		end)
	end

	updatePreviousPartPositions(player, character)
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
		resetPlayerState(player)
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
		resetPlayerState(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	RunService.Heartbeat:Connect(function(dt)
		for _, player in ipairs(Players:GetPlayers()) do
			updatePlayer(player, dt)
		end
	end)

	print("[HeightService] Started fixed impacts + corpse + insanity horizontal push.")
end

return HeightService