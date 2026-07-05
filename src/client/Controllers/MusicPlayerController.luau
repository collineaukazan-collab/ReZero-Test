local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local MusicPlayerController = {}

local localPlayer = Players.LocalPlayer

local musicController = nil

local titleLabel = nil
local timeLeftLabel = nil
local timeRightLabel = nil
local playButton = nil
local loopButton = nil
local speedLabel = nil

local progressFill = nil
local progressKnob = nil
local volumeFill = nil
local volumeKnob = nil

local progressBar = nil
local volumeBar = nil

local draggingProgress = false
local draggingVolume = false

local function formatTime(seconds)
	seconds = math.max(0, math.floor(seconds or 0))

	local minutes = math.floor(seconds / 60)
	local remaining = seconds % 60

	return string.format("%d:%02d", minutes, remaining)
end

local function setBarValue(fill, knob, value)
	if not fill or not knob then
		return
	end

	value = math.clamp(value or 0, 0, 1)

	fill.Size = UDim2.new(value, 0, 1, 0)
	knob.Position = UDim2.new(value, -5, 0.5, -5)
end

local function makeCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent

	return corner
end

local function makeStroke(parent, color, transparency, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Transparency = transparency
	stroke.Thickness = thickness
	stroke.Parent = parent

	return stroke
end

local function createButton(parent, name, text, position, size)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size or UDim2.fromOffset(38, 34)
	button.Position = position
	button.BackgroundColor3 = Color3.fromRGB(18, 19, 24)
	button.BackgroundTransparency = 0.08
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.fromRGB(235, 235, 245)
	button.TextSize = 15
	button.Font = Enum.Font.GothamBold
	button.AutoButtonColor = true
	button.Parent = parent

	makeCorner(button, 9)
	makeStroke(button, Color3.fromRGB(55, 55, 70), 0.55, 1)

	return button
end

local function createBar(parent, name, position, size)
	local bar = Instance.new("Frame")
	bar.Name = name
	bar.Position = position
	bar.Size = size
	bar.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
	bar.BackgroundTransparency = 0.15
	bar.BorderSizePixel = 0
	bar.Parent = parent

	makeCorner(bar, 10)

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Color3.fromRGB(145, 75, 255)
	fill.BorderSizePixel = 0
	fill.Parent = bar

	makeCorner(fill, 10)

	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.Size = UDim2.fromOffset(10, 10)
	knob.Position = UDim2.new(0, -5, 0.5, -5)
	knob.BackgroundColor3 = Color3.fromRGB(230, 230, 240)
	knob.BorderSizePixel = 0
	knob.Parent = bar

	makeCorner(knob, 50)

	return bar, fill, knob
end

local function setProgressFromInputX(x)
	if not progressBar or not musicController then
		return
	end

	local alpha = math.clamp(
		(x - progressBar.AbsolutePosition.X) / progressBar.AbsoluteSize.X,
		0,
		1
	)

	musicController:Seek(alpha)
	setBarValue(progressFill, progressKnob, alpha)
end

local function setVolumeFromInputX(x)
	if not volumeBar or not musicController then
		return
	end

	local alpha = math.clamp(
		(x - volumeBar.AbsolutePosition.X) / volumeBar.AbsoluteSize.X,
		0,
		1
	)

	musicController:SetVolume(alpha)
	setBarValue(volumeFill, volumeKnob, alpha)
end

local function createGui()
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	local old = playerGui:FindFirstChild("MusicPlayerGui")
	if old then
		old:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "MusicPlayerGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 250
	gui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "RadioFrame"
	frame.AnchorPoint = Vector2.new(1, 1)
	frame.Position = UDim2.new(1, -22, 1, -22)
	frame.Size = UDim2.fromOffset(392, 122)
	frame.BackgroundColor3 = Color3.fromRGB(8, 9, 13)
	frame.BackgroundTransparency = 0.08
	frame.BorderSizePixel = 0
	frame.Parent = gui

	makeCorner(frame, 16)
	makeStroke(frame, Color3.fromRGB(60, 60, 78), 0.35, 1)

	titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.BackgroundTransparency = 1
	titleLabel.Position = UDim2.fromOffset(14, 10)
	titleLabel.Size = UDim2.new(1, -28, 0, 22)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 14
	titleLabel.TextColor3 = Color3.fromRGB(240, 235, 255)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Center
	titleLabel.Text = "Radio"
	titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	titleLabel.Parent = frame

	progressBar, progressFill, progressKnob = createBar(
		frame,
		"ProgressBar",
		UDim2.fromOffset(14, 38),
		UDim2.new(1, -28, 0, 4)
	)

	timeLeftLabel = Instance.new("TextLabel")
	timeLeftLabel.Name = "CurrentTime"
	timeLeftLabel.BackgroundTransparency = 1
	timeLeftLabel.Position = UDim2.fromOffset(14, 47)
	timeLeftLabel.Size = UDim2.fromOffset(70, 18)
	timeLeftLabel.Font = Enum.Font.Gotham
	timeLeftLabel.TextSize = 11
	timeLeftLabel.TextColor3 = Color3.fromRGB(135, 115, 205)
	timeLeftLabel.TextXAlignment = Enum.TextXAlignment.Left
	timeLeftLabel.Text = "0:00"
	timeLeftLabel.Parent = frame

	timeRightLabel = Instance.new("TextLabel")
	timeRightLabel.Name = "TotalTime"
	timeRightLabel.BackgroundTransparency = 1
	timeRightLabel.AnchorPoint = Vector2.new(1, 0)
	timeRightLabel.Position = UDim2.new(1, -14, 0, 47)
	timeRightLabel.Size = UDim2.fromOffset(70, 18)
	timeRightLabel.Font = Enum.Font.Gotham
	timeRightLabel.TextSize = 11
	timeRightLabel.TextColor3 = Color3.fromRGB(135, 115, 205)
	timeRightLabel.TextXAlignment = Enum.TextXAlignment.Right
	timeRightLabel.Text = "0:00"
	timeRightLabel.Parent = frame

	local previousButton = createButton(frame, "PreviousButton", "<<", UDim2.fromOffset(14, 72))
	playButton = createButton(frame, "PlayButton", "||", UDim2.fromOffset(58, 72))
	local nextButton = createButton(frame, "NextButton", ">>", UDim2.fromOffset(102, 72))
	loopButton = createButton(frame, "LoopButton", "LOOP", UDim2.fromOffset(146, 72), UDim2.fromOffset(54, 34))

	local volumeLabel = Instance.new("TextLabel")
	volumeLabel.Name = "VolumeLabel"
	volumeLabel.BackgroundTransparency = 1
	volumeLabel.Position = UDim2.fromOffset(210, 76)
	volumeLabel.Size = UDim2.fromOffset(32, 24)
	volumeLabel.Font = Enum.Font.GothamBold
	volumeLabel.TextSize = 12
	volumeLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
	volumeLabel.Text = "VOL"
	volumeLabel.Parent = frame

	volumeBar, volumeFill, volumeKnob = createBar(
		frame,
		"VolumeBar",
		UDim2.fromOffset(244, 86),
		UDim2.fromOffset(58, 4)
	)

	local speedMinus = createButton(frame, "SpeedMinus", "-", UDim2.fromOffset(314, 75), UDim2.fromOffset(22, 28))

	speedLabel = Instance.new("TextLabel")
	speedLabel.Name = "SpeedLabel"
	speedLabel.BackgroundTransparency = 1
	speedLabel.Position = UDim2.fromOffset(336, 77)
	speedLabel.Size = UDim2.fromOffset(34, 24)
	speedLabel.Font = Enum.Font.GothamMedium
	speedLabel.TextSize = 11
	speedLabel.TextColor3 = Color3.fromRGB(200, 190, 235)
	speedLabel.Text = "1.00x"
	speedLabel.Parent = frame

	local speedPlus = createButton(frame, "SpeedPlus", "+", UDim2.fromOffset(370, 75), UDim2.fromOffset(22, 28))

	previousButton.Activated:Connect(function()
		musicController:Previous()
	end)

	playButton.Activated:Connect(function()
		musicController:TogglePause()
	end)

	nextButton.Activated:Connect(function()
		musicController:Next()
	end)

	loopButton.Activated:Connect(function()
		musicController:ToggleLoop()
	end)

	speedMinus.Activated:Connect(function()
		local state = musicController:GetState()
		musicController:SetPlaybackSpeed((state.PlaybackSpeed or 1) - 0.05)
	end)

	speedPlus.Activated:Connect(function()
		local state = musicController:GetState()
		musicController:SetPlaybackSpeed((state.PlaybackSpeed or 1) + 0.05)
	end)

	progressBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingProgress = true
			setProgressFromInputX(input.Position.X)
		end
	end)

	volumeBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingVolume = true
			setVolumeFromInputX(input.Position.X)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end

		if draggingProgress then
			setProgressFromInputX(input.Position.X)
		elseif draggingVolume then
			setVolumeFromInputX(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingProgress = false
			draggingVolume = false
		end
	end)
end

local function updateUi()
	if not musicController then
		return
	end

	local state = musicController:GetState()
	local track = state.Track

	if titleLabel then
		titleLabel.Text = track and track.Name or "Aucune musique"
	end

	if playButton then
		playButton.Text = state.IsPlaying and "||" or ">"
	end

	if loopButton then
		loopButton.Text = state.LoopEnabled and "LOOP ON" or "LOOP"
		loopButton.BackgroundColor3 = state.LoopEnabled
			and Color3.fromRGB(90, 55, 150)
			or Color3.fromRGB(18, 19, 24)
	end

	if speedLabel then
		speedLabel.Text = string.format("%.2fx", state.PlaybackSpeed or 1)
	end

	if timeLeftLabel then
		timeLeftLabel.Text = formatTime(state.TimePosition)
	end

	if timeRightLabel then
		timeRightLabel.Text = formatTime(state.TimeLength)
	end

	local progress = 0

	if state.TimeLength and state.TimeLength > 0 then
		progress = state.TimePosition / state.TimeLength
	end

	setBarValue(progressFill, progressKnob, progress)
	setBarValue(volumeFill, volumeKnob, state.Volume or 0.6)
end

function MusicPlayerController:Start(injectedMusicController)
	musicController = injectedMusicController

	if not musicController then
		warn("[MusicPlayerController] Missing MusicController.")
		return
	end

	createGui()
	updateUi()

	if musicController.Changed then
		musicController.Changed:Connect(updateUi)
	end

	RunService.RenderStepped:Connect(function()
		updateUi()
	end)
end

return MusicPlayerController