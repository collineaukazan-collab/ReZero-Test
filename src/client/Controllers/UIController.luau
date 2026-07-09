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

local fpsLabel = nil
local floorLabel = nil
local studsLabel = nil
local bestStudsLabel = nil
local currencyLabel = nil

local settingsFrame = nil
local settingsOpen = false
local graphicsController = nil

local fpsTimer = 0
local fpsFrames = 0
local currentFps = 0

local musicGroup = nil
local sfxGroup = nil

local THEME_BG = Color3.fromRGB(8, 8, 12)
local THEME_WHITE = Color3.fromRGB(255, 255, 255)
local THEME_DIM = Color3.fromRGB(220, 220, 235)

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

local function getCurrencyName()
	return GameConfig.CurrencyName or "Auracoins"
end

local function getCurrencyColor()
	return GameConfig.CurrencyColor or Color3.fromRGB(255, 221, 65)
end

local function getCurrencyValue()
	return localPlayer:GetAttribute("Auracoins")
		or localPlayer:GetAttribute("Money")
		or 0
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

local function createText(parent, name, text, size, position, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Size = size
	label.Position = position
	label.Text = text
	label.TextColor3 = color or THEME_WHITE
	label.TextSize = textSize or 15
	label.Font = Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextWrapped = true
	label.Parent = parent

	return label
end

local function createButton(parent, name, text, size)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.BackgroundColor3 = THEME_BG
	button.BackgroundTransparency = 0.08
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = THEME_WHITE
	button.TextSize = 16
	button.Font = Enum.Font.GothamBlack
	button.AutoButtonColor = true
	button.Parent = parent

	makeCorner(button, 8)
	makeStroke(button, THEME_WHITE, 1, 0.45)

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
		THEME_DIM
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
	local bestStuds = math.floor(localPlayer:GetAttribute("BestStuds") or localPlayer:GetAttribute("RunBestStuds") or 0)
	local auracoins = getCurrencyValue()

	fpsLabel.Text = "FPS : " .. tostring(currentFps)
	floorLabel.Text = "Floor : " .. formatInteger(floor)
	studsLabel.Text = "Height : " .. formatInteger(studs) .. " studs"
	bestStudsLabel.Text = "Best Studs : " .. formatInteger(bestStuds)
	currencyLabel.Text = getCurrencyName() .. " : " .. formatInteger(auracoins)
	currencyLabel.TextColor3 = getCurrencyColor()
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
	statsFrame.AnchorPoint = Vector2.new(1, 0)
	statsFrame.Position = UDim2.new(1, -16, 0, 14)
	statsFrame.Size = UDim2.fromOffset(315, 126)
	statsFrame.BackgroundColor3 = THEME_BG
	statsFrame.BackgroundTransparency = 0.18
	statsFrame.BorderSizePixel = 0
	statsFrame.Parent = screenGui

	makeCorner(statsFrame, 12)
	makeStroke(statsFrame, THEME_WHITE, 1, 0.55)

	fpsLabel = createText(statsFrame, "FpsLabel", "FPS : 0", UDim2.new(1, -20, 0, 20), UDim2.fromOffset(10, 8), 14, THEME_WHITE)
	floorLabel = createText(statsFrame, "FloorLabel", "Floor : 0", UDim2.new(1, -20, 0, 20), UDim2.fromOffset(10, 30), 15, THEME_WHITE)
	studsLabel = createText(statsFrame, "StudsLabel", "Height : 0 studs", UDim2.new(1, -20, 0, 20), UDim2.fromOffset(10, 52), 15, THEME_WHITE)
	bestStudsLabel = createText(statsFrame, "BestStudsLabel", "Best Studs : 0", UDim2.new(1, -20, 0, 20), UDim2.fromOffset(10, 74), 15, THEME_WHITE)
	currencyLabel = createText(statsFrame, "CurrencyLabel", "Auracoins : 0", UDim2.new(1, -20, 0, 20), UDim2.fromOffset(10, 96), 15, getCurrencyColor())
end

local function createQualityButton(row, name, qualityName)
	local button = createButton(row, name, qualityName, UDim2.fromOffset(96, 40))

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
	local audioConfig = GameConfig.Audio or {}

	musicGroup = getOrCreateSoundGroup("Music", audioConfig.MusicVolume or GameConfig.DefaultMusicVolume or 0.6)
	sfxGroup = getOrCreateSoundGroup("SFX", audioConfig.SfxVolume or GameConfig.DefaultSfxVolume or 0.8)

	settingsFrame = Instance.new("Frame")
	settingsFrame.Name = "SettingsFrame"
	settingsFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	settingsFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	settingsFrame.Size = UDim2.fromOffset(460, 420)
	settingsFrame.BackgroundColor3 = THEME_BG
	settingsFrame.BackgroundTransparency = 0.08
	settingsFrame.BorderSizePixel = 0
	settingsFrame.Visible = false
	settingsFrame.Parent = screenGui

	makeCorner(settingsFrame, 16)
	makeStroke(settingsFrame, THEME_WHITE, 2, 0.25)

	local title = createText(settingsFrame, "Title", "SETTINGS", UDim2.new(1, -30, 0, 46), UDim2.fromOffset(18, 12), 28, THEME_WHITE)
	title.Font = Enum.Font.GothamBlack

	local exitButton = createButton(settingsFrame, "ExitButton", "Exit", UDim2.fromOffset(90, 36))
	exitButton.Position = UDim2.new(1, -108, 0, 14)
	exitButton.BackgroundColor3 = THEME_WHITE
	exitButton.TextColor3 = Color3.fromRGB(0, 0, 0)
	exitButton.Activated:Connect(function()
		setSettingsVisible(false)
	end)

	local qualityTitle = createText(settingsFrame, "QualityTitle", "Graphics Quality", UDim2.fromOffset(240, 28), UDim2.fromOffset(22, 78), 18, THEME_DIM)
	qualityTitle.Font = Enum.Font.GothamBlack

	local qualityRow = Instance.new("Frame")
	qualityRow.Name = "QualityRow"
	qualityRow.Position = UDim2.fromOffset(22, 112)
	qualityRow.Size = UDim2.new(1, -44, 0, 42)
	qualityRow.BackgroundTransparency = 1
	qualityRow.Parent = settingsFrame

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 18)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = qualityRow

	createQualityButton(qualityRow, "LowQuality", "Low").LayoutOrder = 1
	createQualityButton(qualityRow, "MediumQuality", "Medium").LayoutOrder = 2
	createQualityButton(qualityRow, "HighQuality", "High").LayoutOrder = 3

	createSlider(settingsFrame, "MusicSlider", "Music", UDim2.fromOffset(22, 176), musicGroup.Volume, function(value)
		musicGroup.Volume = value
	end)

	createSlider(settingsFrame, "SfxSlider", "FX", UDim2.fromOffset(22, 240), sfxGroup.Volume, function(value)
		sfxGroup.Volume = value
	end)

	local impactButton = createButton(settingsFrame, "ImpactMarksButton", "Impact Marks : ON", UDim2.fromOffset(190, 42))
	impactButton.Position = UDim2.fromOffset(22, 318)

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