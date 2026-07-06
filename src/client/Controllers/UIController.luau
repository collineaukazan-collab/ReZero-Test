local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local NumberUtil = nil

pcall(function()
	NumberUtil = require(ReplicatedStorage.Shared.Utils.NumberUtil)
end)

local UIController = {}

local localPlayer = Players.LocalPlayer

local screenGui = nil
local statsFrame = nil
local floorLabel = nil
local studsLabel = nil
local currencyLabel = nil
local fpsLabel = nil

local settingsFrame = nil
local settingsOpen = false

local graphicsController = nil

local fpsTimer = 0
local fpsFrames = 0
local currentFps = 0

local musicGroup = nil
local sfxGroup = nil

local function formatInteger(value)
	value = math.floor(tonumber(value) or 0)

	if NumberUtil and NumberUtil.formatInteger then
		return NumberUtil.formatInteger(value)
	end

	local text = tostring(value)
	local result = ""

	while #text > 3 do
		result = "," .. string.sub(text, -3) .. result
		text = string.sub(text, 1, #text - 3)
	end

	return text .. result
end

local function getAudioConfig()
	return GameConfig.Audio or {}
end

local function getCurrencyValue()
	return localPlayer:GetAttribute("Auracoins")
		or localPlayer:GetAttribute("Money")
		or 0
end

local function getCurrencyName()
	return GameConfig.CurrencyName or "Auracoins"
end

local function getCurrencyColor()
	return GameConfig.CurrencyColor or Color3.fromRGB(255, 221, 65)
end

local function getOrCreateSoundGroup(name, defaultVolume)
	local group = SoundService:FindFirstChild(name)

	if not group then
		group = Instance.new("SoundGroup")
		group.Name = name
		group.Volume = defaultVolume
		group.Parent = SoundService
	end

	return group
end

local function makeCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function makeStroke(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0
	stroke.Parent = parent
	return stroke
end

local function createText(parent, name, text, size, position, textSize, color, font)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Size = size
	label.Position = position
	label.Text = text
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.TextSize = textSize or 16
	label.Font = font or Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextWrapped = true
	label.Parent = parent

	return label
end

local function createButton(parent, name, text, size, position)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
	button.BackgroundTransparency = 0.08
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 16
	button.Font = Enum.Font.GothamBlack
	button.AutoButtonColor = true
	button.Parent = parent

	makeCorner(button, 8)
	makeStroke(button, Color3.fromRGB(255, 255, 255), 1, 0.45)

	return button
end

local function setMenuOpen(value)
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	playerGui:SetAttribute("MenuOpen", value == true)
end

local function createSlider(parent, name, title, position, defaultValue, callback)
	local container = Instance.new("Frame")
	container.Name = name
	container.Position = position
	container.Size = UDim2.fromOffset(330, 48)
	container.BackgroundTransparency = 1
	container.Parent = parent

	local label = createText(
		container,
		"Label",
		title .. " : " .. tostring(math.floor(defaultValue * 100)) .. "%",
		UDim2.new(1, 0, 0, 18),
		UDim2.fromOffset(0, 0),
		15,
		Color3.fromRGB(235, 235, 245),
		Enum.Font.GothamBold
	)

	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.Position = UDim2.fromOffset(0, 28)
	bar.Size = UDim2.new(1, 0, 0, 6)
	bar.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
	bar.BorderSizePixel = 0
	bar.Parent = container

	makeCorner(bar, 12)

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(defaultValue, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(150, 75, 255)
	fill.BorderSizePixel = 0
	fill.Parent = bar

	makeCorner(fill, 12)

	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.Size = UDim2.fromOffset(14, 14)
	knob.Position = UDim2.new(defaultValue, -7, 0.5, -7)
	knob.BackgroundColor3 = Color3.fromRGB(245, 245, 255)
	knob.BorderSizePixel = 0
	knob.Parent = bar

	makeCorner(knob, 50)

	local dragging = false

	local function setValueFromX(x)
		local alpha = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)

		fill.Size = UDim2.new(alpha, 0, 1, 0)
		knob.Position = UDim2.new(alpha, -7, 0.5, -7)
		label.Text = title .. " : " .. tostring(math.floor(alpha * 100)) .. "%"

		callback(alpha)
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
			setValueFromX(input.Position.X)
		end
	end)

	game:GetService("UserInputService").InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			setValueFromX(input.Position.X)
		end
	end)

	game:GetService("UserInputService").InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	return container
end

local function updateStats()
	local floor = math.floor(localPlayer:GetAttribute("CurrentFloor") or 0)
	local studs = math.floor(localPlayer:GetAttribute("CurrentStuds") or 0)
	local auracoins = getCurrencyValue()

	if floorLabel then
		floorLabel.Text = "Floor : " .. formatInteger(floor)
	end

	if studsLabel then
		studsLabel.Text = "Height : " .. formatInteger(studs) .. " studs"
	end

	if currencyLabel then
		currencyLabel.Text = getCurrencyName() .. " : " .. formatInteger(auracoins)
		currencyLabel.TextColor3 = getCurrencyColor()
	end

	if fpsLabel then
		fpsLabel.Text = "FPS : " .. tostring(currentFps)
	end
end

local function setSettingsVisible(value)
	if not settingsFrame then
		return
	end

	settingsOpen = value == true
	setMenuOpen(settingsOpen)

	if settingsOpen then
		settingsFrame.Visible = true
		settingsFrame.Position = UDim2.new(0.5, 0, 0.54, 0)

		TweenService:Create(
			settingsFrame,
			TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = UDim2.new(0.5, 0, 0.5, 0),
				BackgroundTransparency = 0.08,
			}
		):Play()
	else
		local tween = TweenService:Create(
			settingsFrame,
			TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{
				Position = UDim2.new(0.5, 0, 0.57, 0),
				BackgroundTransparency = 0.25,
			}
		)

		tween:Play()

		task.delay(0.18, function()
			if settingsFrame and not settingsOpen then
				settingsFrame.Visible = false
			end
		end)
	end
end

local function toggleSettings()
	setSettingsVisible(not settingsOpen)
end

local function createStatsGui()
	statsFrame = Instance.new("Frame")
	statsFrame.Name = "StatsFrame"
	statsFrame.Position = UDim2.fromOffset(16, 14)
	statsFrame.Size = UDim2.fromOffset(290, 104)
	statsFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
	statsFrame.BackgroundTransparency = 0.25
	statsFrame.BorderSizePixel = 0
	statsFrame.Parent = screenGui

	makeCorner(statsFrame, 12)
	makeStroke(statsFrame, Color3.fromRGB(255, 255, 255), 1, 0.65)

	fpsLabel = createText(
		statsFrame,
		"FpsLabel",
		"FPS : 0",
		UDim2.new(1, -20, 0, 24),
		UDim2.fromOffset(10, 6),
		15,
		Color3.fromRGB(210, 210, 220),
		Enum.Font.GothamBold
	)

	floorLabel = createText(
		statsFrame,
		"FloorLabel",
		"Floor : 0",
		UDim2.new(1, -20, 0, 24),
		UDim2.fromOffset(10, 32),
		17,
		Color3.fromRGB(255, 255, 255),
		Enum.Font.GothamBlack
	)

	studsLabel = createText(
		statsFrame,
		"StudsLabel",
		"Height : 0 studs",
		UDim2.new(1, -20, 0, 24),
		UDim2.fromOffset(10, 58),
		15,
		Color3.fromRGB(220, 220, 235),
		Enum.Font.GothamBold
	)

	currencyLabel = createText(
		statsFrame,
		"CurrencyLabel",
		getCurrencyName() .. " : 0",
		UDim2.new(1, -20, 0, 24),
		UDim2.fromOffset(10, 80),
		15,
		getCurrencyColor(),
		Enum.Font.GothamBlack
	)
end

local function createQualityButton(parent, name, qualityName, position)
	local button = createButton(
		parent,
		name,
		qualityName,
		UDim2.fromOffset(96, 40),
		position
	)

	button.Activated:Connect(function()
		if graphicsController and graphicsController.SetQuality then
			graphicsController:SetQuality(qualityName)
		elseif graphicsController and graphicsController.setQuality then
			graphicsController:setQuality(qualityName)
		end

		localPlayer:SetAttribute("GraphicsQuality", qualityName)
	end)

	return button
end

local function createSettingsGui()
	local audioConfig = getAudioConfig()

	musicGroup = getOrCreateSoundGroup(
		"Music",
		audioConfig.MusicVolume or GameConfig.DefaultMusicVolume or 0.6
	)

	sfxGroup = getOrCreateSoundGroup(
		"SFX",
		audioConfig.SfxVolume or GameConfig.DefaultSfxVolume or 0.8
	)

	settingsFrame = Instance.new("Frame")
	settingsFrame.Name = "SettingsFrame"
	settingsFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	settingsFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	settingsFrame.Size = UDim2.fromOffset(460, 420)
	settingsFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 13)
	settingsFrame.BackgroundTransparency = 0.08
	settingsFrame.BorderSizePixel = 0
	settingsFrame.Visible = false
	settingsFrame.Parent = screenGui

	makeCorner(settingsFrame, 16)
	makeStroke(settingsFrame, Color3.fromRGB(255, 255, 255), 2, 0.25)

	createText(
		settingsFrame,
		"Title",
		"SETTINGS",
		UDim2.new(1, -30, 0, 46),
		UDim2.fromOffset(18, 12),
		28,
		Color3.fromRGB(255, 255, 255),
		Enum.Font.GothamBlack
	)

	local exitButton = createButton(
		settingsFrame,
		"ExitButton",
		"Exit",
		UDim2.fromOffset(90, 36),
		UDim2.new(1, -108, 0, 14)
	)

	exitButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	exitButton.TextColor3 = Color3.fromRGB(0, 0, 0)
	exitButton.Activated:Connect(function()
		setSettingsVisible(false)
	end)

	createText(
		settingsFrame,
		"QualityTitle",
		"Graphics Quality",
		UDim2.fromOffset(240, 28),
		UDim2.fromOffset(22, 78),
		18,
		Color3.fromRGB(235, 235, 245),
		Enum.Font.GothamBlack
	)

	createQualityButton(settingsFrame, "LowQuality", "Low", UDim2.fromOffset(22, 112))
	createQualityButton(settingsFrame, "MediumQuality", "Medium", UDim2.fromOffset(132, 112))
	createQualityButton(settingsFrame, "HighQuality", "High", UDim2.fromOffset(262, 112))

	createSlider(
		settingsFrame,
		"MusicSlider",
		"Music",
		UDim2.fromOffset(22, 176),
		musicGroup.Volume,
		function(value)
			musicGroup.Volume = value
		end
	)

	createSlider(
		settingsFrame,
		"SfxSlider",
		"FX",
		UDim2.fromOffset(22, 240),
		sfxGroup.Volume,
		function(value)
			sfxGroup.Volume = value
		end
	)

	local impactButton = createButton(
		settingsFrame,
		"ImpactMarksButton",
		"Impact Marks : ON",
		UDim2.fromOffset(190, 42),
		UDim2.fromOffset(22, 318)
	)

	if localPlayer:GetAttribute("ImpactMarksEnabled") == nil then
		localPlayer:SetAttribute("ImpactMarksEnabled", GameConfig.DefaultImpactMarksEnabled ~= false)
	end

	local function refreshImpactButton()
		local enabled = localPlayer:GetAttribute("ImpactMarksEnabled") ~= false
		impactButton.Text = enabled and "Impact Marks : ON" or "Impact Marks : OFF"
	end

	refreshImpactButton()

	impactButton.Activated:Connect(function()
		local current = localPlayer:GetAttribute("ImpactMarksEnabled") ~= false
		localPlayer:SetAttribute("ImpactMarksEnabled", not current)
		refreshImpactButton()
	end)
end

local function setupMenuSignal()
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	playerGui:GetAttributeChangedSignal("SettingsMenuSignal"):Connect(function()
		toggleSettings()
	end)
end

function UIController:Start(injectedGraphicsController)
	graphicsController = injectedGraphicsController

	local playerGui = localPlayer:WaitForChild("PlayerGui")

	local old = playerGui:FindFirstChild("MainHudGui")
	if old then
		old:Destroy()
	end

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MainHudGui"
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 100
	screenGui.Parent = playerGui

	createStatsGui()
	createSettingsGui()
	setupMenuSignal()

	RunService.RenderStepped:Connect(function(dt)
		fpsFrames += 1
		fpsTimer += dt

		if fpsTimer >= 0.5 then
			currentFps = math.floor(fpsFrames / fpsTimer + 0.5)
			fpsFrames = 0
			fpsTimer = 0
		end

		updateStats()
	end)

	updateStats()

	print("[UIController] Started. Currency = Auracoins.")
end

return UIController