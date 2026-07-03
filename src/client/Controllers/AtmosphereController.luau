local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local AtmosphereController = {}

local localPlayer = Players.LocalPlayer

local sandFolder = nil
local sandEmitters = {}

local function createEmitterPart(name, offset)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Transparency = 1
	part.Size = Vector3.new(1, 1, 1)
	part.Parent = sandFolder

	local attachment = Instance.new("Attachment")
	attachment.Parent = part

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "TowerSandEmitter"
	emitter.Enabled = true
	emitter.Rate = 55
	emitter.Lifetime = NumberRange.new(2.5, 4)
	emitter.Speed = NumberRange.new(10, 18)
	emitter.SpreadAngle = Vector2.new(45, 45)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-60, 60)
	emitter.Acceleration = Vector3.new(12, -1, 0)
	emitter.Drag = 1.5
	emitter.LightInfluence = 0
	emitter.Color = ColorSequence.new(Color3.fromRGB(210, 178, 120))

	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.15, 0.55),
		NumberSequenceKeypoint.new(0.75, 0.65),
		NumberSequenceKeypoint.new(1, 1),
	})

	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.12),
		NumberSequenceKeypoint.new(0.5, 0.22),
		NumberSequenceKeypoint.new(1, 0.08),
	})

	emitter.Parent = attachment

	table.insert(sandEmitters, {
		Part = part,
		Offset = offset,
	})
end

local function setupSandstorm()
	local old = Workspace:FindFirstChild("ClientTowerSandstorm")
	if old then
		old:Destroy()
	end

	sandFolder = Instance.new("Folder")
	sandFolder.Name = "ClientTowerSandstorm"
	sandFolder.Parent = Workspace

	-- Plusieurs points autour du centre de la tour.
	createEmitterPart("SandEmitter_1", Vector3.new(0, 0, 0))
	createEmitterPart("SandEmitter_2", Vector3.new(24, 0, 0))
	createEmitterPart("SandEmitter_3", Vector3.new(-24, 0, 0))
	createEmitterPart("SandEmitter_4", Vector3.new(0, 0, 24))
	createEmitterPart("SandEmitter_5", Vector3.new(0, 0, -24))
end

local function updateSandstormPosition()
	local character = localPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")

	if not root then
		return
	end

	local center = GameConfig.StairCenter or Vector3.new(0, 0, 0)
	local playerY = root.Position.Y

	for _, data in ipairs(sandEmitters) do
		data.Part.Position = Vector3.new(
			center.X + data.Offset.X,
			playerY + 18,
			center.Z + data.Offset.Z
		)
	end
end

function AtmosphereController:Start()
	-- Ambiance plus lumineuse, style tour sableuse.
	Lighting.Brightness = 1.65
	Lighting.ClockTime = 13.5
	Lighting.GlobalShadows = true

	Lighting.Ambient = Color3.fromRGB(125, 110, 85)
	Lighting.OutdoorAmbient = Color3.fromRGB(90, 80, 65)

	Lighting.FogColor = Color3.fromRGB(175, 145, 100)
	Lighting.FogStart = 70
	Lighting.FogEnd = 520

	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Parent = Lighting
	end

	atmosphere.Density = 0.22
	atmosphere.Offset = 0.08
	atmosphere.Color = Color3.fromRGB(205, 175, 125)
	atmosphere.Decay = Color3.fromRGB(120, 95, 65)
	atmosphere.Glare = 0.04
	atmosphere.Haze = 1.6

	local colorCorrection = Lighting:FindFirstChild("TowerSandColorCorrection")
	if not colorCorrection then
		colorCorrection = Instance.new("ColorCorrectionEffect")
		colorCorrection.Name = "TowerSandColorCorrection"
		colorCorrection.Parent = Lighting
	end

	colorCorrection.Brightness = 0.04
	colorCorrection.Contrast = 0.08
	colorCorrection.Saturation = -0.04
	colorCorrection.TintColor = Color3.fromRGB(255, 230, 185)

	setupSandstorm()

	RunService.RenderStepped:Connect(function()
		updateSandstormPosition()
	end)
end

return AtmosphereController