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

local function getMainBodyPart(character)
	return character:FindFirstChild("LowerTorso")
		or character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("Torso")
		or character:FindFirstChild("HumanoidRootPart")
end

local function createSocketFromMotor(motor)
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
	socket.Name = motor.Name .. "_RagdollSocket"
	socket.Attachment0 = attachment0
	socket.Attachment1 = attachment1

	socket.LimitsEnabled = true
	socket.TwistLimitsEnabled = true
	socket.UpperAngle = 95
	socket.TwistLowerAngle = -95
	socket.TwistUpperAngle = 95
	socket.MaxFrictionTorque = 0
	socket.Restitution = 0

	socket.Parent = part0

	motor.Enabled = false
end

local function addCenterPull(character)
	if character:FindFirstChild("CenterPullAttachment", true) then
		return
	end

	local mainPart = getMainBodyPart(character)
	if not mainPart or not mainPart:IsA("BasePart") then
		return
	end

	local attachment = Instance.new("Attachment")
	attachment.Name = "CenterPullAttachment"
	attachment.Parent = mainPart

	local vectorForce = Instance.new("VectorForce")
	vectorForce.Name = "CenterPullForce"
	vectorForce.Attachment0 = attachment
	vectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
	vectorForce.ApplyAtCenterOfMass = true
	vectorForce.Force = Vector3.zero
	vectorForce.Parent = mainPart
end

local function applyInitialRagdollImpulse(character)
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name ~= "HumanoidRootPart" then
			local side = Vector3.new(
				random:NextNumber(-1, 1),
				random:NextNumber(-0.2, 0.4),
				random:NextNumber(-1, 1)
			)

			if side.Magnitude > 0 then
				descendant:ApplyImpulse(side.Unit * descendant.AssemblyMass * random:NextNumber(12, 28))
			end

			descendant:ApplyAngularImpulse(Vector3.new(
				random:NextNumber(-1, 1),
				random:NextNumber(-1, 1),
				random:NextNumber(-1, 1)
			) * descendant.AssemblyMass * 70)
		end
	end
end

local function ragdollCharacter(player, character)
	if character:GetAttribute("IsRagdolled") then
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

	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("Motor6D") then
			createSocketFromMotor(descendant)
		elseif descendant:IsA("BasePart") then
			if descendant.Name == "HumanoidRootPart" then
				descendant.CanCollide = false
				descendant.Transparency = 1
			else
				descendant.CanCollide = true
				descendant.Massless = false
			end
		end
	end

	addCenterPull(character)
	applyInitialRagdollImpulse(character)

	getOrCreateRemote("FallStarted"):FireClient(player)
end

function RagdollService:ApplyCenterPull(player)
	local character = player.Character
	if not character or not character:GetAttribute("IsRagdolled") then
		return
	end

	local mainPart = getMainBodyPart(character)
	if not mainPart or not mainPart:IsA("BasePart") then
		return
	end

	local forceObject = mainPart:FindFirstChild("CenterPullForce")
	if not forceObject then
		return
	end

	local position = mainPart.Position
	local horizontalOffset = Vector3.new(position.X, 0, position.Z)
	local distance = horizontalOffset.Magnitude

	if distance <= GameConfig.CenterPullStartRadius then
		forceObject.Force = Vector3.zero
		return
	end

	local directionToCenter = -horizontalOffset.Unit
	local forcePower = math.clamp(
		(distance - GameConfig.CenterPullStartRadius) * GameConfig.CenterPullStrength,
		0,
		GameConfig.CenterPullMaxForce
	)

	forceObject.Force = directionToCenter * forcePower * mainPart.AssemblyMass
end

local function getLowestPart(character)
	local lowestPart = nil
	local lowestY = math.huge

	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name ~= "HumanoidRootPart" then
			if descendant.Position.Y < lowestY then
				lowestY = descendant.Position.Y
				lowestPart = descendant
			end
		end
	end

	return lowestPart
end

local function createImpactMarks(player, character)
	if player:GetAttribute("ImpactMarksEnabled") == false then
		return
	end

	if character:GetAttribute("ImpactCreated") then
		return
	end

	character:SetAttribute("ImpactCreated", true)

	local lowestPart = getLowestPart(character)
	if not lowestPart then
		return
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }

	local result = workspace:Raycast(lowestPart.Position + Vector3.new(0, 6, 0), Vector3.new(0, -80, 0), params)
	if not result then
		return
	end

	local folder = getOrCreateFolder(workspace, "ImpactMarks")

	for index = 1, random:NextInteger(2, 4) do
		local mark = Instance.new("Part")
		mark.Name = "ImpactMark"
		mark.Shape = Enum.PartType.Cylinder
		mark.Anchored = true
		mark.CanCollide = false
		mark.CanQuery = false
		mark.CanTouch = false
		mark.Material = Enum.Material.SmoothPlastic
		mark.Color = Color3.fromRGB(70, 0, 0)
		mark.Transparency = random:NextNumber(0.12, 0.28)

		local diameter = random:NextNumber(2.4, 7.5)
		mark.Size = Vector3.new(0.05, diameter, diameter * random:NextNumber(0.65, 1.15))

		local offset = Vector3.new(random:NextNumber(-2.2, 2.2), 0.035 + index * 0.006, random:NextNumber(-2.2, 2.2))
		mark.CFrame =
			CFrame.new(result.Position + offset)
			* CFrame.Angles(0, random:NextNumber(0, math.pi), math.rad(90))

		mark.Parent = folder
	end

	local marks = folder:GetChildren()
	while #marks > GameConfig.MaxImpactMarks do
		marks[1]:Destroy()
		table.remove(marks, 1)
	end
end

local function stripScripts(instance)
	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("Script") or descendant:IsA("LocalScript") then
			descendant:Destroy()
		end
	end
end

local function createPersistentCorpse(player, character)
	if character:GetAttribute("CorpseCreated") then
		return
	end

	character:SetAttribute("CorpseCreated", true)
	character.Archivable = true

	local corpseFolder = getOrCreateFolder(workspace, "PersistentCorpses")
	local corpse = character:Clone()

	corpse.Name = player.Name .. "_Corpse"

	stripScripts(corpse)

	local corpseHumanoid = corpse:FindFirstChildOfClass("Humanoid")
	if corpseHumanoid then
		corpseHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		corpseHumanoid.Health = 0
		corpseHumanoid.PlatformStand = true
	end

	for _, descendant in ipairs(corpse:GetDescendants()) do
		if descendant:IsA("BasePart") then
			if descendant.Name == "HumanoidRootPart" then
				descendant.CanCollide = false
				descendant.Transparency = 1
			else
				descendant.CanCollide = true
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

function RagdollService:PrepareImpactDeath(player)
	local character = player.Character
	if not character then
		return
	end

	createImpactMarks(player, character)
	createPersistentCorpse(player, character)
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
		if typeof(enabled) == "boolean" then
			player:SetAttribute("ImpactMarksEnabled", enabled)
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