local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local ActionButtonsController = {}

local localPlayer = Players.LocalPlayer

local restButton = nil
local runButton = nil
local auraButton = nil

local setRestingRemote = nil
local lastRestToggle = 0
local lastRunToggle = 0

local function getRestingRemote()
	if setRestingRemote then
		return setRestingRemote
	end

	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	setRestingRemote = remotes:WaitForChild("SetResting")

	return setRestingRemote
end

local function setResting(value)
	localPlayer:SetAttribute("IsResting", value)

	if value then
		localPlayer:SetAttribute("RunToggled", false)
	end

	getRestingRemote():FireServer(value)
end

local function toggleRest()
	if os.clock() - lastRestToggle < 0.18 then
		return
	end

	lastRestToggle = os.clock()

	local current = localPlayer:GetAttribute("IsResting") == true
	setResting(not current)
end

local function toggleRun()
	if os.clock() - lastRunToggle < 0.18 then
		return
	end

	lastRunToggle = os.clock()

	local current = localPlayer:GetAttribute("RunToggled") == true

	if not current then
		setResting(false)
	end

	localPlayer:SetAttribute("RunToggled", not current)
end

local function updateButtons()
	local resting = localPlayer:GetAttribute("IsResting") == true
	local runToggled = localPlayer:GetAttribute("RunToggled") == true

	if restButton then
		restButton.Text = resting and "REST: ON" or "REST"
		restButton.BackgroundColor3 = resting
			and Color3.fromRGB(80, 80, 110)
			or Color3.fromRGB(28, 28, 34)
	end

	if runButton then
		runButton.Text = runToggled and "RUN: ON" or "RUN"
		runButton.BackgroundColor3 = runToggled
			and Color3.fromRGB(55, 100, 70)
			or Color3.fromRGB(28, 28, 34)
	end

	if auraButton then
		auraButton.Text = "AURA"
	end
end

local function createButton(parent, name, text, position)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.fromOffset(86, 38)
	button.Position = position
	button.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
	button.BackgroundTransparency = 0.05
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.fromRGB(235, 235, 245)
	button.TextSize = 14
	button.Font = Enum.Font.GothamBold
	button.AutoButtonColor = true
	button.Parent = parent

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(75, 75, 90)
	stroke.Thickness = 1
	stroke.Transparency = 0.25
	stroke.Parent = button

	return button
end

local function createGui()
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	local old = playerGui:FindFirstChild("ActionButtonsGui")
	if old then
		old:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "ActionButtonsGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 200
	gui.Parent = playerGui

	local holder = Instance.new("Frame")
	holder.Name = "Holder"
	holder.Size = UDim2.fromOffset(282, 42)
	holder.AnchorPoint = Vector2.new(0.5, 1)
	holder.Position = UDim2.new(0.5, 0, 1, -28)
	holder.BackgroundTransparency = 1
	holder.Parent = gui

	restButton = createButton(holder, "RestButton", "REST", UDim2.fromOffset(0, 0))
	runButton = createButton(holder, "RunButton", "RUN", UDim2.fromOffset(98, 0))
	auraButton = createButton(holder, "AuraButton", "AURA", UDim2.fromOffset(196, 0))

	restButton.Activated:Connect(function()
		toggleRest()
	end)

	runButton.Activated:Connect(function()
		toggleRun()
	end)

	auraButton.Activated:Connect(function()
		print("[Aura] Pas encore configuré.")
	end)

	updateButtons()
end

local function onRestAction(_, inputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end

	if UserInputService:GetFocusedTextBox() then
		return Enum.ContextActionResult.Pass
	end

	toggleRest()
	return Enum.ContextActionResult.Sink
end

function ActionButtonsController:Start()
	localPlayer:SetAttribute("RunToggled", false)
	localPlayer:SetAttribute("IsResting", false)

	createGui()

	localPlayer:GetAttributeChangedSignal("IsResting"):Connect(updateButtons)
	localPlayer:GetAttributeChangedSignal("RunToggled"):Connect(updateButtons)

	ContextActionService:UnbindAction("ToggleRestAction")
	ContextActionService:BindAction(
		"ToggleRestAction",
		onRestAction,
		false,
		Enum.KeyCode.C
	)

	localPlayer.CharacterAdded:Connect(function()
		task.wait(0.1)
		setResting(false)
		localPlayer:SetAttribute("RunToggled", false)
		updateButtons()
	end)
end

return ActionButtonsController