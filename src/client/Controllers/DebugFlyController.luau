local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local DebugFlyController = {}

local localPlayer = Players.LocalPlayer

local enabled = false

local moveKeys = {
	Forward = false,
	Backward = false,
	Left = false,
	Right = false,
	Up = false,
	Down = false,
}

local flySpeed = 80
local bodyVelocity = nil
local bodyGyro = nil
local renderConnection = nil

local function getCharacterParts()
	local character = localPlayer.Character
	if not character then
		return nil, nil, nil
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	return character, root, humanoid
end

local function cleanupFlyObjects()
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end

	if bodyVelocity then
		bodyVelocity:Destroy()
		bodyVelocity = nil
	end

	if bodyGyro then
		bodyGyro:Destroy()
		bodyGyro = nil
	end
end

local function setFly(state)
	enabled = state

	local _, root, humanoid = getCharacterParts()
	if not root or not humanoid then
		enabled = false
		cleanupFlyObjects()
		return
	end

	if not enabled then
		humanoid.PlatformStand = false
		humanoid.AutoRotate = true
		cleanupFlyObjects()
		print("[DebugFly] Disabled")
		return
	end

	humanoid.PlatformStand = true
	humanoid.AutoRotate = false

	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Name = "DebugFlyVelocity"
	bodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	bodyVelocity.P = 12000
	bodyVelocity.Velocity = Vector3.zero
	bodyVelocity.Parent = root

	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.Name = "DebugFlyGyro"
	bodyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
	bodyGyro.P = 12000
	bodyGyro.CFrame = root.CFrame
	bodyGyro.Parent = root

	renderConnection = RunService.RenderStepped:Connect(function()
		local camera = Workspace.CurrentCamera
		if not camera or not bodyVelocity or not bodyGyro then
			return
		end

		local direction = Vector3.zero

		if moveKeys.Forward then
			direction += camera.CFrame.LookVector
		end

		if moveKeys.Backward then
			direction -= camera.CFrame.LookVector
		end

		if moveKeys.Right then
			direction += camera.CFrame.RightVector
		end

		if moveKeys.Left then
			direction -= camera.CFrame.RightVector
		end

		if moveKeys.Up then
			direction += Vector3.yAxis
		end

		if moveKeys.Down then
			direction -= Vector3.yAxis
		end

		if direction.Magnitude > 0 then
			direction = direction.Unit
		end

		bodyVelocity.Velocity = direction * flySpeed
		bodyGyro.CFrame = camera.CFrame
	end)

	print("[DebugFly] Enabled")
end

local function toggleFly()
	setFly(not enabled)
end

local function setMoveKey(input, value)
	if input.KeyCode == Enum.KeyCode.F then
		if value then
			toggleFly()
		end
	elseif input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.Z then
		moveKeys.Forward = value
	elseif input.KeyCode == Enum.KeyCode.S then
		moveKeys.Backward = value
	elseif input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.Q then
		moveKeys.Left = value
	elseif input.KeyCode == Enum.KeyCode.D then
		moveKeys.Right = value
	elseif input.KeyCode == Enum.KeyCode.Space then
		moveKeys.Up = value
	elseif input.KeyCode == Enum.KeyCode.LeftControl then
		moveKeys.Down = value
	end
end

function DebugFlyController:Start()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		setMoveKey(input, true)
	end)

	UserInputService.InputEnded:Connect(function(input)
		setMoveKey(input, false)
	end)

	localPlayer.CharacterAdded:Connect(function()
		enabled = false
		cleanupFlyObjects()
	end)
end

return DebugFlyController