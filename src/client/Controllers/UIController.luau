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

local function createText(parent, name, text, size, position)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Size = size
	label.Position = position
	label.Font = Enum.Font.GothamBold
	label.TextSize = 17
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = Color3.fromRGB(245, 245, 255)
	label.TextStrokeTransparency = 0.55
	label.Text = text
	label.Parent = parent

	return label
end

local function createButton(parent, name, text, size, position)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
	button.BackgroundTransparency = 0.08
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.TextSize = 17
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Text = text
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button

	return button
end

local function createFrame(parent, name, size, position)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.Position = position
	frame.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
	frame.BackgroundTransparency = 0.08
	frame.BorderSizePixel = 0
	frame.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(80, 80, 110)
	stroke.Thickness = 1
	stroke.Transparency = 0.35
	stroke.Parent = frame

	return frame
end

local function createSlider(parent, name, title, position, defaultValue, callback)
	local container = Instance.new("Frame")
	container.Name = name
	container.Size = UDim2.new(1, -48, 0, 62)
	container.Position = position
	container.BackgroundTransparency = 1
	container.Parent = parent

	local label = createText(container, "Label", title .. ": " .. tostring(math.floor(defaultValue * 100)) .. "%", UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 0))

	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.Size = UDim2.new(1, 0, 0, 8)
	bar.Position = UDim2.new(0, 0, 0, 38)
	bar.BackgroundColor3 = Color3.fromRGB(45, 45, 62)
	bar.BorderSizePixel = 0
	bar.Parent = container

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(1, 0)
	barCorner.Parent = bar

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(defaultValue, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(120, 120, 180)
	fill.BorderSizePixel = 0
	fill.Parent = bar

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.Size = UDim2.new(0, 18, 0, 18)
	knob.Position = UDim2.new(defaultValue, -9, 0.5, -9)
	knob.BackgroundColor3 = Color3.fromRGB(230, 230, 255)
	knob.BorderSizePixel = 0
	knob.Parent = bar

	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0)
	knobCorner.Parent = knob

	local dragging = false
	local value = defaultValue

	local function setValueFromX(x)
		local relative = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		value = relative

		fill.Size = UDim2.new(value, 0, 1, 0)
		knob.Position = UDim2.new(value, -9, 0.5, -9)
		label.Text = title .. ": " .. tostring(math.floor(value * 100)) .. "%"

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

	return container
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

local function getPingText()
	local success, pingSeconds = pcall(function()
		return localPlayer:GetNetworkPing()
	end)

	if not success or type(pingSeconds) ~= "number" then
		return "Ping: N/A"
	end

	local pingMs = math.floor(pingSeconds * 2000)
	return "Ping: " .. tostring(pingMs) .. " ms"
end

local function getServerLocationText()
	return "Server: Roblox Cloud"
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

	local statsFrame = createFrame(screenGui, "StatsFrame", UDim2.new(0, 275, 0, 170), UDim2.new(0, 18, 0, 18))

	local statsPadding = Instance.new("UIPadding")
	statsPadding.PaddingTop = UDim.new(0, 12)
	statsPadding.PaddingLeft = UDim.new(0, 14)
	statsPadding.PaddingRight = UDim.new(0, 14)
	statsPadding.Parent = statsFrame

	local statsLayout = Instance.new("UIListLayout")
	statsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	statsLayout.Padding = UDim.new(0, 6)
	statsLayout.Parent = statsFrame

	local studsLabel = createText(statsFrame, "StudsLabel", "Studs: 0", UDim2.new(1, 0, 0, 22), UDim2.new())
	local floorLabel = createText(statsFrame, "FloorLabel", "Floor: 0", UDim2.new(1, 0, 0, 22), UDim2.new())
	local bestLabel = createText(statsFrame, "BestLabel", "Best: 0", UDim2.new(1, 0, 0, 22), UDim2.new())
	local moneyLabel = createText(statsFrame, "MoneyLabel", "Money: 0", UDim2.new(1, 0, 0, 22), UDim2.new())
	local rewardLabel = createText(statsFrame, "RewardLabel", "Last reward: +0", UDim2.new(1, 0, 0, 22), UDim2.new())

	local performanceFrame = createFrame(screenGui, "PerformanceFrame", UDim2.new(0, 245, 0, 92), UDim2.new(1, -263, 0, 18))

	local perfPadding = Instance.new("UIPadding")
	perfPadding.PaddingTop = UDim.new(0, 10)
	perfPadding.PaddingLeft = UDim.new(0, 12)
	perfPadding.Parent = performanceFrame

	local fpsLabel = createText(performanceFrame, "FpsLabel", "FPS: ...", UDim2.new(1, -20, 0, 22), UDim2.new(0, 0, 0, 0))
	local pingLabel = createText(performanceFrame, "PingLabel", "Ping: ...", UDim2.new(1, -20, 0, 22), UDim2.new(0, 0, 0, 27))
	local serverLabel = createText(performanceFrame, "ServerLabel", getServerLocationText(), UDim2.new(1, -20, 0, 22), UDim2.new(0, 0, 0, 54))

	local settingsButton = createButton(screenGui, "SettingsButton", "⚙", UDim2.new(0, 54, 0, 54), UDim2.new(1, -72, 0, 122))
	settingsButton.TextSize = 26

	local menuFrame = createFrame(screenGui, "SettingsMenu", UDim2.new(0, 420, 0, 400), UDim2.new(0.5, -210, 0.5, -200))
	menuFrame.Visible = false

	local title = createText(menuFrame, "Title", "PARAMÈTRES", UDim2.new(1, -40, 0, 36), UDim2.new(0, 24, 0, 18))
	title.TextSize = 24

	local closeButton = createButton(menuFrame, "CloseButton", "X", UDim2.new(0, 38, 0, 38), UDim2.new(1, -52, 0, 16))

	local qualityButton = createButton(menuFrame, "QualityButton", "Graphiques: " .. graphicsController:GetQuality(), UDim2.new(1, -48, 0, 46), UDim2.new(0, 24, 0, 75))

	local renderInfoLabel = createText(menuFrame, "RenderInfoLabel", "", UDim2.new(1, -48, 0, 28), UDim2.new(0, 24, 0, 125))
	renderInfoLabel.TextSize = 14

	createSlider(menuFrame, "MusicSlider", "Musique", UDim2.new(0, 24, 0, 160), musicVolume, function(value)
		musicVolume = value
		musicGroup.Volume = value
	end)

	createSlider(menuFrame, "SfxSlider", "Effets sonores", UDim2.new(0, 24, 0, 235), sfxVolume, function(value)
		sfxVolume = value
		sfxGroup.Volume = value
	end)

	local infoLabel = createText(menuFrame, "InfoLabel", "Debug: appuie sur F pour activer/désactiver le vol.", UDim2.new(1, -48, 0, 54), UDim2.new(0, 24, 0, 325))
	infoLabel.TextSize = 15
	infoLabel.TextWrapped = true

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
		rewardLabel.Text = "Last reward: +" .. NumberUtil.formatInteger(lastReward)

		qualityButton.Text = "Graphiques: " .. graphicsController:GetQuality()
		renderInfoLabel.Text = "Affichage: +" .. graphicsController:GetRenderDistanceAbove() .. " studs / -" .. graphicsController:GetRenderDistanceBelow() .. " studs"
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

			fpsLabel.Text = "FPS: " .. tostring(fps)
			pingLabel.Text = getPingText()
			serverLabel.Text = getServerLocationText()
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