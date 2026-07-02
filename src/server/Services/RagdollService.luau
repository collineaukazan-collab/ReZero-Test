local Players = game:GetService("Players")

local RagdollService = {}

local function ragdollCharacter(character)
	if character:GetAttribute("IsRagdolled") then
		return
	end

	character:SetAttribute("IsRagdolled", true)

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false
	humanoid.PlatformStand = true
	humanoid.AutoRotate = false
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)

	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("Motor6D") then
			local motor = descendant
			local part0 = motor.Part0
			local part1 = motor.Part1

			if part0 and part1 then
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
				socket.UpperAngle = 45
				socket.TwistLowerAngle = -35
				socket.TwistUpperAngle = 35
				socket.Parent = part0

				motor.Enabled = false
			end
		elseif descendant:IsA("BasePart") then
			descendant.CanCollide = true
			descendant.Massless = false
		end
	end
end

local function setupCharacter(character)
	character:SetAttribute("IsRagdolled", false)

	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then
		return
	end

	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false
end

function RagdollService:RagdollPlayer(player)
	local character = player.Character
	if not character then
		return
	end

	ragdollCharacter(character)
end

function RagdollService:Start()
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			setupCharacter(character)
		end)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			setupCharacter(player.Character)
		end
	end
end

return RagdollService