local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local HeightService = {}

local ragdollService = nil

local function getHorizontalDistanceFromTower(root)
	local position = root.Position
	return Vector2.new(position.X, position.Z).Magnitude
end

local function isOutsideTower(root)
	if not GameConfig.KillWhenOutsideTowerRadius then
		return false
	end

	return getHorizontalDistanceFromTower(root) > GameConfig.TowerSafeRadius
end

local function shouldRagdoll(character, root, humanoid, currentStuds, runBestStuds)
	if character:GetAttribute("IsRagdolled") then
		return false
	end

	if currentStuds < GameConfig.MinimumStudsBeforeFallKill then
		return false
	end

	local velocityY = root.AssemblyLinearVelocity.Y
	local heightLoss = runBestStuds - currentStuds
	local state = humanoid:GetState()

	local isFallingState =
		state == Enum.HumanoidStateType.Freefall
		or state == Enum.HumanoidStateType.FallingDown
		or state == Enum.HumanoidStateType.Physics

	if isOutsideTower(root) and velocityY < -8 then
		return true
	end

	if isFallingState and velocityY <= GameConfig.FallingVelocityToRagdoll then
		return true
	end

	if velocityY <= GameConfig.FallingVelocityToRagdoll and heightLoss >= GameConfig.FallingHeightLossToRagdoll then
		return true
	end

	return false
end

local function isNearBottom(character, root)
	if root.Position.Y <= GameConfig.FallDeathY then
		return true
	end

	if character:GetAttribute("IsRagdolled") and root.Position.Y <= GameConfig.GroundDeathY then
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
						if ragdollService then
							ragdollService:RagdollPlayer(player)
						end
					end

					if isNearBottom(character, root) then
						humanoid.Health = 0
					end
				end
			end

			task.wait(GameConfig.HeightUpdateInterval)
		end
	end)
end

return HeightService