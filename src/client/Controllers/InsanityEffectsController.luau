local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local InsanityEffectsController = {}

local localPlayer = Players.LocalPlayer
local overlay = nil
local shakeSeed = Random.new()

local function createOverlay()
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	local old = playerGui:FindFirstChild("InsanityEffectsGui")
	if old then
		old:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "InsanityEffectsGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 35
	gui.Parent = playerGui

	overlay = Instance.new("Frame")
	overlay.Name = "DarkOverlay"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.Parent = gui
end

local function getHumanoid()
	local character = localPlayer.Character
	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

function InsanityEffectsController:Start()
	createOverlay()

	localPlayer.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid", 10)
		if humanoid then
			humanoid.CameraOffset = Vector3.zero
		end
	end)

	RunService.RenderStepped:Connect(function()
		local insanity = math.clamp(localPlayer:GetAttribute("Insanity") or 0, 0, 100)
		local ratio = insanity / 100

		if overlay then
			local darkness = ratio * GameConfig.Insanity.ScreenDarknessAtMax
			overlay.BackgroundTransparency = math.clamp(1 - darkness, 0.45, 1)
		end

		local humanoid = getHumanoid()
		if not humanoid then
			return
		end

		if ratio < GameConfig.Insanity.ShakeStartRatio then
			humanoid.CameraOffset = Vector3.zero
			return
		end

		local shakeRatio = (ratio - GameConfig.Insanity.ShakeStartRatio) / (1 - GameConfig.Insanity.ShakeStartRatio)
		local shakePower = shakeRatio * GameConfig.Insanity.ShakeAtMax

		humanoid.CameraOffset = Vector3.new(
			shakeSeed:NextNumber(-shakePower, shakePower),
			shakeSeed:NextNumber(-shakePower, shakePower),
			0
		)
	end)
end

return InsanityEffectsController