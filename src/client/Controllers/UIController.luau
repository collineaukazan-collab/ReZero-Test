local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local NumberUtil = require(ReplicatedStorage.Shared.Utils.NumberUtil)

local UIController = {}

local localPlayer = Players.LocalPlayer

local fps = 0
local frameCount = 0
local frameTimer = 0

local musicVolume = GameConfig.DefaultMusicVolume
local sfxVolume = GameConfig.DefaultSfxVolume
local impactMarksEnabled = GameConfig.DefaultImpactMarksEnabled

local function getOrCreateSoundGroup(name, volume)
	local group = SoundService:FindFirstChild(name)

	if not group then
		group = Instance.new("SoundGroup")
		group.Name = name
		group.Parent = SoundService
	end

	group.Volume = volume
	return group
end

local musicGroup = getOrCreateSoundGroup("Music", musicVolume)
local sfxGroup = getOrCreateSoundGroup("SFX", sfxVolume)

local function createFrame(parent, name, size, position)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.Position = position
	frame.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
	frame.BackgroundTransparency = 0.04
	frame.BorderSizePixel = 0
	frame.Parent = parent

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(55, 55, 70)
	stroke.Thickness = 1
	stroke.Transparency = 0.25
	stroke.Parent = frame

	return frame
end

local function createText(parent, name, text, size, position, textSize)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Size = size
	label.Position = position
	label.Font = Enum.Font.GothamMedium
	label.TextSize = textSize or 15
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = Color3.fromRGB(225, 225, 235)
	label.Text = text
	label.Parent = parent

	return label
end

local function createButton(parent, name, text, size, position)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamMedium
	button.TextSize = 15
	button.TextColor3 = Color3.fromRGB(235, 235, 245)
	button.Text = text
	button.AutoButtonColor = true
	button.Parent = parent

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(70, 70, 90)
	stroke.Thickness = 1
	stroke.Transparency = 0.35
	stroke.Parent = button

	return button
end

local function createSlider(parent, name, title, position, defaultValue, callback)
	local container = Instance.new("Frame")
	container.Name = name
	container.Size = UDim2.new(1, -36, 0, 56)
	container.Position = position
	container.BackgroundTransparency = 1
	container.Parent = parent

	local label = createText(container, "Label", title .. ": " .. math.floor(defaultValue * 100) .. "%", UDim2.new(1, 0, 0, 22), UDim2.new(0, 0, 0, 0), 14)

	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.Size = UDim2.new(1, 0, 0, 6)
	bar.Position = UDim2.new(0, 0, 0, 36)
	bar.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
	bar.BorderSizePixel = 0
	bar.Parent = container

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(defaultValue, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(130, 130, 170)
	fill.BorderSizePixel = 0
	fill.Parent = bar

	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.Size = UDim2.new(0, 14, 0, 14)
	knob.Position = UDim2.new(defaultValue, -7, 0.5, -7)
	knob.BackgroundColor3 = Color3.fromRGB(235, 235, 245)
	knob.BorderSizePixel = 0
	knob.Parent = bar

	local dragging = false

	local function setValueFromX(x)
		local value = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)

		fill.Size = UDim2.new(value, 0, 1, 0)
		knob.Position = UDim2.new(value, -7, 0.5, -7)
		label.Text = title .. ": " .. math.floor(value * 100) .. "%"

		callback(value)
	end

	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			setValueFromX(input.Position.X)
		end
	end)

	knob.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			setValueFromX(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	callback(defaultValue)
end

local function getLeaderstatValue(name)
	local leaderstats = localPlayer:FindFirstChild("leaderstats")
	if not leaderstats then
		return 0
	end

	local value = leaderstats:FindFirstChild(name)
	if not value then
		return 0
	end

	return value.Value
end

local function getPing()
	local success, pingSeconds = pcall(function()
		return localPlayer:GetNetworkPing()
	end)

	if not success or type(pingSeconds) ~= "number" then
		return "N/A"
	end

	return tostring(math.floor(pingSeconds * 2000)) .. " ms"
end

function UIController:Start(graphicsController)
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	local oldGui = playerGui:FindFirstChild("ReZeroHUD")
	if oldGui then
		oldGui:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ReZeroHUD"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	local statsFrame = createFrame(screenGui, "StatsFrame", UDim2.new(0, 255, 0, 142), UDim2.new(0, 16, 0, 16))

	local insanityFrame = createFrame(
	screenGui,
	"InsanityFrame",
	UDim2.new(0, 420, 0, 44),
	UDim2.new(0.5, -210, 0, 18)
)

	insanityFrame.Visible = false

	local insanityLabel = createText(
		insanityFrame,
		"InsanityLabel",
		"INSANITY",
		UDim2.new(0, 105, 1, 0),
		UDim2.new(0, 12, 0, 0),
		14
	)

	local insanityBarBack = Instance.new("Frame")
	insanityBarBack.Name = "BarBack"
	insanityBarBack.Size = UDim2.new(1, -135, 0, 10)
	insanityBarBack.Position = UDim2.new(0, 118, 0.5, -5)
	insanityBarBack.BackgroundColor3 = Color3.fromRGB(32, 32, 42)
	insanityBarBack.BorderSizePixel = 0
	insanityBarBack.Parent = insanityFrame

	local insanityBarFill = Instance.new("Frame")
	insanityBarFill.Name = "BarFill"
	insanityBarFill.Size = UDim2.new(0, 0, 1, 0)
	insanityBarFill.BackgroundColor3 = Color3.fromRGB(130, 20, 45)
	insanityBarFill.BorderSizePixel = 0
	insanityBarFill.Parent = insanityBarBack


	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 12)
	padding.PaddingLeft = UDim.new(0, 14)
	padding.Parent = statsFrame

	local studsLabel = createText(statsFrame, "StudsLabel", "Studs: 0", UDim2.new(1, -20, 0, 22), UDim2.new(0, 0, 0, 0), 16)
	local floorLabel = createText(statsFrame, "FloorLabel", "Floor: 0", UDim2.new(1, -20, 0, 22), UDim2.new(0, 0, 0, 26), 16)
	local bestLabel = createText(statsFrame, "BestLabel", "Best: 0", UDim2.new(1, -20, 0, 22), UDim2.new(0, 0, 0, 52), 16)
	local moneyLabel = createText(statsFrame, "MoneyLabel", "Money: 0", UDim2.new(1, -20, 0, 22), UDim2.new(0, 0, 0, 78), 16)
	local rewardLabel = createText(statsFrame, "RewardLabel", "Reward: +0", UDim2.new(1, -20, 0, 22), UDim2.new(0, 0, 0, 104), 16)

	local perfFrame = createFrame(screenGui, "PerformanceFrame", UDim2.new(0, 160, 0, 70), UDim2.new(1, -176, 0, 16))
	local fpsLabel = createText(perfFrame, "FpsLabel", "FPS: ...", UDim2.new(1, -20, 0, 22), UDim2.new(0, 12, 0, 12), 14)
	local pingLabel = createText(perfFrame, "PingLabel", "Ping: ...", UDim2.new(1, -20, 0, 22), UDim2.new(0, 12, 0, 38), 14)

	local settingsButton = createButton(screenGui, "SettingsButton", "SETTINGS", UDim2.new(0, 120, 0, 38), UDim2.new(1, -136, 0, 96))

	local menuFrame = createFrame(screenGui, "SettingsMenu", UDim2.new(0, 390, 0, 360), UDim2.new(0.5, -195, 0.5, -180))
	menuFrame.Visible = false

	createText(menuFrame, "Title", "PARAMÈTRES", UDim2.new(1, -50, 0, 30), UDim2.new(0, 18, 0, 16), 20)

	local closeButton = createButton(menuFrame, "CloseButton", "X", UDim2.new(0, 36, 0, 32), UDim2.new(1, -50, 0, 14))
	local qualityButton = createButton(menuFrame, "QualityButton", "Graphiques: " .. graphicsController:GetQuality(), UDim2.new(1, -36, 0, 42), UDim2.new(0, 18, 0, 62))

	createSlider(menuFrame, "MusicSlider", "Musique", UDim2.new(0, 18, 0, 122), musicVolume, function(value)
		musicVolume = value
		musicGroup.Volume = value
	end)

	createSlider(menuFrame, "SfxSlider", "SfxSlider", UDim2.new(0, 18, 0, 192), sfxVolume, function(value)
		sfxVolume = value
		sfxGroup.Volume = value
	end)

	local impactButton = createButton(menuFrame, "ImpactMarksButton", "Marques d'impact: ON", UDim2.new(1, -36, 0, 42), UDim2.new(0, 18, 0, 270))

	local function updateStats()
		local currentStuds = math.floor(localPlayer:GetAttribute("CurrentStuds") or getLeaderstatValue("Studs"))
		local currentFloor = math.floor(localPlayer:GetAttribute("CurrentFloor") or (currentStuds / GameConfig.StairSegmentHeight))
		local bestStuds = math.floor(localPlayer:GetAttribute("BestStuds") or getLeaderstatValue("Best"))
		local money = math.floor(localPlayer:GetAttribute("Money") or getLeaderstatValue("Money"))
		local lastReward = math.floor(localPlayer:GetAttribute("LastReward") or 0)

		studsLabel.Text = "Studs: " .. NumberUtil.formatInteger(currentStuds)
		floorLabel.Text = "Floor: " .. NumberUtil.formatInteger(currentFloor)
		bestLabel.Text = "Best: " .. NumberUtil.formatInteger(bestStuds)
		moneyLabel.Text = "Money: " .. NumberUtil.formatInteger(money)
		rewardLabel.Text = "Reward: +" .. NumberUtil.formatInteger(lastReward)
		qualityButton.Text = "Graphiques: " .. graphicsController:GetQuality()

		local insanity = math.clamp(localPlayer:GetAttribute("Insanity") or 0, 0, 100)
		local currentFloor = math.floor(localPlayer:GetAttribute("CurrentFloor") or 0)

		insanityFrame.Visible = currentFloor >= 1 or insanity > 0
		insanityBarFill.Size = UDim2.new(insanity / 100, 0, 1, 0)
	end

	settingsButton.Activated:Connect(function()
		menuFrame.Visible = not menuFrame.Visible
	end)

	closeButton.Activated:Connect(function()
		menuFrame.Visible = false
	end)

	qualityButton.Activated:Connect(function()
		graphicsController:CycleQuality()
		updateStats()
	end)

	impactButton.Activated:Connect(function()
		impactMarksEnabled = not impactMarksEnabled
		localPlayer:SetAttribute("ImpactMarksEnabled", impactMarksEnabled)

		local remotes = ReplicatedStorage:FindFirstChild("Remotes")
		if remotes and remotes:FindFirstChild("SetImpactMarksEnabled") then
			remotes.SetImpactMarksEnabled:FireServer(impactMarksEnabled)
		end

		impactButton.Text = impactMarksEnabled and "Marques d'impact: ON" or "Marques d'impact: OFF"
	end)

	graphicsController.Changed:Connect(updateStats)

	for _, attributeName in ipairs({
		"CurrentStuds",
		"CurrentFloor",
		"BestStuds",
		"Money",
		"LastReward",
	}) do
		localPlayer:GetAttributeChangedSignal(attributeName):Connect(updateStats)
	end

	RunService.RenderStepped:Connect(function(deltaTime)
		frameCount += 1
		frameTimer += deltaTime

		if frameTimer >= 0.5 then
			fps = math.floor(frameCount / frameTimer)
			frameCount = 0
			frameTimer = 0

			fpsLabel.Text = "FPS: " .. fps
			pingLabel.Text = "Ping: " .. getPing()
		end
	end)

	task.spawn(function()
		while true do
			updateStats()
			task.wait(0.5)
		end
	end)

	updateStats()
end

return UIController