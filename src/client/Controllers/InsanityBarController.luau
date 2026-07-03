local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CharacterBarsController = {}

local localPlayer = Players.LocalPlayer

local staminaFill = nil
local insanityFill = nil
local staminaGui = nil
local insanityGui = nil

local function removeOldTopInsanityGui()
	local playerGui = localPlayer:FindFirstChild("PlayerGui")
	if not playerGui then
		return
	end

	for _, name in ipairs({
		"InsanityHUD",
		"InsanityBarGui",
		"InsanityGui",
		"TopInsanityGui",
	}) do
		local old = playerGui:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end
end

local function createVerticalBar(character, name, offset, fillColor)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root then
		return nil, nil
	end

	local gui = Instance.new("BillboardGui")
	gui.Name = name
	gui.Adornee = root
	gui.AlwaysOnTop = true
	gui.MaxDistance = 120
	gui.Size = UDim2.fromOffset(6, 48)
	gui.StudsOffsetWorldSpace = offset
	gui.Parent = character

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.fromScale(1, 1)
	background.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
	background.BackgroundTransparency = 0.72
	background.BorderSizePixel = 0
	background.Parent = gui

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(230, 230, 230)
	stroke.Thickness = 0.25
	stroke.Transparency = 0.82
	stroke.Parent = background

	local holder = Instance.new("Frame")
	holder.Name = "Holder"
	holder.Size = UDim2.new(1, -2, 1, -2)
	holder.Position = UDim2.fromOffset(1, 1)
	holder.BackgroundTransparency = 1
	holder.ClipsDescendants = true
	holder.Parent = background

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.AnchorPoint = Vector2.new(0.5, 1)
	fill.Position = UDim2.fromScale(0.5, 1)
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = fillColor
	fill.BorderSizePixel = 0
	fill.Parent = holder

	return gui, fill
end

local function setupCharacter(character)
	removeOldTopInsanityGui()

	if staminaGui then
		staminaGui:Destroy()
		staminaGui = nil
	end

	if insanityGui then
		insanityGui:Destroy()
		insanityGui = nil
	end

	staminaGui, staminaFill = createVerticalBar(
		character,
		"StaminaBarWorld",
		Vector3.new(-1.05, 0.95, 0),
		Color3.fromRGB(80, 210, 135)
	)

	insanityGui, insanityFill = createVerticalBar(
		character,
		"InsanityBarWorld",
		Vector3.new(1.05, 0.95, 0),
		Color3.fromRGB(210, 45, 55)
	)
end

function CharacterBarsController:Start()
	removeOldTopInsanityGui()

	localPlayer.CharacterAdded:Connect(function(character)
		task.wait(0.2)
		setupCharacter(character)
	end)

	if localPlayer.Character then
		task.wait(0.2)
		setupCharacter(localPlayer.Character)
	end

	RunService.RenderStepped:Connect(function()
		removeOldTopInsanityGui()

		local stamina = math.clamp(localPlayer:GetAttribute("Stamina") or 100, 0, 100)
		local insanity = math.clamp(localPlayer:GetAttribute("Insanity") or 0, 0, 100)
		local floor = localPlayer:GetAttribute("CurrentFloor") or 0

		if staminaFill then
			staminaFill.Size = UDim2.fromScale(1, stamina / 100)
		end

		if insanityFill then
			insanityFill.Size = UDim2.fromScale(1, insanity / 100)
		end

		if staminaGui then
			staminaGui.Enabled = true
		end

		if insanityGui then
			insanityGui.Enabled = floor >= 1 or insanity > 0
		end
	end)
end

return CharacterBarsController