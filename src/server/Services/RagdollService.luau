local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local RagdollService = {}

local random = Random.new()

local function getOrCreateFolder(parent, name)
	local folder = parent:FindFirstChild(name)

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = parent
	end

	return folder
end

local function getOrCreateRemote(name)
	local remotes = getOrCreateFolder(ReplicatedStorage, "Remotes")
	local remote = remotes:FindFirstChild(name)

	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = remotes
	end

	return remote
end

local function getTorso(character)
	return character:FindFirstChild("Torso")
end

local function isR6(character)
	return character:FindFirstChild("Torso")
		and character:FindFirstChild("Head")
		and character:FindFirstChild("Left Arm")
		and character:FindFirstChild("Right Arm")
		and character:FindFirstChild("Left Leg")
		and character:FindFirstChild("Right Leg")
end

local function isRuntimeObject(instance)
	return instance:IsA("Script")
		or instance:IsA("LocalScript")
		or instance:IsA("VectorForce")
		or instance:IsA("LinearVelocity")
		or instance:IsA("BodyVelocity")
		or instance:IsA("BodyGyro")
		or instance:IsA("AngularVelocity")
		or instance:IsA("BallSocketConstraint")
		or instance:IsA("Attachment")
		or instance:IsA("Motor6D")
end

local function createLooseSocket(motor)
	local part0 = motor.Part0
	local part1 = motor.Part1

	if not part0 or not part1 then
		return
	end

	local attachment0 = Instance.new("Attachment")
	attachment0.Name = motor.Name .. "_RagdollAttachment0"
	attachment0.CFrame = motor.C0
	attachment0.Parent = part0

	local attachment1 = Instance.new("Attachment")
	attachment1.Name = motor.Name .. "_RagdollAttachment1"
	attachment1.CFrame = motor.C1
	attachment1.Parent = part1

	local socket = Instance.new("BallSocketConstraint")
	socket.Name = motor.Name .. "_LooseRagdollSocket"
	socket.Attachment0 = attachment0
	socket.Attachment1 = attachment1
	socket.LimitsEnabled = false
	socket.TwistLimitsEnabled = false
	socket.MaxFrictionTorque = 0
	socket.Restitution = 0
	socket.Parent = part0

	motor.Enabled = false
end

local function setupRagdollPhysics(character)
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("Motor6D") then
			createLooseSocket(descendant)
		elseif descendant:IsA("BasePart") then
			descendant.AssemblyAngularVelocity = Vector3.new(
				random:NextNumber(-10, 10),
				random:NextNumber(-10, 10),
				random:NextNumber(-10, 10)
			)

			if descendant.Name == "HumanoidRootPart" then
				descendant.CanCollide = false
				descendant.Transparency = 1
			else
				descendant.CanCollide = true
				descendant.Massless = false
				descendant.CustomPhysicalProperties = PhysicalProperties.new(1, 1, 0, 1, 0)

				descendant:ApplyAngularImpulse(Vector3.new(
					random:NextNumber(-1, 1),
					random:NextNumber(-1, 1),
					random:NextNumber(-1, 1)
				) * descendant.AssemblyMass * 180)
			end
		end
	end
end

local function addCenterVelocity(character)
	local torso = getTorso(character)
	if not torso then
		return
	end

	if torso:FindFirstChild("CenterPullVelocity") then
		return
	end

	local attachment = Instance.new("Attachment")
	attachment.Name = "CenterPullAttachment"
	attachment.Parent = torso

	local velocity = Instance.new("LinearVelocity")
	velocity.Name = "CenterPullVelocity"
	velocity.Attachment0 = attachment
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.MaxForce = GameConfig.CenterPullMaxForce or 2600
	velocity.VectorVelocity = Vector3.zero
	velocity.Parent = torso
end

local function ragdollCharacter(player, character)
	if character:GetAttribute("IsRagdolled") then
		return
	end

	if not isR6(character) then
		warn("[RagdollService] Le personnage n'est pas en R6. Mets Game Settings > Avatar > R6.")
		return
	end

	character.Archivable = true
	character:SetAttribute("IsRagdolled", true)
	character:SetAttribute("RagdollStartedAt", os.clock())
	character:SetAttribute("ImpactCreated", false)
	character:SetAttribute("CorpseCreated", false)

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false
	humanoid.PlatformStand = true
	humanoid.AutoRotate = false

	-- Important : empêcher les états qui peuvent faire "remonter" le perso.
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, false)

	humanoid:ChangeState(Enum.HumanoidStateType.Physics)

	local animate = character:FindFirstChild("Animate")
	if animate then
		animate.Disabled = true
	end

	setupRagdollPhysics(character)
	addCenterVelocity(character)

	getOrCreateRemote("FallStarted"):FireClient(player)
end

function RagdollService:ApplyCenterPull(player)
	local character = player.Character
	if not character or not character:GetAttribute("IsRagdolled") then
		return
	end

	local torso = getTorso(character)
	if not torso then
		return
	end

	local velocityObject = torso:FindFirstChild("CenterPullVelocity")
	if not velocityObject then
		return
	end

	if not GameConfig.CenterPullEnabled then
		velocityObject.VectorVelocity = Vector3.zero
		return
	end

	local center = GameConfig.StairCenter or Vector3.new(0, 0, 0)
	local offset = Vector3.new(center.X - torso.Position.X, 0, center.Z - torso.Position.Z)
	local distance = offset.Magnitude

	local targetRadius = GameConfig.CenterPullTargetRadius or 2
	if distance <= targetRadius then
		velocityObject.VectorVelocity = Vector3.zero
		return
	end

	local direction = offset.Unit
	local speed = GameConfig.CenterPullSpeed or 22

	-- Plus on est loin, plus ça tire, mais toujours uniquement à l'horizontale.
	local scaledSpeed = math.clamp(distance * 0.18, 4, speed)

	velocityObject.MaxForce = GameConfig.CenterPullMaxForce or 2600
	velocityObject.VectorVelocity = Vector3.new(
		direction.X * scaledSpeed,
		0,
		direction.Z * scaledSpeed
	)
end

function RagdollService:ApplyFallPhysics(player, deltaTime)
	if not GameConfig.FallAccelerationEnabled then
		return
	end

	local character = player.Character
	if not character or not character:GetAttribute("IsRagdolled") then
		return
	end

	local torso = getTorso(character)
	if not torso then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	end

	local velocity = torso.AssemblyLinearVelocity
	local acceleration = GameConfig.FallAcceleration or 25
	local maxFallSpeed = GameConfig.MaxFallSpeed or -160

	-- Si le moteur physique essaye de faire remonter le perso,
	-- on annule la remontée.
	local currentY = math.min(velocity.Y, 0)

	local newY = currentY - acceleration * deltaTime
	newY = math.max(newY, maxFallSpeed)

	torso.AssemblyLinearVelocity = Vector3.new(
		velocity.X,
		newY,
		velocity.Z
	)
end

function RagdollService:PushPlayerToCenter(player, horizontalSpeed, downSpeed)
	local character = player.Character
	if not character then
		return
	end

	self:RagdollPlayer(player)

	local torso = getTorso(character)
	if not torso then
		return
	end

	local center = GameConfig.StairCenter or Vector3.new(0, 0, 0)
	local offset = Vector3.new(center.X - torso.Position.X, 0, center.Z - torso.Position.Z)

	if offset.Magnitude <= 1 then
		offset = Vector3.new(1, 0, 0)
	end

	local direction = offset.Unit

	torso.AssemblyLinearVelocity = Vector3.new(
		direction.X * horizontalSpeed,
		downSpeed,
		direction.Z * horizontalSpeed
	)

	torso:ApplyImpulse(Vector3.new(
		direction.X * torso.AssemblyMass * horizontalSpeed * 1.8,
		torso.AssemblyMass * downSpeed * 1.2,
		direction.Z * torso.AssemblyMass * horizontalSpeed * 1.8
	))

	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name ~= "HumanoidRootPart" then
			descendant:ApplyAngularImpulse(Vector3.new(
				random:NextNumber(-1, 1),
				random:NextNumber(-1, 1),
				random:NextNumber(-1, 1)
			) * descendant.AssemblyMass * 420)
		end
	end
end

local function getLowestPart(character)
	local lowestPart = nil
	local lowestY = math.huge

	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name ~= "HumanoidRootPart" then
			local bottomY = descendant.Position.Y - descendant.Size.Y / 2

			if bottomY < lowestY then
				lowestY = bottomY
				lowestPart = descendant
			end
		end
	end

	return lowestPart
end

local function getImpactPosition(character)
	local lowestPart = getLowestPart(character)

	if not lowestPart then
		local center = GameConfig.StairCenter or Vector3.new(0, 0, 0)
		return Vector3.new(center.X, 0, center.Z)
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }

	local result = workspace:Raycast(
		lowestPart.Position + Vector3.new(0, 20, 0),
		Vector3.new(0, -300, 0),
		params
	)

	if result then
		return result.Position
	end

	return Vector3.new(lowestPart.Position.X, 0, lowestPart.Position.Z)
end

local function createRoundImpactMark(player, character, impactPosition)
	if player:GetAttribute("ImpactMarksEnabled") == false then
		return
	end

	if character:GetAttribute("ImpactCreated") then
		return
	end

	character:SetAttribute("ImpactCreated", true)

	local folder = getOrCreateFolder(workspace, "ImpactMarks")

	local mark = Instance.new("Part")
	mark.Name = "RoundImpactMark"
	mark:SetAttribute("OwnerUserId", player.UserId)

	mark.Shape = Enum.PartType.Cylinder
	mark.Anchored = true
	mark.CanCollide = false
	mark.CanTouch = false
	mark.CanQuery = false
	mark.Material = Enum.Material.SmoothPlastic
	mark.Color = Color3.fromRGB(90, 0, 0)
	mark.Transparency = 0.14

	local diameter = random:NextNumber(6, 10)
	local thickness = 0.06

	-- Important :
	-- Dans Roblox, le cylindre est orienté sur l'axe X.
	-- Donc on met l'épaisseur sur X, puis on le tourne pour le poser à plat.
	mark.Size = Vector3.new(thickness, diameter, diameter)

	mark.CFrame =
		CFrame.new(impactPosition + Vector3.new(0, 0.04, 0))
		* CFrame.Angles(0, 0, math.rad(90))

	mark.Parent = folder

	local marks = folder:GetChildren()
	while #marks > GameConfig.MaxImpactMarks do
		marks[1]:Destroy()
		table.remove(marks, 1)
	end
end

local function stripRuntimeObjects(instance)
	for _, descendant in ipairs(instance:GetDescendants()) do
		if isRuntimeObject(descendant) then
			descendant:Destroy()
		end
	end
end

local function getVerticalExtent(part, rotation)
	local right = rotation.RightVector
	local up = rotation.UpVector
	local look = rotation.LookVector
	local size = part.Size

	return 0.5 * (
		math.abs(right.Y) * size.X
			+ math.abs(up.Y) * size.Y
			+ math.abs(look.Y) * size.Z
	)
end

local function placePartGrounded(part, positionXZ, rotation, groundY)
	local extent = getVerticalExtent(part, rotation)
	local position = Vector3.new(positionXZ.X, groundY + extent + 0.03, positionXZ.Z)

	part.CFrame = CFrame.new(position) * rotation
	part.AssemblyLinearVelocity = Vector3.zero
	part.AssemblyAngularVelocity = Vector3.zero
	part.Anchored = true
	part.CanCollide = true
	part.CustomPhysicalProperties = PhysicalProperties.new(1, 1, 0, 1, 0)
end

local function layCorpseOnGround(corpse, impactPosition)
	local yaw = random:NextNumber(0, math.pi * 2)

	local forward = Vector3.new(math.cos(yaw), 0, math.sin(yaw))
	local right = Vector3.new(-forward.Z, 0, forward.X)

	local groundY = impactPosition.Y
	local base = Vector3.new(impactPosition.X, groundY, impactPosition.Z)

	local torso = corpse:FindFirstChild("Torso")
	local head = corpse:FindFirstChild("Head")
	local leftArm = corpse:FindFirstChild("Left Arm")
	local rightArm = corpse:FindFirstChild("Right Arm")
	local leftLeg = corpse:FindFirstChild("Left Leg")
	local rightLeg = corpse:FindFirstChild("Right Leg")
	local root = corpse:FindFirstChild("HumanoidRootPart")

	local flatRotation = CFrame.Angles(math.rad(90), yaw, 0)
	local headRotation = CFrame.Angles(0, yaw, 0)

	if torso then
		placePartGrounded(torso, base, flatRotation, groundY)
	end

	if head then
		placePartGrounded(head, base + forward * 1.55, headRotation, groundY)
	end

	if leftArm then
		placePartGrounded(leftArm, base - right * 1.45, flatRotation * CFrame.Angles(0, 0, math.rad(14)), groundY)
	end

	if rightArm then
		placePartGrounded(rightArm, base + right * 1.45, flatRotation * CFrame.Angles(0, 0, math.rad(-14)), groundY)
	end

	if leftLeg then
		placePartGrounded(leftLeg, base - forward * 1.65 - right * 0.45, flatRotation, groundY)
	end

	if rightLeg then
		placePartGrounded(rightLeg, base - forward * 1.65 + right * 0.45, flatRotation, groundY)
	end

	if root then
		root.CFrame = CFrame.new(base + Vector3.new(0, 0.4, 0))
		root.Transparency = 1
		root.CanCollide = false
		root.Anchored = true
	end
end

local function placeCorpseAccessoriesOnGround(corpse, impactPosition)
	local index = 0
	local groundY = impactPosition.Y

	for _, accessory in ipairs(corpse:GetChildren()) do
		if accessory:IsA("Accessory") then
			local handle = accessory:FindFirstChild("Handle")

			if handle and handle:IsA("BasePart") then
				index += 1

				local angle = index * 1.35
				local radius = 1.2 + (index % 3) * 0.35

				local x = impactPosition.X + math.cos(angle) * radius
				local z = impactPosition.Z + math.sin(angle) * radius
				local y = groundY + handle.Size.Y / 2 + 0.04

				handle.AssemblyLinearVelocity = Vector3.zero
				handle.AssemblyAngularVelocity = Vector3.zero

				handle.Anchored = true
				handle.CanCollide = false
				handle.CanTouch = false
				handle.CanQuery = false

				handle.CFrame =
					CFrame.new(x, y, z)
					* CFrame.Angles(
						random:NextNumber(-0.25, 0.25),
						random:NextNumber(0, math.pi * 2),
						random:NextNumber(-0.25, 0.25)
					)
			end
		end
	end
end

local function createFlatCorpse(player, character, impactPosition)
	if player:GetAttribute("ImpactMarksEnabled") == false then
		return
	end

	if character:GetAttribute("CorpseCreated") then
		return
	end

	character:SetAttribute("CorpseCreated", true)
	character.Archivable = true

	local corpseFolder = getOrCreateFolder(workspace, "PersistentCorpses")
	local corpse = character:Clone()

	corpse.Name = player.Name .. "_Corpse"
	corpse:SetAttribute("OwnerUserId", player.UserId)

	stripRuntimeObjects(corpse)

	local humanoid = corpse:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.Health = 0
		humanoid.PlatformStand = true
	end

	layCorpseOnGround(corpse, impactPosition)
	placeCorpseAccessoriesOnGround(corpse, impactPosition)

	for _, descendant in ipairs(corpse:GetDescendants()) do
		if descendant:IsA("BasePart") then
			if descendant.Name == "HumanoidRootPart" then
				descendant.Transparency = 1
				descendant.CanCollide = false
				descendant.Anchored = true
			else
				descendant.CanCollide = true
				descendant.Anchored = true
			end
		end
	end

	corpse.Parent = corpseFolder

	local corpses = corpseFolder:GetChildren()
	while #corpses > GameConfig.MaxPersistentCorpses do
		corpses[1]:Destroy()
		table.remove(corpses, 1)
	end
end

local function clearImpactVisuals(player)
	for _, folderName in ipairs({ "ImpactMarks", "PersistentCorpses" }) do
		local folder = workspace:FindFirstChild(folderName)

		if folder then
			for _, child in ipairs(folder:GetChildren()) do
				local owner = child:GetAttribute("OwnerUserId")

				if owner == nil or owner == player.UserId then
					child:Destroy()
				end
			end
		end
	end
end

local function freezeOriginalCharacter(character)
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.AssemblyLinearVelocity = Vector3.zero
			descendant.AssemblyAngularVelocity = Vector3.zero
			descendant.CanCollide = false
			descendant.Anchored = true
		end
	end
end

function RagdollService:PrepareImpactDeath(player)
	local character = player.Character
	if not character then
		return
	end

	local impactPosition = getImpactPosition(character)

	createRoundImpactMark(player, character, impactPosition)
	createFlatCorpse(player, character, impactPosition)
	freezeOriginalCharacter(character)

	getOrCreateRemote("ForceBlackScreen"):FireClient(player)
end

function RagdollService:RagdollPlayer(player)
	local character = player.Character
	if not character then
		return
	end

	ragdollCharacter(player, character)
end

local function setupCharacter(player, character)
	character.Archivable = true
	character:SetAttribute("IsRagdolled", false)
	character:SetAttribute("RagdollStartedAt", 0)
	character:SetAttribute("ImpactCreated", false)
	character:SetAttribute("CorpseCreated", false)
	character:SetAttribute("AirborneStartedAt", 0)

	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then
		return
	end

	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false
	humanoid.PlatformStand = false
	humanoid.AutoRotate = true

	-- Réactiver les états normaux au respawn.
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, true)
end

function RagdollService:Start()
	getOrCreateRemote("FallStarted")
	getOrCreateRemote("ForceBlackScreen")

	local setImpactMarks = getOrCreateRemote("SetImpactMarksEnabled")

	setImpactMarks.OnServerEvent:Connect(function(player, enabled)
		if typeof(enabled) ~= "boolean" then
			return
		end

		player:SetAttribute("ImpactMarksEnabled", enabled)

		if not enabled then
			clearImpactVisuals(player)
		end
	end)

	Players.PlayerAdded:Connect(function(player)
		player:SetAttribute("ImpactMarksEnabled", GameConfig.DefaultImpactMarksEnabled)

		player.CharacterAdded:Connect(function(character)
			setupCharacter(player, character)
		end)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		player:SetAttribute("ImpactMarksEnabled", GameConfig.DefaultImpactMarksEnabled)

		if player.Character then
			setupCharacter(player, player.Character)
		end
	end
end

return RagdollService