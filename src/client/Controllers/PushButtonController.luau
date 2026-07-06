local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local PushButtonController = {}

local localPlayer = Players.LocalPlayer

local frame = nil
local normalPosition = nil
local hiddenPosition = nil
local pushRemote = nil
local cooldown = false

local function setHidden(hidden)
	if not frame then
		return
	end

	local target = hidden and hiddenPosition or normalPosition

	TweenService:Create(
		frame,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = target }
	):Play()
end

local function doPush()
	if cooldown then
		return
	end

	cooldown = true

	if pushRemote then
		pushRemote:FireServer()
	end

	task.delay((GameConfig.Push and GameConfig.Push.Cooldown) or 2.2, function()
		cooldown = false
	end)
end

function PushButtonController:Start()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	pushRemote = remotes:WaitForChild("PushRequest")

	local playerGui = localPlayer:WaitForChild("PlayerGui")

	local old = playerGui:FindFirstChild("PushButtonGui")
	if old then
		old:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "PushButtonGui"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 300
	gui.Parent = playerGui

	normalPosition = UDim2.new(0.5, -70, 1, -86)
	hiddenPosition = UDim2.new(0.5, -70, 1, 35)

	frame = Instance.new("Frame")
	frame.Name = "ActionButtonsFrame"
	frame.Size = UDim2.fromOffset(140, 58)
	frame.Position = normalPosition
	frame.BackgroundTransparency = 1
	frame.Parent = gui

	local button = Instance.new("TextButton")
	button.Name = "PushButton"
	button.Size = UDim2.fromScale(1, 1)
	button.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
	button.BackgroundTransparency = 0.05
	button.BorderSizePixel = 0
	button.Text = (GameConfig.Push and GameConfig.Push.ButtonText) or "PUSH"
	button.Font = Enum.Font.GothamBlack
	button.TextSize = 24
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Thickness = 2
	stroke.Transparency = 0.1
	stroke.Parent = button

	button.Activated:Connect(doPush)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.F then
			doPush()
		end
	end)

	playerGui:GetAttributeChangedSignal("MenuOpen"):Connect(function()
		setHidden(playerGui:GetAttribute("MenuOpen") == true)
	end)
end

return PushButtonController