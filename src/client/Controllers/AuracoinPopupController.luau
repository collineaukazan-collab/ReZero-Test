local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local AuracoinPopupController = {}

local localPlayer = Players.LocalPlayer

local gui = nil
local lastMilestone = 0
local lastCurrency = nil
local started = false

local function getCurrencyName()
	return GameConfig.CurrencyName or "Auracoins"
end

local function getCurrencyColor()
	return GameConfig.CurrencyColor or Color3.fromRGB(255, 221, 65)
end

local function formatInteger(value)
	value = math.floor(tonumber(value) or 0)

	local text = tostring(value)
	local result = ""

	while #text > 3 do
		result = "," .. string.sub(text, -3) .. result
		text = string.sub(text, 1, #text - 3)
	end

	return text .. result
end

local function getCurrencyValue()
	return localPlayer:GetAttribute("Auracoins")
		or localPlayer:GetAttribute("Money")
		or 0
end

local function getGainPerTenStuds()
	local moneyPerStud = GameConfig.MoneyPerStud or 1

	local baseMultiplier = localPlayer:GetAttribute("MoneyMultiplier")
		or localPlayer:GetAttribute("AuracoinsMultiplier")
		or GameConfig.DefaultMoneyMultiplier
		or 1

	local sinMultiplier = localPlayer:GetAttribute("SinAuracoinsMultiplier") or 1

	return math.max(1, math.floor(10 * moneyPerStud * baseMultiplier * sinMultiplier))
end

local function createGui()
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	local old = playerGui:FindFirstChild("AuracoinPopupGui")
	if old then
		old:Destroy()
	end

	gui = Instance.new("ScreenGui")
	gui.Name = "AuracoinPopupGui"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 9000
	gui.Parent = playerGui
end

local function showPopup(amount)
	if not gui then
		return
	end

	amount = math.floor(tonumber(amount) or 0)

	if amount <= 0 then
		return
	end

	local x = 0.5 + math.random(-22, 22) / 100
	local y = 0.5 + math.random(-14, 14) / 100

	local label = Instance.new("TextLabel")
	label.Name = "GainPopup"
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(x, y)
	label.Size = UDim2.fromOffset(280, 46)
	label.BackgroundTransparency = 1
	label.Text = "+" .. formatInteger(amount) .. " " .. getCurrencyName()
	label.TextColor3 = getCurrencyColor()
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.TextStrokeTransparency = 0.1
	label.TextSize = 25
	label.Font = Enum.Font.GothamBlack
	label.Parent = gui

	TweenService:Create(
		label,
		TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Position = UDim2.fromScale(x + math.random(-4, 4) / 100, y - 0.08),
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		}
	):Play()

	task.delay(0.95, function()
		if label then
			label:Destroy()
		end
	end)
end

local function resetValues()
	local studs = math.floor(localPlayer:GetAttribute("CurrentStuds") or 0)

	lastMilestone = math.floor(studs / 10)
	lastCurrency = getCurrencyValue()
end

local function onStudsChanged()
	local studs = math.floor(localPlayer:GetAttribute("CurrentStuds") or 0)

	if studs < 10 then
		lastMilestone = 0
		return
	end

	local milestone = math.floor(studs / 10)

	if milestone > lastMilestone then
		local gainedMilestones = milestone - lastMilestone
		lastMilestone = milestone

		showPopup(getGainPerTenStuds() * gainedMilestones)
	elseif milestone < lastMilestone then
		lastMilestone = milestone
	end
end

local function onCurrencyChanged()
	local current = getCurrencyValue()

	if lastCurrency == nil then
		lastCurrency = current
		return
	end

	local delta = current - lastCurrency
	lastCurrency = current

	if delta > 0 then
		showPopup(delta)
	end
end

function AuracoinPopupController:Start()
	if started then
		return
	end

	started = true

	createGui()
	resetValues()

	localPlayer.CharacterAdded:Connect(function()
		task.wait(0.4)
		resetValues()
	end)

	localPlayer:GetAttributeChangedSignal("CurrentStuds"):Connect(onStudsChanged)
	localPlayer:GetAttributeChangedSignal("Auracoins"):Connect(onCurrencyChanged)
	localPlayer:GetAttributeChangedSignal("Money"):Connect(onCurrencyChanged)

	print("[AuracoinPopupController] Started.")
end

return AuracoinPopupController