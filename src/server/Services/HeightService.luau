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

local function hasBodyTouchedBottom(character, root)
	if root.Position.Y <= GameConfig.FallDeathY then
		return true
	end

	if not character:GetAttribute("IsRagdolled") then
		return false
	end

	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name ~= "HumanoidRootPart" then
			if descendant.Position.Y <= GameConfig.GroundDeathY then
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
		while true do
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