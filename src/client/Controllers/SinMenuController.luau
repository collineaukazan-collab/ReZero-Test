local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local SinMenuController = {}

local localPlayer = Players.LocalPlayer

local gui = nil
local mainFrame = nil

local currentSinLabel = nil
local currentDescription = nil
local slotDescriptionLabel = nil
local shardsLabel = nil
local rollButton = nil
local rouletteLabel = nil

local slotsFrame = nil
local chancesScroller = nil
local chancesContent = nil

local hoverFrame = nil
local hoverTitle = nil
local hoverDescription = nil

local selectedSlot = 1
local rolling = false

local getSinStateRemote = nil
local rollSinRemote = nil
local openSinMenuRemote = nil
local sinStateChangedRemote = nil

local currentState = nil

local THEME_BG = Color3.fromRGB(8, 8, 12)
local THEME_PANEL = Color3.fromRGB(12, 9, 16)
local THEME_WHITE = Color3.fromRGB(255, 255, 255)
local THEME_PINK = Color3.fromRGB(255, 105, 255)
local THEME_DIM = Color3.fromRGB(210, 210, 225)
local THEME_GREEN = Color3.fromRGB(100, 255, 80)

local FALLBACK_DESCRIPTIONS = {
	Pride = "Run speed increases by 10%.",
	Lust = "Gives 3% run speed to you and nearby players within 40 studs.",
	Greed = "Gain 20% more Auracoins.",
	Sloth = "Walk speed and run speed increase, but max stamina decreases.",
	Gluttony = "If a player dies after your push, your stamina goes to 100% and insanity goes to 0%.",
	Wrath = "Insanity gain is reduced by 25%.",
	Envy = "On death, gain your Auracoins, then return 60 seconds before your death.",
}

local function getRemotes()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")

	getSinStateRemote = remotes:WaitForChild("GetSinState")
	rollSinRemote = remotes:WaitForChild("RollSin")
	openSinMenuRemote = remotes:WaitForChild("OpenSinMenu")
	sinStateChangedRemote = remotes:WaitForChild("SinStateChanged")
end

local function setCorePlayerList(enabled)
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, enabled)
	end)
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
	label.TextColor3 = color or THEME_WHITE
	label.TextSize = textSize or 18
	label.Font = font or Enum.Font.GothamBold
	label.TextWrapped = true
	label.TextScaled = false
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = parent

	return label
end

local function createButton(parent, name, text, size, position)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = THEME_BG
	button.BackgroundTransparency = 0.06
	button.BorderSizePixel = 0
	button.Text = text
	button.Font = Enum.Font.GothamBlack
	button.TextSize = 20
	button.TextColor3 = THEME_WHITE
	button.AutoButtonColor = true
	button.Parent = parent

	makeStroke(button, THEME_WHITE, 2, 0.15)

	return button
end

local function setMenuOpen(value)
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	playerGui:SetAttribute("MenuOpen", value == true)
	setCorePlayerList(false)
end

local function getDefinition(sinName)
	if not currentState or not currentState.Definitions then
		return nil
	end

	return currentState.Definitions[sinName]
end

local function getDisplayName(sinName)
	local definition = getDefinition(sinName)

	if definition and definition.DisplayName then
		return definition.DisplayName
	end

	return sinName
end

local function getSinColor(sinName)
	local definition = getDefinition(sinName)

	if definition and definition.Color then
		return definition.Color
	end

	return THEME_WHITE
end

local function getSinDescription(sinName)
	local definition = getDefinition(sinName)

	if definition and definition.Description and definition.Description ~= "" then
		return definition.Description
	end

	return FALLBACK_DESCRIPTIONS[sinName] or "No description."
end

local function clearChildren(frame)
	for _, child in ipairs(frame:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

local function refreshCurrentSin()
	if not currentState or not currentSinLabel or not currentDescription then
		return
	end

	if rolling then
		return
	end

	local slots = currentState.Slots or {}
	local sinName = slots[selectedSlot] or ""

	if sinName == "" then
		currentSinLabel.Text = "None"
		currentSinLabel.TextColor3 = Color3.fromRGB(190, 190, 205)
		currentDescription.Text = "Roll a Sin to fill this slot."

		if slotDescriptionLabel then
			slotDescriptionLabel.Text = "Selected Slot " .. tostring(selectedSlot) .. " : Empty"
		end

		return
	end

	currentSinLabel.Text = getDisplayName(sinName)
	currentSinLabel.TextColor3 = getSinColor(sinName)

	local description = getSinDescription(sinName)
	currentDescription.Text = description

	if slotDescriptionLabel then
		slotDescriptionLabel.Text = "Slot " .. tostring(selectedSlot) .. " - " .. getDisplayName(sinName) .. " : " .. description
		slotDescriptionLabel.TextColor3 = THEME_DIM
	end
end

local function refreshSlots()
	if not currentState or not slotsFrame then
		return
	end

	clearChildren(slotsFrame)

	local layout = slotsFrame:FindFirstChildOfClass("UIListLayout")

	if not layout then
		layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.Padding = UDim.new(0, 10)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = slotsFrame
	end

	local slots = currentState.Slots or {}

	for index = 1, 3 do
		local sinName = slots[index] or ""
		local color = sinName ~= "" and getSinColor(sinName) or THEME_WHITE

		local button = createButton(
			slotsFrame,
			"Slot" .. index,
			"Slot " .. index .. "\n" .. (sinName ~= "" and getDisplayName(sinName) or "Empty"),
			UDim2.new(0.31, 0, 0.82, 0),
			UDim2.fromOffset(0, 0)
		)

		button.LayoutOrder = index
		button.TextColor3 = color
		button.TextSize = 20
		button.Font = Enum.Font.Gotham

		if selectedSlot == index then
			button.BackgroundColor3 = Color3.fromRGB(35, 20, 45)
		end

		button.MouseEnter:Connect(function()
			if sinName ~= "" and slotDescriptionLabel then
				slotDescriptionLabel.Text = "Slot " .. tostring(index) .. " - " .. getDisplayName(sinName) .. " : " .. getSinDescription(sinName)
			end
		end)

		button.MouseLeave:Connect(function()
			refreshCurrentSin()
		end)

		button.Activated:Connect(function()
			if rolling then
				return
			end

			selectedSlot = index
			refreshSlots()
			refreshCurrentSin()
		end)
	end
end

local function showHoverForSin(sinName, box)
	if not hoverFrame then
		return
	end

	local definition = getDefinition(sinName)

	if not definition then
		return
	end

	hoverTitle.Text = getDisplayName(sinName) .. " - " .. tostring(definition.Weight or 0) .. "%"
	hoverTitle.TextColor3 = getSinColor(sinName)
	hoverDescription.Text = getSinDescription(sinName)

	hoverFrame.Visible = true

	local absolutePosition = box.AbsolutePosition
	local mainAbsolutePosition = mainFrame.AbsolutePosition

	local x = absolutePosition.X - mainAbsolutePosition.X
	local y = absolutePosition.Y - mainAbsolutePosition.Y

	hoverFrame.Position = UDim2.fromOffset(
		math.clamp(x, 10, mainFrame.AbsoluteSize.X - 310),
		math.clamp(y - 118, 64, mainFrame.AbsoluteSize.Y - 125)
	)
end

local function hideHover()
	if hoverFrame then
		hoverFrame.Visible = false
	end
end

local function refreshChances()
	if not currentState or not chancesContent then
		return
	end

	clearChildren(chancesContent)

	local layout = chancesContent:FindFirstChildOfClass("UIListLayout")

	if not layout then
		layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.Padding = UDim.new(0, 8)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = chancesContent
	end

	local order = currentState.RollOrder or {}
	local definitions = currentState.Definitions or {}

	for i, sinName in ipairs(order) do
		local definition = definitions[sinName]

		if definition then
			local chance = definition.Weight or 0

			local box = Instance.new("Frame")
			box.Name = sinName
			box.LayoutOrder = i
			box.Active = true
			box.Size = UDim2.fromOffset(118, 56)
			box.BackgroundColor3 = THEME_BG
			box.BackgroundTransparency = 0.03
			box.BorderSizePixel = 0
			box.Parent = chancesContent

			local stroke = makeStroke(box, getSinColor(sinName), 1, 0.05)

			createText(
				box,
				"Name",
				getDisplayName(sinName),
				UDim2.new(1, -8, 0, 25),
				UDim2.fromOffset(4, 3),
				16,
				getSinColor(sinName),
				Enum.Font.GothamBlack
			)

			createText(
				box,
				"Chance",
				tostring(chance) .. "%",
				UDim2.new(1, -8, 0, 26),
				UDim2.fromOffset(4, 27),
				20,
				THEME_WHITE,
				Enum.Font.GothamBlack
			)

			box.MouseEnter:Connect(function()
				stroke.Thickness = 2
				box.BackgroundColor3 = Color3.fromRGB(25, 18, 30)
				showHoverForSin(sinName, box)
			end)

			box.MouseLeave:Connect(function()
				stroke.Thickness = 1
				box.BackgroundColor3 = THEME_BG
				hideHover()
			end)
		end
	end

	task.defer(function()
		if chancesScroller and chancesContent and layout then
			chancesScroller.CanvasSize = UDim2.fromOffset(layout.AbsoluteContentSize.X + 16, 0)
		end
	end)
end

local function refresh()
	if not currentState then
		return
	end

	if shardsLabel then
		shardsLabel.Text = "Shards : " .. tostring(currentState.Shards or 0)
	end

	if rollButton then
		rollButton.Text = rolling and "Rolling..." or "Roll - " .. tostring(currentState.RollCost or 1) .. " Shard"
	end

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

local function playRollAnimation(finalSin, finalState)
	if not currentState then
		return
	end

	local order = currentState.RollOrder or {}

	if #order == 0 then
		return
	end

	rolling = true

	if rollButton then
		rollButton.Active = false
		rollButton.AutoButtonColor = false
		rollButton.Text = "Rolling..."
	end

	if rouletteLabel then
		rouletteLabel.Visible = true
	end

	currentSinLabel.Text = "???"
	currentSinLabel.TextColor3 = THEME_WHITE
	currentDescription.Text = "Rolling..."
	slotDescriptionLabel.Text = "The Sin will be revealed at the end."

	local spins = 34
	local delayTime = 0.028

	for i = 1, spins do
		local index = ((i - 1) % #order) + 1
		local sinName = order[index]

		if rouletteLabel then
			rouletteLabel.Text = getDisplayName(sinName)
			rouletteLabel.TextColor3 = getSinColor(sinName)
		end

		task.wait(delayTime)
		delayTime += 0.004
	end

	if rouletteLabel then
		rouletteLabel.Text = "..."
		rouletteLabel.TextColor3 = THEME_WHITE
	end

	task.wait(0.25)

	currentState = finalState or currentState
	rolling = false

	if rouletteLabel then
		rouletteLabel.Visible = false
	end

	if rollButton then
		rollButton.Active = true
		rollButton.AutoButtonColor = true
	end

	refresh()

	currentSinLabel.Text = getDisplayName(finalSin)
	currentSinLabel.TextColor3 = getSinColor(finalSin)
	currentDescription.Text = getSinDescription(finalSin)

	TweenService:Create(
		currentSinLabel,
		TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ TextSize = 58 }
	):Play()

	task.wait(0.18)

	TweenService:Create(
		currentSinLabel,
		TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ TextSize = 46 }
	):Play()
end

local function roll()
	if rolling then
		return
	end

	local success, result = pcall(function()
		return rollSinRemote:InvokeServer(selectedSlot)
	end)

	if not success then
		warn("[SinMenuController] Roll failed:", result)
		return
	end

	if not result then
		return
	end

	if result.Success == false then
		if rollButton then
			rollButton.Text = result.Message or "Not enough shards"

			task.delay(1, function()
				if rollButton then
					refresh()
				end
			end)
		end

		return
	end

	local finalSin = result.RolledSin

	if finalSin then
		playRollAnimation(finalSin, result.State)
	elseif result.State then
		currentState = result.State
		refresh()
	end
end

local function openMenu()
	if not gui or not mainFrame then
		return
	end

	requestState()

	gui.Enabled = true
	setMenuOpen(true)

	mainFrame.Position = UDim2.new(0.5, 0, 0.54, 0)
	mainFrame.BackgroundTransparency = 0.22

	TweenService:Create(
		mainFrame,
		TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundTransparency = 0.08,
		}
	):Play()
end

local function closeMenu()
	if not gui or not mainFrame then
		return
	end

	if rolling then
		return
	end

	local tween = TweenService:Create(
		mainFrame,
		TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{
			Position = UDim2.new(0.5, 0, 0.57, 0),
			BackgroundTransparency = 0.25,
		}
	)

	tween:Play()

	task.delay(0.18, function()
		if gui then
			gui.Enabled = false
		end

		hideHover()
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

local function createHoverGui()
	hoverFrame = Instance.new("Frame")
	hoverFrame.Name = "HoverDescription"
	hoverFrame.Size = UDim2.fromOffset(300, 110)
	hoverFrame.Position = UDim2.fromOffset(20, 20)
	hoverFrame.BackgroundColor3 = Color3.fromRGB(5, 5, 8)
	hoverFrame.BackgroundTransparency = 0.02
	hoverFrame.BorderSizePixel = 0
	hoverFrame.Visible = false
	hoverFrame.ZIndex = 20
	hoverFrame.Parent = mainFrame

	makeStroke(hoverFrame, THEME_WHITE, 1, 0.15)

	hoverTitle = createText(
		hoverFrame,
		"Title",
		"",
		UDim2.new(1, -16, 0, 30),
		UDim2.fromOffset(8, 6),
		18,
		THEME_WHITE,
		Enum.Font.GothamBlack
	)
	hoverTitle.ZIndex = 21

	hoverDescription = createText(
		hoverFrame,
		"Description",
		"",
		UDim2.new(1, -18, 1, -42),
		UDim2.fromOffset(9, 36),
		14,
		THEME_DIM,
		Enum.Font.GothamMedium
	)
	hoverDescription.ZIndex = 21
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
	gui.DisplayOrder = 900
	gui.Enabled = false
	gui.Parent = playerGui

	mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.Size = UDim2.fromScale(0.88, 0.82)
	mainFrame.BackgroundColor3 = THEME_BG
	mainFrame.BackgroundTransparency = 0.08
	mainFrame.BorderSizePixel = 0
	mainFrame.ClipsDescendants = true
	mainFrame.Parent = gui

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MaxSize = Vector2.new(1080, 650)
	sizeConstraint.MinSize = Vector2.new(620, 390)
	sizeConstraint.Parent = mainFrame

	makeStroke(mainFrame, THEME_WHITE, 2, 0.08)

	local title = createText(
		mainFrame,
		"Title",
		"SINS",
		UDim2.new(0, 260, 0, 54),
		UDim2.new(0.5, -130, 0, 4),
		42,
		THEME_PINK,
		Enum.Font.GothamBlack
	)

	title.TextStrokeTransparency = 0
	title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

	local exitButton = createButton(
		mainFrame,
		"Exit",
		"Exit",
		UDim2.new(0, 150, 0, 42),
		UDim2.new(1, -168, 0, 10)
	)

	exitButton.BackgroundColor3 = THEME_WHITE
	exitButton.TextColor3 = Color3.fromRGB(0, 0, 0)
	exitButton.Activated:Connect(closeMenu)

	local currentPanel = Instance.new("Frame")
	currentPanel.Name = "CurrentPanel"
	currentPanel.Position = UDim2.new(0.04, 0, 0.13, 0)
	currentPanel.Size = UDim2.new(0.66, 0, 0.49, 0)
	currentPanel.BackgroundColor3 = THEME_PANEL
	currentPanel.BackgroundTransparency = 0.18
	currentPanel.BorderSizePixel = 0
	currentPanel.Parent = mainFrame

	makeStroke(currentPanel, THEME_WHITE, 1, 0.15)

	createText(
		currentPanel,
		"CurrentTitle",
		"Current Sin",
		UDim2.new(1, 0, 0, 36),
		UDim2.fromOffset(0, 8),
		24,
		THEME_WHITE,
		Enum.Font.Gotham
	)

	currentSinLabel = createText(
		currentPanel,
		"CurrentSin",
		"None",
		UDim2.new(1, -20, 0, 70),
		UDim2.new(0, 10, 0.30, -35),
		46,
		THEME_WHITE,
		Enum.Font.GothamBlack
	)

	currentSinLabel.TextStrokeTransparency = 0.25

	rouletteLabel = createText(
		currentPanel,
		"RouletteLabel",
		"",
		UDim2.new(1, -20, 0, 38),
		UDim2.new(0, 10, 0.49, -20),
		26,
		THEME_WHITE,
		Enum.Font.GothamBlack
	)
	rouletteLabel.Visible = false

	currentDescription = createText(
		currentPanel,
		"Description",
		"",
		UDim2.new(1, -60, 0, 58),
		UDim2.new(0, 30, 0.58, 0),
		16,
		THEME_DIM,
		Enum.Font.GothamMedium
	)

	rollButton = createButton(
		currentPanel,
		"RollButton",
		"Roll - 1 Shard",
		UDim2.new(0, 250, 0, 54),
		UDim2.new(0.5, -125, 1, -64)
	)

	rollButton.Activated:Connect(roll)

	local shardsPanel = Instance.new("Frame")
	shardsPanel.Name = "ShardsPanel"
	shardsPanel.Position = UDim2.new(0.73, 0, 0.13, 0)
	shardsPanel.Size = UDim2.new(0.23, 0, 0.49, 0)
	shardsPanel.BackgroundColor3 = THEME_BG
	shardsPanel.BackgroundTransparency = 0.06
	shardsPanel.BorderSizePixel = 0
	shardsPanel.Parent = mainFrame

	makeStroke(shardsPanel, THEME_WHITE, 2, 0.05)

	createText(
		shardsPanel,
		"Title",
		"Shards",
		UDim2.new(1, 0, 0, 42),
		UDim2.fromOffset(0, 10),
		25,
		THEME_WHITE,
		Enum.Font.GothamBlack
	)

	shardsLabel = createText(
		shardsPanel,
		"ShardsText",
		"Shards : 0",
		UDim2.new(1, -16, 0, 50),
		UDim2.new(0, 8, 0.42, -25),
		21,
		THEME_GREEN,
		Enum.Font.GothamBlack
	)

	createText(
		shardsPanel,
		"Info",
		"+1 shard every 5 floors",
		UDim2.new(1, -16, 0, 70),
		UDim2.new(0, 8, 1, -86),
		16,
		THEME_DIM,
		Enum.Font.GothamBold
	)

	slotDescriptionLabel = createText(
		mainFrame,
		"SlotDescription",
		"Selected Slot : Empty",
		UDim2.new(0.92, 0, 0.06, 0),
		UDim2.new(0.04, 0, 0.64, 0),
		15,
		THEME_DIM,
		Enum.Font.GothamMedium
	)

	chancesScroller = Instance.new("ScrollingFrame")
	chancesScroller.Name = "ChancesScroller"
	chancesScroller.Position = UDim2.new(0.04, 0, 0.72, 0)
	chancesScroller.Size = UDim2.new(0.92, 0, 0.105, 0)
	chancesScroller.BackgroundColor3 = THEME_BG
	chancesScroller.BackgroundTransparency = 0.04
	chancesScroller.BorderSizePixel = 0
	chancesScroller.ScrollBarThickness = 4
	chancesScroller.ScrollingDirection = Enum.ScrollingDirection.X
	chancesScroller.CanvasSize = UDim2.fromOffset(0, 0)
	chancesScroller.Parent = mainFrame

	makeStroke(chancesScroller, THEME_WHITE, 2, 0.08)

	chancesContent = Instance.new("Frame")
	chancesContent.Name = "Content"
	chancesContent.Size = UDim2.new(1, 0, 1, 0)
	chancesContent.BackgroundTransparency = 1
	chancesContent.Parent = chancesScroller

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = chancesContent

	slotsFrame = Instance.new("Frame")
	slotsFrame.Name = "SlotsFrame"
	slotsFrame.Position = UDim2.new(0.04, 0, 0.85, 0)
	slotsFrame.Size = UDim2.new(0.92, 0, 0.11, 0)
	slotsFrame.BackgroundTransparency = 1
	slotsFrame.Parent = mainFrame

	createHoverGui()
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
		if rolling then
			return
		end

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