local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local GraphicsController = {}

GraphicsController.CurrentQuality = GameConfig.DefaultQuality
GraphicsController._changedEvent = Instance.new("BindableEvent")
GraphicsController.Changed = GraphicsController._changedEvent.Event

local function getRemotes()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	return remotes
end

function GraphicsController:GetQuality()
	return self.CurrentQuality
end

function GraphicsController:GetRenderDistance()
	local setting = GameConfig.QualitySettings[self.CurrentQuality]
	if not setting then
		return GameConfig.QualitySettings[GameConfig.DefaultQuality].RenderDistance
	end

	return setting.RenderDistance
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
