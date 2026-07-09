local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local WorldService = {}

local terrain = workspace.Terrain

local function getSandConfig()
	return GameConfig.TowerSandFloor or {}
end

local function smoothStep(edge0, edge1, value)
	local t = math.clamp((value - edge0) / math.max(edge1 - edge0, 0.001), 0, 1)
	return t * t * (3 - 2 * t)
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function getCenter()
	local config = getSandConfig()
	return config.Center or GameConfig.StairCenter or Vector3.zero
end

local function getSpawnXZ()
	local config = getSandConfig()
	local center = getCenter()
	local offset = config.SpawnOffset or GameConfig.SpawnOffsetFromStair or Vector3.new(-20, 0, -30)

	return Vector3.new(center.X + offset.X, 0, center.Z + offset.Z)
end

local function getSandHeight(x, z)
	local config = getSandConfig()
	local center = getCenter()

	local baseY = config.BaseY or 0
	local reliefHeight = config.ReliefHeight or 1.15

	local bigNoise = math.noise(
		x * (config.BigReliefScale or 0.035),
		z * (config.BigReliefScale or 0.035),
		12.34
	)

	local smallNoise = math.noise(
		x * (config.SmallReliefScale or 0.09),
		z * (config.SmallReliefScale or 0.09),
		56.78
	)

	local height = baseY
		+ bigNoise * reliefHeight
		+ smallNoise * reliefHeight * 0.32

	local currentXZ = Vector3.new(x, 0, z)

	do
		local stairXZ = Vector3.new(center.X, 0, center.Z)
		local distance = (currentXZ - stairXZ).Magnitude
		local radius = config.FlatStairRadius or 34

		if distance < radius then
			local influence = 1 - smoothStep(radius * 0.45, radius, distance)
			height = lerp(height, baseY, influence)
		end
	end

	do
		local spawnXZ = getSpawnXZ()
		local distance = (currentXZ - spawnXZ).Magnitude
		local radius = config.FlatSpawnRadius or 18

		if distance < radius then
			local influence = 1 - smoothStep(radius * 0.35, radius, distance)
			height = lerp(height, baseY, influence)
		end
	end

	return height
end

local function getGroundY(x, z, ignoreCharacter)
	local config = getSandConfig()
	local center = getCenter()

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true

	if ignoreCharacter then
		params.FilterDescendantsInstances = { ignoreCharacter }
	else
		params.FilterDescendantsInstances = {}
	end

	local origin = Vector3.new(x, (config.BaseY or 0) + 90, z)
	local direction = Vector3.new(0, -220, 0)

	local result = workspace:Raycast(origin, direction, params)

	if result then
		return result.Position.Y
	end

	return getSandHeight(x, z)
end

local function clearOldGeneratedObjects()
	local oldFolder = workspace:FindFirstChild("TowerSandFloor")

	if oldFolder then
		oldFolder:Destroy()
	end
end

local function removeBaseplate()
	local baseplate = workspace:FindFirstChild("Baseplate")

	if baseplate and baseplate:IsA("BasePart") then
		baseplate:Destroy()
	end
end

local function clearSandTerrainArea()
	local config = getSandConfig()

	if config.ClearOldSandArea == false then
		return
	end

	local center = getCenter()
	local size = config.Size or 170
	local baseY = config.BaseY or 0
	local bottomY = config.BottomY or -4

	terrain:FillBlock(
		CFrame.new(center.X, (bottomY + baseY) / 2, center.Z),
		Vector3.new(size + 24, 18, size + 24),
		Enum.Material.Air
	)
end

local function generateTowerSandFloor()
	local config = getSandConfig()

	if config.Enabled == false then
		return
	end

	clearOldGeneratedObjects()
	removeBaseplate()
	clearSandTerrainArea()

	local center = getCenter()
	local size = config.Size or 170
	local step = config.Step or 6
	local bottomY = config.BottomY or -4

	local halfSize = size / 2

	for x = -halfSize, halfSize, step do
		for z = -halfSize, halfSize, step do
			local worldX = center.X + x
			local worldZ = center.Z + z

			local topY = getSandHeight(worldX, worldZ)
			local height = math.max(1.5, topY - bottomY)

			terrain:FillBlock(
				CFrame.new(worldX, bottomY + height / 2, worldZ),
				Vector3.new(step + 0.5, height, step + 0.5),
				Enum.Material.Sand
			)
		end

		task.wait()
	end

	print("[WorldService] Tower sand floor generated.")
end

local function forceR6GroundSettings(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return
	end

	if humanoid.RigType == Enum.HumanoidRigType.R6 then
		humanoid.HipHeight = 0
	else
		humanoid.HipHeight = GameConfig.Character and GameConfig.Character.HipHeight or humanoid.HipHeight
	end

	humanoid.PlatformStand = false
	humanoid.AutoRotate = true
end

local function getRootYOffset(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not root then
		return 3
	end

	if humanoid.RigType == Enum.HumanoidRigType.R6 then
		return 3
	end

	return humanoid.HipHeight + root.Size.Y / 2 + 0.1
end

local function getSpawnPosition(character)
	local spawnXZ = getSpawnXZ()
	local groundY = getGroundY(spawnXZ.X, spawnXZ.Z, character)
	local yOffset = character and getRootYOffset(character) or 3

	return Vector3.new(spawnXZ.X, groundY + yOffset, spawnXZ.Z)
end

local function getOrCreateSpawnLocation()
	for _, instance in ipairs(workspace:GetDescendants()) do
		if instance:IsA("SpawnLocation") then
			return instance
		end
	end

	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "SpawnLocation"
	spawnLocation.Parent = workspace

	return spawnLocation
end

local function setupSpawnLocation()
	local spawnXZ = getSpawnXZ()
	local groundY = getGroundY(spawnXZ.X, spawnXZ.Z)
	local spawnLocation = getOrCreateSpawnLocation()

	spawnLocation.Anchored = true
	spawnLocation.CanCollide = false
	spawnLocation.CanTouch = false
	spawnLocation.CanQuery = false
	spawnLocation.Neutral = true
	spawnLocation.Duration = 0
	spawnLocation.Size = Vector3.new(8, 1, 8)
	spawnLocation.Transparency = 1
	spawnLocation.Position = Vector3.new(spawnXZ.X, groundY + 0.2, spawnXZ.Z)

	GameConfig.SpawnPosition = Vector3.new(spawnXZ.X, groundY + 3, spawnXZ.Z)

	print("[WorldService] Spawn positioned at:", GameConfig.SpawnPosition)
end

local function resetRunAttributes(player)
	player:SetAttribute("CurrentStuds", 0)
	player:SetAttribute("CurrentFloor", 0)
	player:SetAttribute("RunBestStuds", 0)

	player:SetAttribute("LastReward", 0)
	player:SetAttribute("LastRunStuds", 0)
	player:SetAttribute("LastRunFloor", 0)
	player:SetAttribute("LastRunMultiplier", 1)

	player:SetAttribute("Insanity", 0)
	player:SetAttribute("InsanityActive", false)
	player:SetAttribute("InsanityCollapsed", false)
	player:SetAttribute("IsResting", false)
end

local function teleportCharacterToSpawn(character)
	local root = character:WaitForChild("HumanoidRootPart", 10)

	if not root then
		return
	end

	task.wait(0.25)

	forceR6GroundSettings(character)

	local spawnPosition = getSpawnPosition(character)
	GameConfig.SpawnPosition = spawnPosition

	character:PivotTo(CFrame.new(spawnPosition))

	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero

	task.delay(0.15, function()
		if character.Parent and root.Parent then
			forceR6GroundSettings(character)
			root.AssemblyLinearVelocity = Vector3.zero
		end
	end)
end

function WorldService:Start()
	generateTowerSandFloor()
	setupSpawnLocation()

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			resetRunAttributes(player)
			teleportCharacterToSpawn(character)
		end)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			resetRunAttributes(player)
			teleportCharacterToSpawn(player.Character)
		end
	end
end

return WorldService