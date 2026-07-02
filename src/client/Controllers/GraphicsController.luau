local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local GraphicsController = {}

GraphicsController.CurrentQuality = GameConfig.DefaultQuality
GraphicsController._changedEvent = Instance.new("BindableEvent")
GraphicsController.Changed = GraphicsController._changedEvent.Event

local function getRemotes()
	return ReplicatedStorage:WaitForChild("Remotes")
end

function GraphicsController:GetQuality()
	return self.CurrentQuality
end

function GraphicsController:GetQualitySetting()
	local setting = GameConfig.QualitySettings[self.CurrentQuality]

	if not setting then
		setting = GameConfig.QualitySettings[GameConfig.DefaultQuality]
	end

	return setting
end

function GraphicsController:GetRenderDistanceAbove()
	local setting = self:GetQualitySetting()

	if setting.RenderDistanceAbove then
		return setting.RenderDistanceAbove
	end

	if setting.RenderDistance then
		return setting.RenderDistance
	end

	return 900
end

function GraphicsController:GetRenderDistanceBelow()
	local setting = self:GetQualitySetting()

	if setting.RenderDistanceBelow then
		return setting.RenderDistanceBelow
	end

	if setting.RenderDistance then
		return math.floor(setting.RenderDistance / 2)
	end

	return 360
end

function GraphicsController:SetQuality(quality, shouldSave)
	if not GameConfig.QualitySettings[quality] then
		return
	end

	if self.CurrentQuality == quality then
		return
	end

	self.CurrentQuality = quality
	self._changedEvent:Fire(quality)

	if shouldSave then
		local remotes = getRemotes()
		local setGraphicsQuality = remotes:WaitForChild("SetGraphicsQuality")
		setGraphicsQuality:FireServer(quality)
	end
end

function GraphicsController:CycleQuality()
	local currentIndex = 1

	for index, quality in ipairs(GameConfig.QualityOrder) do
		if quality == self.CurrentQuality then
			currentIndex = index
			break
		end
	end

	local nextIndex = currentIndex + 1

	if nextIndex > #GameConfig.QualityOrder then
		nextIndex = 1
	end

	self:SetQuality(GameConfig.QualityOrder[nextIndex], true)
end

function GraphicsController:Start()
	local success, data = pcall(function()
		local remotes = getRemotes()
		local getPlayerData = remotes:WaitForChild("GetPlayerData")
		return getPlayerData:InvokeServer()
	end)

	if success and type(data) == "table" and type(data.GraphicsQuality) == "string" then
		self:SetQuality(data.GraphicsQuality, false)
	end
end

return GraphicsController