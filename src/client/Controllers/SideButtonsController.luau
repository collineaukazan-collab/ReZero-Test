local Players = game:GetService("Players")

local SideButtonsController = {}

local localPlayer = Players.LocalPlayer

local function makeStroke(parent)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Thickness = 1
	stroke.Transparency = 0.25
	stroke.Parent = parent
end

local function createSideButton(parent, name, text, order)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.fromOffset(54, 54)
	button.Position = UDim2.fromOffset(10, 18 + (order - 1) * 68)
	button.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
	button.BackgroundTransparency = 0.08
	button.BorderSizePixel = 0
	button.Text = text
	button.Font = Enum.Font.GothamBlack
	button.TextSize = 22
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Parent = parent

	makeStroke(button)

	return button
end

local function toggleSettingsFallback()
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	for _, instance in ipairs(playerGui:GetDescendants()) do
		if instance:IsA("Frame") and string.find(string.lower(instance.Name), "setting") then
			instance.Visible = not instance.Visible
			playerGui:SetAttribute("MenuOpen", instance.Visible)
			return
		end
	end

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
	frame.Size = UDim2.fromOffset(78, 320)
	frame.Position = UDim2.fromOffset(0, 120)
	frame.BackgroundTransparency = 1
	frame.Parent = gui

	local sinsButton = createSideButton(frame, "SinsButton", "☰", 1)
	local settingsButton = createSideButton(frame, "SettingsButton", "⚙", 2)

	sinsButton.Activated:Connect(function()
		playerGui:SetAttribute("SinsMenuSignal", (playerGui:GetAttribute("SinsMenuSignal") or 0) + 1)
	end)

	settingsButton.Activated:Connect(function()
		toggleSettingsFallback()
	end)
end

return SideButtonsController