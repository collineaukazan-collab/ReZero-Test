local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local ActionButtonsController = {}

local localPlayer = Players.LocalPlayer

local mainFrame = nil
local runButton = nil
local restButton = nil
local auraButton = nil
local pushButton = nil

local setRestingRemote = nil
local pushRemote = nil

local normalPosition = UDim2.new(0.5, -214, 1, -76)
local hiddenPosition = UDim2.new(0.5, -214, 1, 50)

local restToggled = false
local cHeld = false
local pushCooldown = false

local THEME_BG = Color3.fromRGB(8, 8, 12)
local THEME_WHITE = Color3.fromRGB(255, 255, 255)

local function makeStroke(parent)
	local stroke = Instance.new("UIStroke")
	stroke.Color = THEME_WHITE
	stroke.Thickness = 1
	stroke.Transparency = 0.25
	stroke.Parent = parent
end

local function createButton(parent, name, text, index)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.fromOffset(96, 42)
	button.Position = UDim2.fromOffset((index - 1) * 108, 0)
	button.BackgroundColor3 = THEME_BG
	button.BackgroundTransparency = 0.05
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = THEME_WHITE
	button.TextSize = 15
	button.Font = Enum.Font.GothamBlack
	button.AutoButtonColor = true
	button.Parent = parent

	makeStroke(button)

	return button
end

local function setMenuHidden(hidden)
	if not mainFrame then
		return
	end

	TweenService:Create(
		mainFrame,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = hidden and hiddenPosition or normalPosition }
	):Play()
end

local function setResting(value)
	localPlayer:SetAttribute("IsResting", value == true)

	if setRestingRemote then
		setRestingRemote:FireServer(value == true)
	end
end

local function refreshButtons()
	local runToggled = localPlayer:GetAttribute("RunToggled") == true
	local resting = localPlayer:GetAttribute("IsResting") == true

	if runButton then
		runButton.BackgroundColor3 = runToggled and Color3.fromRGB(40, 28, 70) or THEME_BG
	end

	if restButton then
		restButton.BackgroundColor3 = resting and Color3.fromRGB(40, 28, 70) or THEME_BG
	end
end

local function toggleRun()
	local newValue = not (localPlayer:GetAttribute("RunToggled") == true)

	if newValue then
		restToggled = false
		setResting(false)
	end

	localPlayer:SetAttribute("RunToggled", newValue)
	refreshButtons()
end

local function toggleRest()
	restToggled = not restToggled

	if restToggled then
		localPlayer:SetAttribute("RunToggled", false)
	end

	setResting(restToggled)
	refreshButtons()
end

local function setHoldRest(value)
	cHeld = value == true

	if cHeld then
		restToggled = false
		localPlayer:SetAttribute("RunToggled", false)
		setResting(true)
	else
		if not restToggled then
			setResting(false)
		end
	end

	refreshButtons()
end

local function push()
	if pushCooldown then
		return
	end

	pushCooldown = true

	if pushRemote then
		pushRemote:FireServer()
	end

	if pushButton then
		pushButton.Text = "..."
	end

	task.delay(0.35, function()
		if pushButton then
			pushButton.Text = "PUSH"
		end
	end)

	task.delay(2.2, function()
		pushCooldown = false
	end)
end

function ActionButtonsController:Start()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	setRestingRemote = remotes:WaitForChild("SetResting")
	pushRemote = remotes:WaitForChild("PushRequest")

	local playerGui = localPlayer:WaitForChild("PlayerGui")

	local old = playerGui:FindFirstChild("ActionButtonsGui")
	if old then
		old:Destroy()
	end

	local oldPush = playerGui:FindFirstChild("PushButtonGui")
	if oldPush then
		oldPush:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "ActionButtonsGui"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 350
	gui.Parent = playerGui

	mainFrame = Instance.new("Frame")
	mainFrame.Name = "ActionButtonsFrame"
	mainFrame.Position = normalPosition
	mainFrame.Size = UDim2.fromOffset(428, 44)
	mainFrame.BackgroundTransparency = 1
	mainFrame.Parent = gui

	restButton = createButton(mainFrame, "RestButton", "REST", 1)
	runButton = createButton(mainFrame, "RunButton", "RUN", 2)
	auraButton = createButton(mainFrame, "AuraButton", "AURA", 3)
	pushButton = createButton(mainFrame, "PushButton", "PUSH", 4)

	restButton.Activated:Connect(toggleRest)
	runButton.Activated:Connect(toggleRun)
	pushButton.Activated:Connect(push)

	auraButton.Activated:Connect(function()
		print("[ActionButtonsController] Aura button pressed.")
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			localPlayer:SetAttribute("RunToggled", true)
			refreshButtons()
		elseif input.KeyCode == Enum.KeyCode.C then
			setHoldRest(true)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.C then
			setHoldRest(false)
		end
	end)

	playerGui:GetAttributeChangedSignal("MenuOpen"):Connect(function()
		setMenuHidden(playerGui:GetAttribute("MenuOpen") == true)
	end)

	localPlayer:GetAttributeChangedSignal("RunToggled"):Connect(refreshButtons)
	localPlayer:GetAttributeChangedSignal("IsResting"):Connect(refreshButtons)

	refreshButtons()
end

return ActionButtonsController