local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local StairRenderController = {}

local localPlayer = Players.LocalPlayer

local renderFolder = nil
local renderedSegments = {}
local graphicsController = nil

local FALLBACK_STEPS_PER_SEGMENT = 180
local FALLBACK_RADIUS = 24
local FALLBACK_STEP_HEIGHT = GameConfig.StairSegmentHeight / FALLBACK_STEPS_PER_SEGMENT

local function getCharacterRoot()
	local character = localPlayer.Character
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function getTemplate()
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if not assets then
		return nil
	end

	return assets:FindFirstChild("StairSegment")
end

local function anchorParts(instance)
	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = true
		end
	end
end

local function createFallbackSegment(index)
	local model = Instance.new("Model")
	model.Name = "FallbackStairSegment_" .. tostring(index)

	local baseY = index * GameConfig.StairSegmentHeight

	for stepIndex = 1, FALLBACK_STEPS_PER_SEGMENT do
		local progress = (stepIndex - 1) / FALLBACK_STEPS_PER_SEGMENT
		local angle = progress * math.pi * 2

		local x = math.cos(angle) * FALLBACK_RADIUS
		local z = math.sin(angle) * FALLBACK_RADIUS
		local y = baseY + (stepIndex - 1) * FALLBACK_STEP_HEIGHT

		local step = Instance.new("Part")
		step.Name = "Step"
		step.Anchored = true
		step.CanCollide = true
		step.Size = Vector3.new(11, 0.7, 8)
		step.Material = Enum.Material.Slate
		step.Color = Color3.fromRGB(70, 70, 82)
		step.CFrame = CFrame.new(x, y, z) * CFrame.Angles(0, -angle, 0)
		step.Parent = model
	end

	model.Parent = renderFolder
	return model
end

local function createSegment(index)
	if renderedSegments[index] then
		return
	end

	local template = getTemplate()

	if template then
		local clone = template:Clone()
		clone.Name = "StairSegment_" .. tostring(index)
		anchorParts(clone)
		clone.Parent = renderFolder

		local targetCFrame = CFrame.new(0, index * GameConfig.StairSegmentHeight, 0)

		if clone:IsA("Model") then
			clone:PivotTo(targetCFrame)
		elseif clone:IsA("BasePart") then
			clone.CFrame = targetCFrame
		end

		renderedSegments[index] = clone
	else
		renderedSegments[index] = createFallbackSegment(index)
	end
end

local function removeSegment(index)
	local segment = renderedSegments[index]
	if segment then
		segment:Destroy()
		renderedSegments[index] = nil
	end
end

local function updateRenderedSegments()
	local root = getCharacterRoot()
	if not root then
		return
	end

	local currentStuds = math.max(0, root.Position.Y - GameConfig.SpawnPosition.Y)
	local currentSegmentIndex = math.max(0, math.floor(currentStuds / GameConfig.StairSegmentHeight))

	local aboveDistance = graphicsController:GetRenderDistanceAbove()
	local belowDistance = graphicsController:GetRenderDistanceBelow()

	local aboveRange = math.max(2, math.ceil(aboveDistance / GameConfig.StairSegmentHeight))
	local belowRange = math.max(1, math.ceil(belowDistance / GameConfig.StairSegmentHeight))

	local minIndex = math.max(0, currentSegmentIndex - belowRange)
	local maxIndex = currentSegmentIndex + aboveRange

	for index = minIndex, maxIndex do
		createSegment(index)
	end

	for index in pairs(renderedSegments) do
		if index < minIndex or index > maxIndex then
			removeSegment(index)
		end
	end
end

function StairRenderController:Start(controller)
	graphicsController = controller

	renderFolder = workspace:FindFirstChild("ClientRenderedStairs")
	if not renderFolder then
		renderFolder = Instance.new("Folder")
		renderFolder.Name = "ClientRenderedStairs"
		renderFolder.Parent = workspace
	end

	graphicsController.Changed:Connect(function()
		updateRenderedSegments()
	end)

	task.spawn(function()
		while true do
			updateRenderedSegments()
			task.wait(GameConfig.ClientRenderUpdateInterval)
		end
	end)
end

return StairRenderController