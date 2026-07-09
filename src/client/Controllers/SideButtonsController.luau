local Players = game:GetService("Players")

local SideButtonsController = {}

local localPlayer = Players.LocalPlayer

local THEME_BG = Color3.fromRGB(8, 8, 12)
local THEME_WHITE = Color3.fromRGB(255, 255, 255)

local function makeStroke(parent)
	local stroke = Instance.new("UIStroke")
	stroke.Color = THEME_WHITE
	stroke.Thickness = 1
	stroke.Transparency = 0.25
	stroke.Parent = parent
end

local function createSideButton(parent, name, text, order)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.fromOffset(54, 54)
	button.Position = UDim2.fromOffset(10, 18 + (order - 1) * 68)
	button.BackgroundColor3 = THEME_BG
	button.BackgroundTransparency = 0.08
	button.BorderSizePixel = 0
	button.Text = text
	button.Font = Enum.Font.GothamBlack
	button.TextSize = 22
	button.TextColor3 = THEME_WHITE
	button.Parent = parent

	makeStroke(button)

	return button
end

local function toggleSettingsFallback()
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	playerGui:SetAttribute("SettingsMenuSignal", (playerGui:GetAttribute("SettingsMenuSignal") or 0) + 1)
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
	frame.Size = UDim2.fromOffset(78, 390)
	frame.Position = UDim2.fromOffset(0, 120)
	frame.BackgroundTransparency = 1
	frame.Parent = gui

	local sinsButton = createSideButton(frame, "SinsButton", "☰", 1)
	local upgradesButton = createSideButton(frame, "UpgradesButton", "↑", 2)
	local settingsButton = createSideButton(frame, "SettingsButton", "⚙", 3)

	sinsButton.Activated:Connect(function()
		playerGui:SetAttribute("SinsMenuSignal", (playerGui:GetAttribute("SinsMenuSignal") or 0) + 1)
	end)

	upgradesButton.Activated:Connect(function()
		playerGui:SetAttribute("UpgradesMenuSignal", (playerGui:GetAttribute("UpgradesMenuSignal") or 0) + 1)
		print("[SideButtonsController] Upgrades button pressed. Menu will be added later.")
	end)

	settingsButton.Activated:Connect(toggleSettingsFallback)
end

return SideButtonsController