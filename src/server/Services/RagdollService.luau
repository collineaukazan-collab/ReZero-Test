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

	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Name = "CenterPullVelocity"
	linearVelocity.Attachment0 = attachment
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.MaxForce = GameConfig.CenterPullMaxForce
	linearVelocity.VectorVelocity = Vector3.zero
	linearVelocity.Parent = torso
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

	local center = GameConfig.StairCenter
	local offset = Vector3.new(center.X - torso.Position.X, 0, center.Z - torso.Position.Z)
	local distance = offset.Magnitude

	if distance <= GameConfig.CenterPullTargetRadius then
		velocityObject.VectorVelocity = Vector3.zero
		return
	end

	local direction = offset.Unit
	local speedRatio = math.clamp(distance / 70, 0.15, 1)
	local speed = GameConfig.CenterPullSpeed * speedRatio

	velocityObject.VectorVelocity = Vector3.new(direction.X * speed, 0, direction.Z * speed)
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

	local center = GameConfig.StairCenter
	local offset = Vector3.new(center.X - torso.Position.X, 0, center.Z - torso.Position.Z)

	if offset.Magnitude > 1 then
		local direction = offset.Unit
		local currentVelocity = torso.AssemblyLinearVelocity

		torso.AssemblyLinearVelocity = Vector3.new(
			direction.X * horizontalSpeed,
			math.min(currentVelocity.Y, downSpeed),
			direction.Z * horizontalSpeed
		)
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
		return GameConfig.SpawnPlatformPosition + Vector3.new(0, 0.08, 0)
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
		return result.Position + Vector3.new(0, 0.08, 0)
	end

	return Vector3.new(lowestPart.Position.X, GameConfig.SpawnPlatformPosition.Y + 0.08, lowestPart.Position.Z)
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
	mark.Color = Color3.fromRGB(85, 0, 0)
	mark.Transparency = 0.16

	local diameter = random:NextNumber(5.5, 9.5)

	-- Cylindre plat posé au sol, rond.
	mark.Size = Vector3.new(diameter, 0.04, diameter)
	mark.CFrame = CFrame.new(impactPosition + Vector3.new(0, 0.025, 0))

	mark.Parent = folder

	local marks = folder:GetChildren()
	while #marks > GameConfig.MaxImpactMarks do
		marks[1]:Destroy()
		table.remove(marks, 1)
	end
end

local function stripRuntimeObjects(instance)
	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("Script")
			or descendant:IsA("LocalScript")
			or descendant:IsA("VectorForce")
			or descendant:IsA("LinearVelocity")
			or descendant:IsA("BodyVelocity")
			or descendant:IsA("BodyGyro")
			or descendant:IsA("AngularVelocity")
		then
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

local function layCorpseOnGround(corpse, impactPosition)
	local yaw = random:NextNumber(0, math.pi * 2)
	local forward = Vector3.new(math.cos(yaw), 0, math.sin(yaw))
	local right = Vector3.new(-forward.Z, 0, forward.X)

	local groundY = impactPosition.Y

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
		placePartGrounded(torso, impactPosition, flatRotation, groundY)
	end

	if head then
		placePartGrounded(head, impactPosition + forward * 1.45, headRotation, groundY)
	end

	if leftArm then
		placePartGrounded(leftArm, impactPosition - right * 1.45, flatRotation * CFrame.Angles(0, 0, math.rad(12)), groundY)
	end

	if rightArm then
		placePartGrounded(rightArm, impactPosition + right * 1.45, flatRotation * CFrame.Angles(0, 0, math.rad(-12)), groundY)
	end

	if leftLeg then
		placePartGrounded(leftLeg, impactPosition - forward * 1.55 - right * 0.45, flatRotation, groundY)
	end

	if rightLeg then
		placePartGrounded(rightLeg, impactPosition - forward * 1.55 + right * 0.45, flatRotation, groundY)
	end

	if root then
		root.CFrame = CFrame.new(impactPosition + Vector3.new(0, 0.4, 0))
		root.Transparency = 1
		root.CanCollide = false
		root.Anchored = true
	end
end

local function createFlatCorpse(player, character, impactPosition)
	if character:GetAttribute("CorpseCreated") then
		return
	end

	character:SetAttribute("CorpseCreated", true)
	character.Archivable = true

	local corpseFolder = getOrCreateFolder(workspace, "PersistentCorpses")
	local corpse = character:Clone()
	corpse.Name = player.Name .. "_Corpse"

	stripRuntimeObjects(corpse)

	for _, descendant in ipairs(corpse:GetDescendants()) do
		if descendant:IsA("Motor6D") or descendant:IsA("BallSocketConstraint") or descendant:IsA("Attachment") then
			descendant:Destroy()
		end
	end

	local humanoid = corpse:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.Health = 0
		humanoid.PlatformStand = true
	end

	layCorpseOnGround(corpse, impactPosition)

	for _, descendant in ipairs(corpse:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.AssemblyLinearVelocity = Vector3.zero
			descendant.AssemblyAngularVelocity = Vector3.zero

			if descendant.Name == "HumanoidRootPart" then
				descendant.Transparency = 1
				descendant.CanCollide = false
				descendant.Anchored = true
			else
				descendant.Anchored = true
				descendant.CanCollide = true
				descendant.CustomPhysicalProperties = PhysicalProperties.new(1, 1, 0, 1, 0)
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