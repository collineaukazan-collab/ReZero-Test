local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local CharacterBarsController = {}

local localPlayer = Players.LocalPlayer

local staminaFill = nil
local insanityFill = nil
local staminaGui = nil
local insanityGui = nil

local staminaStroke = nil
local insanityStroke = nil

local currentCharacter = nil
local currentRoot = nil

local function isInsideAllowedGui(instance)
	local current = instance

	while current do
		if current.Name == "InsanityEffectsGui" then
			return true
		end

		if current.Name == "DeathEffectsGui" then
			return true
		end

		current = current.Parent
	end

	return false
end

local function removeOldTopInsanityGui()
	local playerGui = localPlayer:FindFirstChild("PlayerGui")
	if not playerGui then
		return
	end

	for _, descendant in ipairs(playerGui:GetDescendants()) do
		if isInsideAllowedGui(descendant) then
			continue
		end

		if descendant:IsA("GuiObject") then
			local name = string.lower(descendant.Name)

			if string.find(name, "insanity")
				or string.find(name, "sanity")
			then
				descendant:Destroy()
			end
		end

		if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
			local text = string.lower(descendant.Text)

			if string.find(text, "insanity")
				or string.find(text, "sanity")
			then
				descendant:Destroy()
			end
		end
	end
end

local function createVerticalBar(character, name, offset, fillColor)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root then
		return nil, nil, nil
	end

	local gui = Instance.new("BillboardGui")
	gui.Name = name
	gui.Adornee = root
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.MaxDistance = 160
	gui.Size = UDim2.fromOffset(5, 42)
	gui.StudsOffsetWorldSpace = offset
	gui.Parent = character

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.fromScale(1, 1)
	background.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
	background.BackgroundTransparency = 0.82
	background.BorderSizePixel = 0
	background.Parent = gui

	local stroke = Instance.new("UIStroke")
	stroke.Name = "VeryThinStroke"
	stroke.Color = Color3.fromRGB(230, 230, 230)
	stroke.Thickness = 0.2
	stroke.Transparency = 0.9
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

	return gui, fill, stroke
end

local function getCharacterScreenHeight()
	if not currentCharacter then
		return 80
	end

	local camera = Workspace.CurrentCamera
	if not camera then
		return 80
	end

	local head = currentCharacter:FindFirstChild("Head")
	local leftLeg = currentCharacter:FindFirstChild("Left Leg")
	local rightLeg = currentCharacter:FindFirstChild("Right Leg")
	local root = currentCharacter:FindFirstChild("HumanoidRootPart")

	if not root then
		return 80
	end

	local topPosition
	local bottomPosition

	if head then
		topPosition = head.Position + Vector3.new(0, head.Size.Y * 0.7, 0)
	else
		topPosition = root.Position + Vector3.new(0, 3, 0)
	end

	if leftLeg and rightLeg then
		local leftBottom = leftLeg.Position - Vector3.new(0, leftLeg.Size.Y * 0.5, 0)
		local rightBottom = rightLeg.Position - Vector3.new(0, rightLeg.Size.Y * 0.5, 0)

		if leftBottom.Y < rightBottom.Y then
			bottomPosition = leftBottom
		else
			bottomPosition = rightBottom
		end
	else
		bottomPosition = root.Position - Vector3.new(0, 3, 0)
	end

	local topScreen, topVisible = camera:WorldToViewportPoint(topPosition)
	local bottomScreen, bottomVisible = camera:WorldToViewportPoint(bottomPosition)

	if not topVisible and not bottomVisible then
		return 40
	end

	local screenHeight = math.abs(topScreen.Y - bottomScreen.Y)

	return math.clamp(screenHeight, 35, 160)
end

local function updateBarsFromCamera()
	local characterHeight = getCharacterScreenHeight()

	-- Taille corrigée par rapport à la taille visible du personnage.
	local barHeight = math.clamp(characterHeight * 0.42, 24, 58)
	local barWidth = math.clamp(barHeight * 0.12, 3, 6)

	-- Écart par rapport au corps.
	local offsetScale = math.clamp(characterHeight / 90, 0.65, 1.25)

	local sideOffset = 0.95 * offsetScale
	local heightOffset = 0.9 * offsetScale

	if staminaGui then
		staminaGui.Size = UDim2.fromOffset(barWidth, barHeight)
		staminaGui.StudsOffsetWorldSpace = Vector3.new(-sideOffset, heightOffset, 0)
	end

	if insanityGui then
		insanityGui.Size = UDim2.fromOffset(barWidth, barHeight)
		insanityGui.StudsOffsetWorldSpace = Vector3.new(sideOffset, heightOffset, 0)
	end

	if staminaStroke then
		staminaStroke.Thickness = math.clamp(barWidth * 0.035, 0.12, 0.25)
	end

	if insanityStroke then
		insanityStroke.Thickness = math.clamp(barWidth * 0.035, 0.12, 0.25)
	end
end

local function setupCharacter(character)
	currentCharacter = character
	currentRoot = character:WaitForChild("HumanoidRootPart", 10)

	removeOldTopInsanityGui()

	if staminaGui then
		staminaGui:Destroy()
		staminaGui = nil
	end

	if insanityGui then
		insanityGui:Destroy()
		insanityGui = nil
	end

	if not currentRoot then
		return
	end

	staminaGui, staminaFill, staminaStroke = createVerticalBar(
		character,
		"StaminaBarWorld",
		Vector3.new(-0.95, 0.9, 0),
		Color3.fromRGB(80, 210, 135)
	)

	insanityGui, insanityFill, insanityStroke = createVerticalBar(
		character,
		"InsanityBarWorld",
		Vector3.new(0.95, 0.9, 0),
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
		updateBarsFromCamera()

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