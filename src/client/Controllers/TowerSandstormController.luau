local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local TowerSandstormController = {}

local localPlayer = Players.LocalPlayer

local stormFolder = nil
local stormPart = nil
local emitter = nil
local connection = nil

local function getConfig()
	return GameConfig.TowerSandstorm or {}
end

local function destroyStorm()
	if connection then
		connection:Disconnect()
		connection = nil
	end

	if stormFolder then
		stormFolder:Destroy()
		stormFolder = nil
	end

	stormPart = nil
	emitter = nil
end

local function createStorm()
	local config = getConfig()

	destroyStorm()

	if config.Enabled == false then
		return
	end

	stormFolder = Instance.new("Folder")
	stormFolder.Name = "ClientTowerSandstorm"
	stormFolder.Parent = Workspace

	local center = config.Center or GameConfig.StairCenter or Vector3.zero
	local radius = config.Radius or 85

	stormPart = Instance.new("Part")
	stormPart.Name = "SandstormEmitterPart"
	stormPart.Anchored = true
	stormPart.CanCollide = false
	stormPart.CanTouch = false
	stormPart.CanQuery = false
	stormPart.Transparency = 1
	stormPart.Size = Vector3.new(radius * 2, 2, radius * 2)
	stormPart.Position = Vector3.new(center.X, 8, center.Z)
	stormPart.Parent = stormFolder

	emitter = Instance.new("ParticleEmitter")
	emitter.Name = "MiniSandstorm"
	emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"

	emitter.Color = ColorSequence.new(config.Color or Color3.fromRGB(210, 178, 115))

	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.72),
		NumberSequenceKeypoint.new(0.35, 0.82),
		NumberSequenceKeypoint.new(1, 1),
	})

	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, config.ParticleMinSize or 5),
		NumberSequenceKeypoint.new(1, config.ParticleMaxSize or 13),
	})

	emitter.Lifetime = NumberRange.new(1.8, 3.8)
	emitter.Rate = config.Rate or 55
	emitter.Speed = NumberRange.new(config.WindSpeed or 16, (config.WindSpeed or 16) + 8)
	emitter.SpreadAngle = Vector2.new(12, 24)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-45, 45)
	emitter.LightInfluence = 0.65
	emitter.Drag = 3
	emitter.EmissionDirection = Enum.NormalId.Right
	emitter.Parent = stormPart

	connection = RunService.RenderStepped:Connect(function()
		local character = localPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")

		if not root or not stormPart then
			return
		end

		local centerNow = config.Center or GameConfig.StairCenter or Vector3.zero
		local heightOffset = config.HeightOffset or 10

		stormPart.Position = Vector3.new(
			centerNow.X,
			root.Position.Y + heightOffset,
			centerNow.Z
		)

		-- Rotation légère pour donner l'impression que le vent tourne un peu.
		local t = os.clock()
		stormPart.CFrame = CFrame.new(stormPart.Position)
			* CFrame.Angles(0, math.rad(18 + math.sin(t * 0.25) * 8), 0)
	end)
end

function TowerSandstormController:Start()
	createStorm()
end

return TowerSandstormController