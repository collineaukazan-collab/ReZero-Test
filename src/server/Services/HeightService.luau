local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local HeightService = {}

local ragdollService = nil

local function isAirborne(humanoid)
	return humanoid.FloorMaterial == Enum.Material.Air
end

local function shouldRagdoll(character, root, humanoid, currentStuds, runBestStuds)
	if character:GetAttribute("IsRagdolled") then
		return false
	end

	if currentStuds < GameConfig.MinimumStudsBeforeFallKill then
		return false
	end

	if not isAirborne(humanoid) then
		character:SetAttribute("AirborneStartedAt", 0)
		return false
	end

	local airborneStartedAt = character:GetAttribute("AirborneStartedAt") or 0

	if airborneStartedAt <= 0 then
		character:SetAttribute("AirborneStartedAt", os.clock())
		return false
	end

	local airTime = os.clock() - airborneStartedAt
	local fallDistance = runBestStuds - currentStuds
	local velocityY = root.AssemblyLinearVelocity.Y

	if airTime < GameConfig.RagdollMinAirTime then
		return false
	end

	if fallDistance < GameConfig.RagdollMinFallDistance then
		return false
	end

	if velocityY > GameConfig.FallingVelocityToRagdoll then
		return false
	end

	return true
end

local function getFastestDownwardSpeed(character, root)
	local fastest = math.max(0, -root.AssemblyLinearVelocity.Y)

	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name ~= "HumanoidRootPart" then
			local speed = math.max(0, -descendant.AssemblyLinearVelocity.Y)

			if speed > fastest then
				fastest = speed
			end
		end
	end

	return fastest
end

local function getDynamicGroundDeathY(character, root)
	local baseY = GameConfig.GroundDeathY or 7

	if not GameConfig.DynamicGroundDeathEnabled then
		return baseY
	end

	local speed = getFastestDownwardSpeed(character, root)
	local minSpeed = GameConfig.DynamicGroundDeathMinSpeed or 80
	local maxBonus = GameConfig.DynamicGroundDeathMaxBonus or 45
	local multiplier = GameConfig.DynamicGroundDeathSpeedMultiplier or 0.22

	local bonus = math.clamp((speed - minSpeed) * multiplier, 0, maxBonus)

	return baseY + bonus
end

local function hasBodyTouchedBottom(character, root)
	if root.Position.Y <= GameConfig.FallDeathY then
		return true
	end

	if not character:GetAttribute("IsRagdolled") then
		return false
	end

	local dynamicGroundDeathY = getDynamicGroundDeathY(character, root)

	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name ~= "HumanoidRootPart" then
			local bottomY = descendant.Position.Y - descendant.Size.Y / 2

			if bottomY <= dynamicGroundDeathY then
				return true
			end
		end
	end

	local startedAt = character:GetAttribute("RagdollStartedAt") or 0

	if startedAt > 0 and os.clock() - startedAt >= GameConfig.MaxRagdollFallTime then
		return true
	end

	return false
end

function HeightService:Start(playerDataService, injectedRagdollService)
	ragdollService = injectedRagdollService

	task.spawn(function()
		local lastTime = os.clock()

		while true do
			local now = os.clock()
			local deltaTime = now - lastTime
			lastTime = now

			for _, player in ipairs(Players:GetPlayers()) do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")

				if root and humanoid and humanoid.Health > 0 then
					local currentStuds = math.max(0, math.floor(root.Position.Y - GameConfig.SpawnPosition.Y))
					local currentFloor = math.max(0, math.floor(currentStuds / GameConfig.StairSegmentHeight))
					local runBestStuds = math.max(player:GetAttribute("RunBestStuds") or 0, currentStuds)

					player:SetAttribute("CurrentStuds", currentStuds)
					player:SetAttribute("CurrentFloor", currentFloor)
					player:SetAttribute("RunBestStuds", runBestStuds)

					playerDataService:SetBestStuds(player, runBestStuds)

					if shouldRagdoll(character, root, humanoid, currentStuds, runBestStuds) then
						ragdollService:RagdollPlayer(player)
					end

					if character:GetAttribute("IsRagdolled") then
						ragdollService:ApplyCenterPull(player)
						ragdollService:ApplyFallPhysics(player, deltaTime)
					end

					if hasBodyTouchedBottom(character, root) then
						ragdollService:PrepareImpactDeath(player)
						humanoid.Health = 0
					end
				end
			end

			task.wait(GameConfig.HeightUpdateInterval)
		end
	end)
end

return HeightService