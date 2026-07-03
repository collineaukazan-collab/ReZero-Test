local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local InsanityEffectsController = {}

local localPlayer = Players.LocalPlayer

local gui = nil
local topEdge = nil
local bottomEdge = nil
local leftEdge = nil
local rightEdge = nil

local baseFov = nil
local currentStrength = 0
local random = Random.new()

local function getVisualConfig()
	return GameConfig.InsanityVisual or {
		StartRatio = 0.9,
		MaxZoomAmount = 3.5,
		EdgeDarknessAtMax = 0.82,
		EdgeSizeAtMax = 0.22,
		ShakeStartRatio = 0.9,
		ShakeAtMax = 0.025,
	}
end

local function addGradient(frame, rotation)
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = rotation
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	gradient.Parent = frame
end

local function createEdge(parent, name, position, size, anchor, gradientRotation)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.AnchorPoint = anchor
	frame.Position = position
	frame.Size = size
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Parent = parent

	addGradient(frame, gradientRotation)

	return frame
end

local function createGui()
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	local old = playerGui:FindFirstChild("InsanityEffectsGui")
	if old then
		old:Destroy()
	end

	gui = Instance.new("ScreenGui")
	gui.Name = "InsanityEffectsGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 600
	gui.Parent = playerGui

	topEdge = createEdge(
		gui,
		"TopEdge",
		UDim2.fromScale(0, 0),
		UDim2.fromScale(1, 0),
		Vector2.new(0, 0),
		90
	)

	bottomEdge = createEdge(
		gui,
		"BottomEdge",
		UDim2.fromScale(0, 1),
		UDim2.fromScale(1, 0),
		Vector2.new(0, 1),
		270
	)

	leftEdge = createEdge(
		gui,
		"LeftEdge",
		UDim2.fromScale(0, 0),
		UDim2.fromScale(0, 1),
		Vector2.new(0, 0),
		0
	)

	rightEdge = createEdge(
		gui,
		"RightEdge",
		UDim2.fromScale(1, 0),
		UDim2.fromScale(0, 1),
		Vector2.new(1, 0),
		180
	)
end

local function getHumanoid()
	local character = localPlayer.Character
	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

local function smoothStep(value)
	value = math.clamp(value, 0, 1)
	return value * value * (3 - 2 * value)
end

local function updateEdges(strength)
	local config = getVisualConfig()

	local edgeSize = strength * config.EdgeSizeAtMax
	local transparency = math.clamp(1 - strength * config.EdgeDarknessAtMax, 0.12, 1)

	topEdge.Size = UDim2.fromScale(1, edgeSize)
	bottomEdge.Size = UDim2.fromScale(1, edgeSize)
	leftEdge.Size = UDim2.fromScale(edgeSize, 1)
	rightEdge.Size = UDim2.fromScale(edgeSize, 1)

	topEdge.BackgroundTransparency = transparency
	bottomEdge.BackgroundTransparency = transparency
	leftEdge.BackgroundTransparency = transparency
	rightEdge.BackgroundTransparency = transparency
end

function InsanityEffectsController:Start()
	createGui()

	localPlayer.CharacterAdded:Connect(function()
		local humanoid = getHumanoid()
		if humanoid then
			humanoid.CameraOffset = Vector3.zero
		end
	end)

	RunService.RenderStepped:Connect(function(deltaTime)
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end

		if not baseFov then
			baseFov = camera.FieldOfView
		end

		local config = getVisualConfig()

		local insanity = math.clamp(localPlayer:GetAttribute("Insanity") or 0, 0, 100)
		local ratio = insanity / 100

		local targetStrength = 0
		if ratio > config.StartRatio then
			targetStrength = smoothStep((ratio - config.StartRatio) / (1 - config.StartRatio))
		end

		local alpha = math.clamp(deltaTime * 6, 0, 1)
		currentStrength = currentStrength + (targetStrength - currentStrength) * alpha

		updateEdges(currentStrength)

		local targetFov = baseFov - currentStrength * config.MaxZoomAmount
		camera.FieldOfView = camera.FieldOfView + (targetFov - camera.FieldOfView) * alpha

		local humanoid = getHumanoid()
		if not humanoid then
			return
		end

		if ratio <= config.ShakeStartRatio then
			humanoid.CameraOffset = Vector3.zero
			return
		end

		local shakeRatio = smoothStep((ratio - config.ShakeStartRatio) / (1 - config.ShakeStartRatio))
		local shakePower = shakeRatio * config.ShakeAtMax

		humanoid.CameraOffset = Vector3.new(
			random:NextNumber(-shakePower, shakePower),
			random:NextNumber(-shakePower, shakePower),
			0
		)
	end)
end

return InsanityEffectsController