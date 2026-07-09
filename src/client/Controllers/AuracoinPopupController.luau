local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local AuracoinPopupController = {}

local localPlayer = Players.LocalPlayer

local lastMilestone = nil
local started = false

local function getCurrencyName()
	return GameConfig.CurrencyName or "Auracoins"
end

local function getCurrencyColor()
	return GameConfig.CurrencyColor or Color3.fromRGB(255, 221, 65)
end

local function getGainPerTenStuds()
	local moneyPerStud = GameConfig.MoneyPerStud or 1

	local baseMultiplier = localPlayer:GetAttribute("MoneyMultiplier")
		or localPlayer:GetAttribute("AuracoinsMultiplier")
		or GameConfig.DefaultMoneyMultiplier
		or 1

	local sinMultiplier = localPlayer:GetAttribute("SinAuracoinsMultiplier") or 1

	return math.floor(10 * moneyPerStud * baseMultiplier * sinMultiplier)
end

local function getAdornee()
	local character = localPlayer.Character

	if not character then
		return nil
	end

	return character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
end

local function showPopup(amount)
	local adornee = getAdornee()

	if not adornee then
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "AuracoinGainPopup"
	billboard.Adornee = adornee
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(180, 44)
	billboard.StudsOffset = Vector3.new(2.3, 1.7, 0)
	billboard.Parent = adornee

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Text = "+" .. tostring(amount) .. " " .. getCurrencyName()
	label.TextColor3 = getCurrencyColor()
	label.TextStrokeTransparency = 0.2
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.TextSize = 20
	label.Font = Enum.Font.GothamBlack
	label.Parent = billboard

	TweenService:Create(
		billboard,
		TweenInfo.new(0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ StudsOffset = Vector3.new(2.3, 3.2, 0) }
	):Play()

	TweenService:Create(
		label,
		TweenInfo.new(0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		}
	):Play()

	task.delay(0.9, function()
		if billboard then
			billboard:Destroy()
		end
	end)
end

local function resetMilestone()
	local studs = math.floor(localPlayer:GetAttribute("CurrentStuds") or 0)
	lastMilestone = math.floor(studs / 10)
end

function AuracoinPopupController:Start()
	if started then
		return
	end

	started = true

	resetMilestone()

	localPlayer.CharacterAdded:Connect(function()
		task.wait(0.4)
		resetMilestone()
	end)

	localPlayer:GetAttributeChangedSignal("CurrentStuds"):Connect(function()
		local studs = math.floor(localPlayer:GetAttribute("CurrentStuds") or 0)

		if studs < 10 then
			lastMilestone = 0
			return
		end

		local milestone = math.floor(studs / 10)

		if lastMilestone == nil then
			lastMilestone = milestone
			return
		end

		if milestone > lastMilestone then
			local gainedMilestones = milestone - lastMilestone
			lastMilestone = milestone

			local amount = getGainPerTenStuds() * gainedMilestones

			if amount > 0 then
				showPopup(amount)
			end
		elseif milestone < lastMilestone then
			lastMilestone = milestone
		end
	end)

	print("[AuracoinPopupController] Started.")
end

return AuracoinPopupController