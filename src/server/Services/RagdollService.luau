local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local RagdollService = {}

local function getRoot(character)
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(character)
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function randomVector(power)
	return Vector3.new(
		math.random(-100, 100) / 100 * power,
		math.random(-100, 100) / 100 * power,
		math.random(-100, 100) / 100 * power
	)
end

local function getOrCreateFolder(character)
	local folder = character:FindFirstChild("RagdollObjects")

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "RagdollObjects"
		folder.Parent = character
	end

	return folder
end

local function cleanupOldRagdollObjects(character)
	local oldFolder = character:FindFirstChild("RagdollObjects")

	if oldFolder then
		oldFolder:Destroy()
	end

	for _, instance in ipairs(character:GetDescendants()) do
		if instance:IsA("Attachment") and string.find(instance.Name, "RagdollAttachment") then
			instance:Destroy()
		end
	end
end

local function isAllowedMotor(motor)
	if not motor.Part0 or not motor.Part1 then
		return false
	end

	-- Important : on garde RootJoint actif pour que le centre-pull marche.
	if motor.Name == "RootJoint" then
		return false
	end

	return true
end

local function createSocketFromMotor(character, motor)
	if not isAllowedMotor(motor) then
		return
	end

	local folder = getOrCreateFolder(character)

	local attachment0 = Instance.new("Attachment")
	attachment0.Name = "RagdollAttachment0_" .. motor.Name
	attachment0.CFrame = motor.C0
	attachment0.Parent = motor.Part0

	local attachment1 = Instance.new("Attachment")
	attachment1.Name = "RagdollAttachment1_" .. motor.Name
	attachment1.CFrame = motor.C1
	attachment1.Parent = motor.Part1

	local socket = Instance.new("BallSocketConstraint")
	socket.Name = "RagdollSocket_" .. motor.Name
	socket.Attachment0 = attachment0
	socket.Attachment1 = attachment1
	socket.LimitsEnabled = false
	socket.TwistLimitsEnabled = false
	socket.Restitution = 0
	socket.Parent = folder

	motor.Enabled = false
end

local function forceDefaultCollisionGroup(part)
	pcall(function()
		part.CollisionGroup = "Default"
	end)
end

local function setRagdollCollisions(character)
	for _, instance in ipairs(character:GetDescendants()) do
		if instance:IsA("BasePart") then
			instance.CanTouch = true
			instance.CanQuery = true
			forceDefaultCollisionGroup(instance)

			pcall(function()
				instance:SetNetworkOwner(nil)
			end)

			if instance.Name == "HumanoidRootPart" then
				instance.CanCollide = false
				instance.Massless = true
			else
				instance.CanCollide = true
				instance.Massless = false
				instance.CustomPhysicalProperties = PhysicalProperties.new(1, 0.65, 0, 1, 1)
			end
		end
	end
end

local function disableHumanoidStates(humanoid)
	humanoid.RequiresNeck = false
	humanoid.PlatformStand = true
	humanoid.AutoRotate = false

	pcall(function()
		humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
	end)

	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
end

local function throwLimbs(character)
	local root = getRoot(character)

	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part ~= root then
			part.AssemblyAngularVelocity = randomVector(18)
			part.AssemblyLinearVelocity += randomVector(8)
		end
	end

	if root then
		root.AssemblyAngularVelocity = randomVector(8)
	end
end

function RagdollService:RagdollCharacter(character)
	if not character or not character.Parent then
		return false
	end

	if character:GetAttribute("IsRagdolled") == true then
		return true
	end

	local humanoid = getHumanoid(character)
	local root = getRoot(character)

	if not humanoid or not root or humanoid.Health <= 0 then
		return false
	end

	character:SetAttribute("IsRagdolled", true)

	cleanupOldRagdollObjects(character)
	getOrCreateFolder(character)

	for _, instance in ipairs(character:GetDescendants()) do
		if instance:IsA("Motor6D") then
			createSocketFromMotor(character, instance)
		end
	end

	setRagdollCollisions(character)
	disableHumanoidStates(humanoid)
	throwLimbs(character)

	return true
end

function RagdollService:RagdollPlayer(player)
	if not player or not player.Character then
		return false
	end

	return self:RagdollCharacter(player.Character)
end

function RagdollService:ApplyCenterPull(character, dt)
	if not character or character:GetAttribute("IsRagdolled") ~= true then
		return
	end

	if GameConfig.CenterPullEnabled == false then
		return
	end

	local root = getRoot(character)
	if not root then
		return
	end

	local center = GameConfig.StairCenter or Vector3.zero
	local position = root.Position
	local flatOffset = Vector3.new(center.X - position.X, 0, center.Z - position.Z)
	local distance = flatOffset.Magnitude

	if distance <= (GameConfig.CenterPullTargetRadius or 10) then
		return
	end

	local direction = flatOffset.Unit
	local speed = GameConfig.CenterPullSpeed or 10
	local rootVelocity = root.AssemblyLinearVelocity
	local targetXZ = direction * speed

	root.AssemblyLinearVelocity = Vector3.new(
		targetXZ.X,
		rootVelocity.Y,
		targetXZ.Z
	)

	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part ~= root then
			local velocity = part.AssemblyLinearVelocity

			part.AssemblyLinearVelocity = Vector3.new(
				(velocity.X * 0.65) + (targetXZ.X * 0.35),
				velocity.Y,
				(velocity.Z * 0.65) + (targetXZ.Z * 0.35)
			)
		end
	end
end

function RagdollService:ApplyFallPhysics(character, dt)
	if not character or character:GetAttribute("IsRagdolled") ~= true then
		return
	end

	if GameConfig.FallAccelerationEnabled == false then
		return
	end

	local acceleration = GameConfig.FallAcceleration or 20
	local maxFallSpeed = GameConfig.MaxFallSpeed or -520

	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			local velocity = part.AssemblyLinearVelocity
			local newY = math.max(maxFallSpeed, math.min(velocity.Y, 0) - acceleration * dt)

			part.AssemblyLinearVelocity = Vector3.new(
				velocity.X,
				newY,
				velocity.Z
			)
		end
	end
end

function RagdollService:PushPlayerToCenter(player)
	local character = player and player.Character
	if not character then
		return false
	end

	self:RagdollCharacter(character)

	local root = getRoot(character)
	if not root then
		return false
	end

	local center = GameConfig.StairCenter or Vector3.zero
	local flatOffset = Vector3.new(center.X - root.Position.X, 0, center.Z - root.Position.Z)

	local direction
	if flatOffset.Magnitude > 0.1 then
		direction = flatOffset.Unit
	else
		direction = Vector3.new(0, 0, -1)
	end

	-- Seulement horizontal.
	-- Je mets une valeur minimum pour que l'insanity pousse vraiment,
	-- même si CenterPullSpeed est bas.
	local configuredSpeed = GameConfig.Insanity
		and GameConfig.Insanity.CollapsePushSpeed
		or nil

	local pushSpeed = configuredSpeed or math.max((GameConfig.CenterPullSpeed or 10) * 9, 90)

	local currentVelocity = root.AssemblyLinearVelocity

	root.AssemblyLinearVelocity = Vector3.new(
		direction.X * pushSpeed,
		currentVelocity.Y,
		direction.Z * pushSpeed
	)

	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part ~= root then
			local partVelocity = part.AssemblyLinearVelocity

			part.AssemblyLinearVelocity = Vector3.new(
				direction.X * (pushSpeed * 0.85),
				partVelocity.Y,
				direction.Z * (pushSpeed * 0.85)
			)

			part.AssemblyAngularVelocity = randomVector(12)
		end
	end

	return true
end

function RagdollService:Start()
	print("[RagdollService] Started fixed collisions + horizontal insanity push.")
end

return RagdollService