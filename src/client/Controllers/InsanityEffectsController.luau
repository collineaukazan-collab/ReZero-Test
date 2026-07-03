local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local InsanityEffectsController = {}

local localPlayer = Players.LocalPlayer

local darkOverlay = nil
local redOverlay = nil
local wordLayer = nil
local staticLayer = nil

local random = Random.new()

local words = {
	"RUN",
	"FALL",
	"LOOK",
	"STOP",
	"LOST",
	"TURN",
	"BACK",
	"NO",
	"WAKE",
}

local lastWordTime = 0
local lastStaticTime = 0

local function createGui()
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	local old = playerGui:FindFirstChild("InsanityEffectsGui")
	if old then
		old:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "InsanityEffectsGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 600
	gui.Parent = playerGui

	darkOverlay = Instance.new("Frame")
	darkOverlay.Name = "DarkOverlay"
	darkOverlay.Size = UDim2.fromScale(1, 1)
	darkOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	darkOverlay.BackgroundTransparency = 1
	darkOverlay.BorderSizePixel = 0
	darkOverlay.Parent = gui

	redOverlay = Instance.new("Frame")
	redOverlay.Name = "RedOverlay"
	redOverlay.Size = UDim2.fromScale(1, 1)
	redOverlay.BackgroundColor3 = Color3.fromRGB(135, 0, 0)
	redOverlay.BackgroundTransparency = 1
	redOverlay.BorderSizePixel = 0
	redOverlay.Parent = gui

	staticLayer = Instance.new("Frame")
	staticLayer.Name = "StaticLayer"
	staticLayer.Size = UDim2.fromScale(1, 1)
	staticLayer.BackgroundTransparency = 1
	staticLayer.Parent = gui

	wordLayer = Instance.new("Frame")
	wordLayer.Name = "WordLayer"
	wordLayer.Size = UDim2.fromScale(1, 1)
	wordLayer.BackgroundTransparency = 1
	wordLayer.Parent = gui
end

local function clearLayer(layer)
	if not layer then
		return
	end

	for _, child in ipairs(layer:GetChildren()) do
		child:Destroy()
	end
end

local function spawnWord(intensity)
	if not wordLayer then
		return
	end

	local label = Instance.new("TextLabel")
	label.Name = "InsanityWord"
	label.BackgroundTransparency = 1
	label.AnchorPoint = Vector2.new(0.5, 0.5)

	label.Position = UDim2.fromScale(
		random:NextNumber(0.06, 0.94),
		random:NextNumber(0.08, 0.92)
	)

	label.Size = UDim2.fromOffset(
		random:NextInteger(60, 145),
		random:NextInteger(22, 48)
	)

	label.Rotation = random:NextNumber(-35, 35)
	label.Font = Enum.Font.GothamBlack
	label.Text = words[random:NextInteger(1, #words)]
	label.TextSize = random:NextInteger(18, 38)
	label.TextColor3 = Color3.fromRGB(245, 45, 50)
	label.TextTransparency = 0
	label.TextStrokeColor3 = Color3.fromRGB(25, 0, 0)
	label.TextStrokeTransparency = 0.25
	label.Parent = wordLayer

	local lifetime = random:NextNumber(0.06, 0.13)

	local tween = TweenService:Create(
		label,
		TweenInfo.new(lifetime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
		{
			TextTransparency = 1,
			TextStrokeTransparency = 1,
			Rotation = label.Rotation + random:NextNumber(-40, 40),
		}
	)

	tween:Play()

	task.delay(lifetime + 0.03, function()
		if label then
			label:Destroy()
		end
	end)
end

local function spawnStatic(intensity)
	if not staticLayer then
		return
	end

	local count = math.floor(6 + intensity * 18)

	for _ = 1, count do
		local line = Instance.new("Frame")
		line.Name = "StaticLine"
		line.BorderSizePixel = 0

		line.BackgroundColor3 = Color3.fromRGB(
			random:NextInteger(160, 255),
			random:NextInteger(15, 65),
			random:NextInteger(15, 65)
		)

		line.BackgroundTransparency = random:NextNumber(0.45, 0.82)

		line.Position = UDim2.fromScale(
			random:NextNumber(0, 1),
			random:NextNumber(0, 1)
		)

		line.Size = UDim2.fromOffset(
			random:NextInteger(20, 240),
			random:NextInteger(1, 3)
		)

		line.Rotation = random:NextNumber(-10, 10)
		line.Parent = staticLayer

		task.delay(random:NextNumber(0.025, 0.065), function()
			if line then
				line:Destroy()
			end
		end)
	end
end

local function getHumanoid()
	local character = localPlayer.Character
	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

function InsanityEffectsController:Start()
	createGui()

	localPlayer.CharacterAdded:Connect(function()
		clearLayer(wordLayer)
		clearLayer(staticLayer)

		local humanoid = getHumanoid()
		if humanoid then
			humanoid.CameraOffset = Vector3.zero
		end
	end)

	RunService.RenderStepped:Connect(function()
		local insanity = math.clamp(localPlayer:GetAttribute("Insanity") or 0, 0, 100)
		local ratio = insanity / 100

		if darkOverlay then
			local darkness = ratio * 0.18
			darkOverlay.BackgroundTransparency = math.clamp(1 - darkness, 0.78, 1)
		end

		if redOverlay then
			local redPower = ratio * 0.42
			redOverlay.BackgroundTransparency = math.clamp(1 - redPower, 0.55, 1)
		end

		local humanoid = getHumanoid()
		if humanoid then
			if ratio < 0.96 then
				humanoid.CameraOffset = Vector3.zero
			else
				local shakePower = ((ratio - 0.96) / 0.04) * 0.06

				humanoid.CameraOffset = Vector3.new(
					random:NextNumber(-shakePower, shakePower),
					random:NextNumber(-shakePower, shakePower),
					0
				)
			end
		end

		if ratio < 0.75 then
			return
		end

		local now = os.clock()
		local intensity = math.clamp((ratio - 0.75) / 0.25, 0.2, 1)

		local wordDelay = 0.14 - intensity * 0.08
		if now - lastWordTime >= wordDelay then
			lastWordTime = now
			spawnWord(intensity)
		end

		local staticDelay = 0.08 - intensity * 0.045
		if now - lastStaticTime >= staticDelay then
			lastStaticTime = now
			spawnStatic(intensity)
		end
	end)
end

return InsanityEffectsController