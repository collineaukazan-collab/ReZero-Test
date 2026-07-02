local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local NumberUtil = require(ReplicatedStorage.Shared.Utils.NumberUtil)

local UIController = {}

local localPlayer = Players.LocalPlayer

local function createLabel(parent, name, order)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.LayoutOrder = order
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, 28)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 18
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.5
	label.Parent = parent

	return label
end

local function getLeaderstatValue(name)
	local leaderstats = localPlayer:FindFirstChild("leaderstats")
	if not leaderstats then
		return 0
	end

	local value = leaderstats:FindFirstChild(name)
	if not value then
		return 0
	end

	return value.Value
end

function UIController:Start(graphicsController)
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	local oldGui = playerGui:FindFirstChild("ReZeroHUD")
	if oldGui then
		oldGui:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ReZeroHUD"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "StatsFrame"
	frame.Size = UDim2.new(0, 260, 0, 170)
	frame.Position = UDim2.new(0, 18, 0, 18)
	frame.BackgroundTransparency = 0.25
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = frame

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 4)
	layout.Parent = frame

	local studsLabel = createLabel(frame, "StudsLabel", 1)
	local floorLabel = createLabel(frame, "FloorLabel", 2)
	local bestLabel = createLabel(frame, "BestLabel", 3)
	local moneyLabel = createLabel(frame, "MoneyLabel", 4)
	local rewardLabel = createLabel(frame, "RewardLabel", 5)

	local qualityButton = Instance.new("TextButton")
	qualityButton.Name = "QualityButton"
	qualityButton.Size = UDim2.new(0, 210, 0, 42)
	qualityButton.Position = UDim2.new(1, -230, 0, 18)
	qualityButton.BackgroundTransparency = 0.15
	qualityButton.BorderSizePixel = 0
	qualityButton.Font = Enum.Font.GothamBold
	qualityButton.TextSize = 18
	qualityButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	qualityButton.Parent = screenGui

	local function update()
		local currentStuds = math.floor(localPlayer:GetAttribute("CurrentStuds") or getLeaderstatValue("Studs"))
		local currentFloor = math.floor(localPlayer:GetAttribute("CurrentFloor") or (currentStuds / GameConfig.StairSegmentHeight))
		local bestStuds = math.floor(localPlayer:GetAttribute("BestStuds") or getLeaderstatValue("Best"))
		local money = math.floor(localPlayer:GetAttribute("Money") or getLeaderstatValue("Money"))
		local lastReward = math.floor(localPlayer:GetAttribute("LastReward") or 0)

		studsLabel.Text = "Studs: " .. NumberUtil.formatInteger(currentStuds)
		floorLabel.Text = "Floor: " .. NumberUtil.formatInteger(currentFloor)
		bestLabel.Text = "Best: " .. NumberUtil.formatInteger(bestStuds)
		moneyLabel.Text = "Money: " .. NumberUtil.formatInteger(money)
		rewardLabel.Text = "Last reward: +" .. NumberUtil.formatInteger(lastReward)

		qualityButton.Text = "Quality: " .. graphicsController:GetQuality()
	end

	qualityButton.Activated:Connect(function()
		graphicsController:CycleQuality()
		update()
	end)

	graphicsController.Changed:Connect(update)

	local attributesToWatch = {
		"CurrentStuds",
		"CurrentFloor",
		"BestStuds",
		"Money",
		"LastReward",
	}

	for _, attributeName in ipairs(attributesToWatch) do
		localPlayer:GetAttributeChangedSignal(attributeName):Connect(update)
	end

	localPlayer.ChildAdded:Connect(function(child)
		if child.Name == "leaderstats" then
			task.wait(0.1)
			update()
		end
	end)

	task.spawn(function()
		while true do
			update()
			task.wait(0.5)
		end
	end)

	update()
end

return UIController
