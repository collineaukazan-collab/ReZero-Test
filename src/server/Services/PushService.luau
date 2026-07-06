local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local PushService = {}

local lastPushAt = {}

local function getPushConfig()
	return GameConfig.Push or {}
end

local function getRemotesFolder()
	local folder = ReplicatedStorage:FindFirstChild("Remotes")

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end

	return folder
end

local function getOrCreateRemoteEvent(name)
	local folder = getRemotesFolder()
	local remote = folder:FindFirstChild(name)

	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
	end

	return remote
end

local function getRoot(player)
	local character = player.Character

	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(player)
	local character = player.Character

	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

local function findTargetInFront(player)
	local config = getPushConfig()
	local range = config.Range or 9
	local coneDot = config.ConeDot or 0.45

	local root = getRoot(player)

	if not root then
		return nil
	end

	local look = root.CFrame.LookVector
	local bestTarget = nil
	local bestDistance = range

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			local targetRoot = getRoot(otherPlayer)
			local humanoid = getHumanoid(otherPlayer)

			if targetRoot and humanoid and humanoid.Health > 0 then
				local offset = targetRoot.Position - root.Position
				local distance = offset.Magnitude

				if distance <= range and distance > 0.1 then
					local direction = offset.Unit
					local dot = look:Dot(direction)

					if dot >= coneDot and distance < bestDistance then
						bestDistance = distance
						bestTarget = otherPlayer
					end
				end
			end
		end
	end

	return bestTarget
end

local function pushTarget(attacker, target)
	local config = getPushConfig()

	local attackerRoot = getRoot(attacker)
	local targetRoot = getRoot(target)

	if not attackerRoot or not targetRoot then
		return false
	end

	local horizontal = attackerRoot.CFrame.LookVector
	horizontal = Vector3.new(horizontal.X, 0, horizontal.Z)

	if horizontal.Magnitude < 0.05 then
		horizontal = (targetRoot.Position - attackerRoot.Position)
		horizontal = Vector3.new(horizontal.X, 0, horizontal.Z)
	end

	if horizontal.Magnitude < 0.05 then
		return false
	end

	horizontal = horizontal.Unit

	local velocity = horizontal * (config.HorizontalPower or 85)
	velocity += Vector3.new(0, config.UpPower or 18, 0)

	targetRoot.AssemblyLinearVelocity = velocity

	target:SetAttribute("LastPushedByUserId", attacker.UserId)
	target:SetAttribute("LastPushedAt", os.clock())

	return true
end

function PushService:Start()
	local pushRemote = getOrCreateRemoteEvent("PushRequest")

	pushRemote.OnServerEvent:Connect(function(player)
		local config = getPushConfig()

		if config.Enabled == false then
			return
		end

		local now = os.clock()
		local cooldown = config.Cooldown or 2.2
		local last = lastPushAt[player] or -999999

		if now - last < cooldown then
			return
		end

		lastPushAt[player] = now

		local humanoid = getHumanoid(player)

		if not humanoid or humanoid.Health <= 0 then
			return
		end

		local target = findTargetInFront(player)

		if target then
			pushTarget(player, target)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		lastPushAt[player] = nil
	end)

	print("[PushService] Started.")
end

return PushService