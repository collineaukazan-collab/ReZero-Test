local Players = game:GetService("Players")

local InsanityBarController = {}

local localPlayer = Players.LocalPlayer

local frame = nil
local leftFill = nil
local rightFill = nil

local function createGui()
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	local old = playerGui:FindFirstChild("InsanityHUD")
	if old then
		old:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "InsanityHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 40
	gui.Parent = playerGui

	frame = Instance.new("Frame")
	frame.Name = "InsanityFrame"
	frame.Size = UDim2.new(0, 440, 0, 48)
	frame.Position = UDim2.new(0.5, -220, 0, 18)
	frame.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
	frame.BackgroundTransparency = 0.04
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = gui

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(65, 65, 80)
	stroke.Thickness = 1
	stroke.Transparency = 0.25
	stroke.Parent = frame

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(0, 105, 1, 0)
	label.Position = UDim2.new(0, 14, 0, 0)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = Color3.fromRGB(230, 230, 240)
	label.Text = "INSANITY"
	label.Parent = frame

	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.Size = UDim2.new(1, -140, 0, 10)
	bar.Position = UDim2.new(0, 120, 0.5, -5)
	bar.BackgroundColor3 = Color3.fromRGB(34, 34, 44)
	bar.BorderSizePixel = 0
	bar.Parent = frame

	local centerLine = Instance.new("Frame")
	centerLine.Name = "CenterLine"
	centerLine.Size = UDim2.new(0, 2, 1, 6)
	centerLine.Position = UDim2.new(0.5, -1, 0, -3)
	centerLine.BackgroundColor3 = Color3.fromRGB(220, 220, 230)
	centerLine.BorderSizePixel = 0
	centerLine.Parent = bar

	leftFill = Instance.new("Frame")
	leftFill.Name = "LeftFill"
	leftFill.AnchorPoint = Vector2.new(1, 0)
	leftFill.Position = UDim2.new(0.5, 0, 0, 0)
	leftFill.Size = UDim2.new(0, 0, 1, 0)
	leftFill.BackgroundColor3 = Color3.fromRGB(125, 15, 42)
	leftFill.BorderSizePixel = 0
	leftFill.Parent = bar

	rightFill = Instance.new("Frame")
	rightFill.Name = "RightFill"
	rightFill.Position = UDim2.new(0.5, 0, 0, 0)
	rightFill.Size = UDim2.new(0, 0, 1, 0)
	rightFill.BackgroundColor3 = Color3.fromRGB(125, 15, 42)
	rightFill.BorderSizePixel = 0
	rightFill.Parent = bar
end

local function update()
	local insanity = math.clamp(localPlayer:GetAttribute("Insanity") or 0, 0, 100)
	local floor = math.floor(localPlayer:GetAttribute("CurrentFloor") or 0)

	local ratio = insanity / 100
	local halfRatio = ratio / 2

	frame.Visible = floor >= 1 or insanity > 0

	leftFill.Size = UDim2.new(halfRatio, 0, 1, 0)
	rightFill.Size = UDim2.new(halfRatio, 0, 1, 0)
end

function InsanityBarController:Start()
	createGui()

	for _, attributeName in ipairs({
		"Insanity",
		"CurrentFloor",
	}) do
		localPlayer:GetAttributeChangedSignal(attributeName):Connect(update)
	end

	task.spawn(function()
		while true do
			update()
			task.wait(0.1)
		end
	end)

	update()
end

return InsanityBarController