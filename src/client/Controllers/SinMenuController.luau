local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SinMenuController = {}

local localPlayer = Players.LocalPlayer

local gui = nil
local mainFrame = nil
local currentSinLabel = nil
local currentDescription = nil
local shardsLabel = nil
local rollButton = nil
local slotsFrame = nil
local chancesFrame = nil
local selectedSlot = 1

local getSinStateRemote = nil
local rollSinRemote = nil
local openSinMenuRemote = nil
local sinStateChangedRemote = nil

local currentState = nil

local function getRemotes()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")

	getSinStateRemote = remotes:WaitForChild("GetSinState")
	rollSinRemote = remotes:WaitForChild("RollSin")
	openSinMenuRemote = remotes:WaitForChild("OpenSinMenu")
	sinStateChangedRemote = remotes:WaitForChild("SinStateChanged")
end

local function makeCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function makeStroke(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0
	stroke.Parent = parent
	return stroke
end

local function createText(parent, name, text, size, position, textSize, color, font)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Size = size
	label.Position = position
	label.Text = text
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.TextSize = textSize or 18
	label.Font = font or Enum.Font.GothamBold
	label.TextWrapped = true
	label.Parent = parent
	return label
end

local function createButton(parent, name, text, size, position)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = Color3.fromRGB(10, 7, 13)
	button.BackgroundTransparency = 0.05
	button.BorderSizePixel = 0
	button.Text = text
	button.Font = Enum.Font.GothamBlack
	button.TextSize = 22
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.AutoButtonColor = true
	button.Parent = parent

	makeCorner(button, 0)
	makeStroke(button, Color3.fromRGB(255, 255, 255), 2, 0.05)

	return button
end

local function setMenuOpen(value)
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	playerGui:SetAttribute("MenuOpen", value == true)
end

local function getDefinition(sinName)
	if not currentState or not currentState.Definitions then
		return nil
	end

	return currentState.Definitions[sinName]
end

local function refreshCurrentSin()
	if not currentState then
		return
	end

	local slots = currentState.Slots or {}
	local sinName = slots[selectedSlot] or ""
	local definition = getDefinition(sinName)

	if sinName == "" then
		currentSinLabel.Text = "None"
		currentSinLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
		currentDescription.Text = "Roll a Sin to fill this slot."
		return
	end

	currentSinLabel.Text = sinName

	if definition then
		currentSinLabel.TextColor3 = definition.Color or Color3.fromRGB(255, 255, 255)
		currentDescription.Text = definition.Description or ""
	else
		currentSinLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		currentDescription.Text = ""
	end
end

local function clearChildren(frame)
	for _, child in ipairs(frame:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

local function refreshSlots()
	if not currentState or not slotsFrame then
		return
	end

	clearChildren(slotsFrame)

	local slots = currentState.Slots or {}

	for index = 1, 3 do
		local sinName = slots[index] or ""
		local definition = getDefinition(sinName)
		local color = definition and definition.Color or Color3.fromRGB(255, 255, 255)

		local button = createButton(
			slotsFrame,
			"Slot" .. index,
			"Slot " .. index .. "\n" .. (sinName ~= "" and sinName or "Empty"),
			UDim2.fromOffset(210, 72),
			UDim2.fromOffset((index - 1) * 225, 0)
		)

		button.TextColor3 = color
		button.TextSize = 24

		if selectedSlot == index then
			button.BackgroundColor3 = Color3.fromRGB(35, 20, 45)
		end

		button.Activated:Connect(function()
			selectedSlot = index
			refreshSlots()
			refreshCurrentSin()
		end)
	end
end

local function refreshChances()
	if not currentState or not chancesFrame then
		return
	end

	clearChildren(chancesFrame)

	local order = currentState.RollOrder or {}
	local definitions = currentState.Definitions or {}

	local totalWeight = 0
	for _, sinName in ipairs(order) do
		local definition = definitions[sinName]
		if definition then
			totalWeight += definition.Weight or 0
		end
	end

	local x = 0

	for _, sinName in ipairs(order) do
		local definition = definitions[sinName]

		if definition then
			local chance = 0

			if totalWeight > 0 then
				chance = math.floor(((definition.Weight or 0) / totalWeight) * 100 + 0.5)
			end

			local box = Instance.new("Frame")
			box.Name = sinName
			box.Size = UDim2.fromOffset(118, 58)
			box.Position = UDim2.fromOffset(x, 0)
			box.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
			box.BackgroundTransparency = 0.08
			box.BorderSizePixel = 0
			box.Parent = chancesFrame

			makeStroke(box, definition.Color or Color3.fromRGB(255, 255, 255), 1, 0.2)

			createText(
				box,
				"Name",
				sinName,
				UDim2.new(1, -8, 0, 26),
				UDim2.fromOffset(4, 4),
				17,
				definition.Color or Color3.fromRGB(255, 255, 255),
				Enum.Font.GothamBlack
			)

			createText(
				box,
				"Chance",
				tostring(chance) .. "%",
				UDim2.new(1, -8, 0, 28),
				UDim2.fromOffset(4, 28),
				22,
				Color3.fromRGB(255, 255, 255),
				Enum.Font.GothamBlack
			)

			x += 124
		end
	end
end

local function refresh()
	if not currentState then
		return
	end

	shardsLabel.Text = "Shards : " .. tostring(currentState.Shards or 0)
	rollButton.Text = "Roll - " .. tostring(currentState.RollCost or 1) .. " Shard"

	refreshCurrentSin()
	refreshSlots()
	refreshChances()
end

local function requestState()
	local success, result = pcall(function()
		return getSinStateRemote:InvokeServer()
	end)

	if success and result then
		currentState = result
		refresh()
	else
		warn("[SinMenuController] Failed to get state:", result)
	end
end

local function roll()
	local success, result = pcall(function()
		return rollSinRemote:InvokeServer(selectedSlot)
	end)

	if not success then
		warn("[SinMenuController] Roll failed:", result)
		return
	end

	if result and result.State then
		currentState = result.State
		refresh()
	end
end

local function openMenu()
	if not gui then
		return
	end

	requestState()

	gui.Enabled = true
	setMenuOpen(true)

	mainFrame.Position = UDim2.new(0.5, 0, 0.55, 0)

	TweenService:Create(
		mainFrame,
		TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, 0, 0.5, 0) }
	):Play()
end

local function closeMenu()
	if not gui or not mainFrame then
		return
	end

	local tween = TweenService:Create(
		mainFrame,
		TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Position = UDim2.new(0.5, 0, 0.57, 0) }
	)

	tween:Play()

	task.delay(0.18, function()
		if gui then
			gui.Enabled = false
		end

		setMenuOpen(false)
	end)
end

local function toggleMenu()
	if gui and gui.Enabled then
		closeMenu()
	else
		openMenu()
	end
end

local function createGui()
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	local old = playerGui:FindFirstChild("SinMenuGui")
	if old then
		old:Destroy()
	end

	gui = Instance.new("ScreenGui")
	gui.Name = "SinMenuGui"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 600
	gui.Enabled = false
	gui.Parent = playerGui

	mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.Size = UDim2.fromScale(0.84, 0.76)

    local sizeConstraint = Instance.new("UISizeConstraint")
    sizeConstraint.MaxSize = Vector2.new(1000, 650)
    sizeConstraint.MinSize = Vector2.new(620, 390)
    sizeConstraint.Parent = mainFrame
	mainFrame.BackgroundColor3 = Color3.fromRGB(9, 5, 12)
	mainFrame.BackgroundTransparency = 0.12
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = gui

	makeStroke(mainFrame, Color3.fromRGB(255, 255, 255), 2, 0.1)

	local title = createText(
		mainFrame,
		"Title",
		"SINS",
		UDim2.fromOffset(420, 80),
		UDim2.new(0.5, -210, 0, -72),
		56,
		Color3.fromRGB(255, 105, 255),
		Enum.Font.GothamBlack
	)
	title.TextStrokeTransparency = 0
	title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

	local exitButton = createButton(
		mainFrame,
		"Exit",
		"Exit",
		UDim2.fromOffset(200, 50),
		UDim2.new(1, -220, 0, -60)
	)
	exitButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	exitButton.TextColor3 = Color3.fromRGB(0, 0, 0)
	exitButton.Activated:Connect(closeMenu)

	local currentPanel = Instance.new("Frame")
	currentPanel.Name = "CurrentPanel"
	currentPanel.Position = UDim2.fromOffset(40, 25)
	currentPanel.Size = UDim2.fromOffset(650, 380)
	currentPanel.BackgroundColor3 = Color3.fromRGB(10, 6, 14)
	currentPanel.BackgroundTransparency = 0.25
	currentPanel.BorderSizePixel = 0
	currentPanel.Parent = mainFrame

	makeStroke(currentPanel, Color3.fromRGB(255, 255, 255), 1, 0.18)

	createText(
		currentPanel,
		"CurrentTitle",
		"Current Sin",
		UDim2.new(1, 0, 0, 40),
		UDim2.fromOffset(0, 10),
		26,
		Color3.fromRGB(255, 255, 255),
		Enum.Font.Gotham
	)

	currentSinLabel = createText(
		currentPanel,
		"CurrentSin",
		"None",
		UDim2.new(1, 0, 0, 80),
		UDim2.fromOffset(0, 135),
		58,
		Color3.fromRGB(255, 255, 255),
		Enum.Font.GothamBlack
	)

	currentSinLabel.TextStrokeTransparency = 0.2

	currentDescription = createText(
		currentPanel,
		"Description",
		"",
		UDim2.new(1, -80, 0, 70),
		UDim2.fromOffset(40, 220),
		18,
		Color3.fromRGB(230, 230, 240),
		Enum.Font.GothamMedium
	)

	rollButton = createButton(
		currentPanel,
		"RollButton",
		"Roll - 1 Shard",
		UDim2.fromOffset(270, 72),
		UDim2.new(0.5, -135, 1, -95)
	)

	rollButton.Activated:Connect(roll)

	local shardsPanel = Instance.new("Frame")
	shardsPanel.Name = "ShardsPanel"
	shardsPanel.Position = UDim2.fromOffset(710, 25)
	shardsPanel.Size = UDim2.fromOffset(250, 380)
	shardsPanel.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
	shardsPanel.BackgroundTransparency = 0.1
	shardsPanel.BorderSizePixel = 0
	shardsPanel.Parent = mainFrame

	makeStroke(shardsPanel, Color3.fromRGB(255, 255, 255), 2, 0.05)

	createText(
		shardsPanel,
		"Title",
		"Shards",
		UDim2.new(1, 0, 0, 45),
		UDim2.fromOffset(0, 10),
		28,
		Color3.fromRGB(255, 255, 255),
		Enum.Font.GothamBlack
	)

	shardsLabel = createText(
		shardsPanel,
		"ShardsText",
		"Shards : 0",
		UDim2.new(1, -20, 0, 50),
		UDim2.fromOffset(10, 100),
		24,
		Color3.fromRGB(100, 255, 80),
		Enum.Font.GothamBlack
	)

	createText(
		shardsPanel,
		"Info",
		"+1 shard every 5 floors",
		UDim2.new(1, -20, 0, 90),
		UDim2.fromOffset(10, 250),
		20,
		Color3.fromRGB(220, 220, 230),
		Enum.Font.GothamBold
	)

	chancesFrame = Instance.new("Frame")
	chancesFrame.Name = "ChancesFrame"
	chancesFrame.Position = UDim2.fromOffset(40, 470)
	chancesFrame.Size = UDim2.fromOffset(880, 58)
	chancesFrame.BackgroundColor3 = Color3.fromRGB(8, 5, 12)
	chancesFrame.BackgroundTransparency = 0.05
	chancesFrame.BorderSizePixel = 0
	chancesFrame.Parent = mainFrame

	makeStroke(chancesFrame, Color3.fromRGB(255, 255, 255), 2, 0.05)

	slotsFrame = Instance.new("Frame")
	slotsFrame.Name = "SlotsFrame"
	slotsFrame.Position = UDim2.fromOffset(220, 555)
	slotsFrame.Size = UDim2.fromOffset(670, 75)
	slotsFrame.BackgroundTransparency = 1
	slotsFrame.Parent = mainFrame
end

function SinMenuController:Open()
	openMenu()
end

function SinMenuController:Close()
	closeMenu()
end

function SinMenuController:Toggle()
	toggleMenu()
end

function SinMenuController:Start()
	getRemotes()
	createGui()

	openSinMenuRemote.OnClientEvent:Connect(openMenu)

	sinStateChangedRemote.OnClientEvent:Connect(function(state)
		currentState = state
		refresh()
	end)

	local playerGui = localPlayer:WaitForChild("PlayerGui")

	playerGui:GetAttributeChangedSignal("SinsMenuSignal"):Connect(function()
		toggleMenu()
	end)

	requestState()
end

return SinMenuController