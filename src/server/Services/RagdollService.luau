local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local RagdollService = {}

local function getRoot(character)
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(character)
	return character and character:FindFirstChildOfClass("Humanoid")
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

local function isMotorAllowed(motor)
	if not motor.Part0 or not motor.Part1 then
		return false
	end

	if motor.Name == "RootJoint" then
		return false
	end

	return true
end

local function createSocketFromMotor(character, motor)
	if not isMotorAllowed(motor) then
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
	socket.LimitsEnabled = true
	socket.TwistLimitsEnabled = true
	socket.UpperAngle = 60
	socket.TwistLowerAngle = -40
	socket.TwistUpperAngle = 40
	socket.Parent = folder

	motor.Enabled = false
end

local function setRagdollCollisions(character, enabled)
	for _, instance in ipairs(character:GetDescendants()) do
		if instance:IsA("BasePart") then
			if instance.Name == "HumanoidRootPart" then
				instance.CanCollide = false
				instance.Massless = true
			else
				instance.CanCollide = enabled
				instance.Massless = false
			end
		end
	end
end

local function disableHumanoidStates(humanoid)
	humanoid.RequiresNeck = false
	humanoid.PlatformStand = true
	humanoid.AutoRotate = false
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)

	pcall(function()
		humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, false)
	end)
end

local function enableHumanoidStates(humanoid)
	humanoid.PlatformStand = false
	humanoid.AutoRotate = true
	humanoid.RequiresNeck = false

	pcall(function()
		humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, true)
	end)

	if humanoid.RigType == Enum.HumanoidRigType.R6 then
		humanoid.HipHeight = 0
	end

	humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)

	task.delay(0.15, function()
		if humanoid and humanoid.Parent and humanoid.Health > 0 then
			humanoid:ChangeState(Enum.HumanoidStateType.Running)
		end
	end)
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

	getOrCreateFolder(character)

	for _, instance in ipairs(character:GetDescendants()) do
		if instance:IsA("Motor6D") then
			createSocketFromMotor(character, instance)
		end
	end

	setRagdollCollisions(character, true)
	disableHumanoidStates(humanoid)

	root.AssemblyAngularVelocity = Vector3.new(
		math.random(-5, 5),
		math.random(-5, 5),
		math.random(-5, 5)
	)

	return true
end

function RagdollService:UnragdollCharacter(character)
	if not character or not character.Parent then
		return false
	end

	if character:GetAttribute("IsRagdolled") ~= true then
		return true
	end

	local humanoid = getHumanoid(character)
	local root = getRoot(character)

	if not humanoid or not root or humanoid.Health <= 0 then
		return false
	end

	local folder = character:FindFirstChild("RagdollObjects")

	if folder then
		folder:Destroy()
	end

	for _, instance in ipairs(character:GetDescendants()) do
		if instance:IsA("Motor6D") then
			instance.Enabled = true
		end
	end

	character:SetAttribute("IsRagdolled", false)

	setRagdollCollisions(character, false)

	root.CanCollide = false
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero

	enableHumanoidStates(humanoid)

	return true
end

function RagdollService:RagdollPlayer(player)
	if not player or not player.Character then
		return false
	end

	return self:RagdollCharacter(player.Character)
end

function RagdollService:UnragdollPlayer(player)
	if not player or not player.Character then
		return false
	end

	return self:UnragdollCharacter(player.Character)
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
	local current = root.Position

	local flatOffset = Vector3.new(center.X - current.X, 0, center.Z - current.Z)
	local distance = flatOffset.Magnitude

	if distance <= (GameConfig.CenterPullTargetRadius or 2) then
		return
	end

	local direction = flatOffset.Unit
	local speed = GameConfig.CenterPullSpeed or 22

	local velocity = root.AssemblyLinearVelocity
	local targetVelocity = direction * speed

	root.AssemblyLinearVelocity = Vector3.new(
		targetVelocity.X,
		velocity.Y,
		targetVelocity.Z
	)
end

function RagdollService:ApplyFallPhysics(character, dt)
	if not character or character:GetAttribute("IsRagdolled") ~= true then
		return
	end

	if GameConfig.FallAccelerationEnabled == false then
		return
	end

	local root = getRoot(character)

	if not root then
		return
	end

	local velocity = root.AssemblyLinearVelocity
	local acceleration = GameConfig.FallAcceleration or 120
	local maxFallSpeed = GameConfig.MaxFallSpeed or -420

	local newY = math.max(maxFallSpeed, math.min(velocity.Y, 0) - acceleration * dt)

	root.AssemblyLinearVelocity = Vector3.new(
		velocity.X,
		newY,
		velocity.Z
	)
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

	local pushSpeed = GameConfig.Insanity and GameConfig.Insanity.CollapsePushSpeed or 190
	local downSpeed = GameConfig.Insanity and GameConfig.Insanity.CollapseDownSpeed or -135

	root.AssemblyLinearVelocity = direction * pushSpeed + Vector3.new(0, downSpeed, 0)

	return true
end

function RagdollService:Start()
	print("[RagdollService] Started.")
end

return RagdollService