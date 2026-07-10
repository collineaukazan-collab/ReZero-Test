local Players = game:GetService("Players")

local SideButtonsController = {}

local localPlayer = Players.LocalPlayer

local THEME_BG = Color3.fromRGB(8, 8, 12)
local THEME_WHITE = Color3.fromRGB(255, 255, 255)

local function makeCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

local function makeStroke(parent)
	local stroke = Instance.new("UIStroke")
	stroke.Color = THEME_WHITE
	stroke.Thickness = 1
	stroke.Transparency = 0.25
	stroke.Parent = parent
end

local function createSideButton(parent, name, text)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.fromOffset(60, 60)
	button.BackgroundColor3 = THEME_BG
	button.BackgroundTransparency = 0.07
	button.BorderSizePixel = 0
	button.Text = text
	button.Font = Enum.Font.GothamBlack
	button.TextSize = 24
	button.TextColor3 = THEME_WHITE
	button.Parent = parent

	makeCorner(button, 8)
	makeStroke(button)

	return button
end

function SideButtonsController:Start()
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	local old = playerGui:FindFirstChild("SideButtonsGui")
	if old then
		old:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "SideButtonsGui"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 450
	gui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "SideButtonsFrame"
	frame.AnchorPoint = Vector2.new(0, 0.5)
	frame.Position = UDim2.new(0, 10, 0.5, 0)
	frame.Size = UDim2.fromOffset(70, 280)
	frame.BackgroundTransparency = 1
	frame.Parent = gui

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 14)
	layout.Parent = frame

	local sinsButton = createSideButton(frame, "SinsButton", "☰")
	local upgradesButton = createSideButton(frame, "UpgradesButton", "↑")
	local settingsButton = createSideButton(frame, "SettingsButton", "⚙")

	sinsButton.Activated:Connect(function()
		playerGui:SetAttribute("SinsMenuSignal", (playerGui:GetAttribute("SinsMenuSignal") or 0) + 1)
	end)

	upgradesButton.Activated:Connect(function()
		playerGui:SetAttribute("UpgradesMenuSignal", (playerGui:GetAttribute("UpgradesMenuSignal") or 0) + 1)
		print("[SideButtonsController] Upgrades button pressed.")
	end)

	settingsButton.Activated:Connect(function()
		playerGui:SetAttribute("SettingsMenuSignal", (playerGui:GetAttribute("SettingsMenuSignal") or 0) + 1)
	end)
end

return SideButtonsController