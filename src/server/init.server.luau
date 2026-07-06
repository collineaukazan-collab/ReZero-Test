local Services = script:WaitForChild("Services")

local function requireService(name, optional)
	local module = Services:FindFirstChild(name)

	if not module then
		if not optional then
			warn("[Server] Missing service:", name)
		end

		return nil
	end

	local success, result = pcall(require, module)

	if not success then
		warn("[Server] Failed to require", name, result)
		return nil
	end

	return result
end

local function startService(name, optional)
	local service = requireService(name, optional)

	if not service then
		return nil
	end

	if type(service) ~= "table" then
		warn("[Server] Service did not return a table:", name)
		return nil
	end

	if type(service.Start) ~= "function" then
		warn("[Server] Service has no Start function:", name)
		return service
	end

	local success, err = pcall(function()
		service:Start()
	end)

	if not success then
		warn("[Server] Failed to start service:", name, err)
	end

	return service
end

-- Services de base
startService("RemoteService", true)
startService("PlayerDataService", true)

-- Monde / rendu serveur
startService("WorldService", true)
startService("SinAltarService", true)

-- Stats / récompenses
startService("LeaderboardService", true)
startService("RewardService", true)

-- Physique / hauteur / folie
startService("RagdollService", true)
startService("HeightService", true)
startService("InsanityService", true)

-- Sins / push
startService("SinService", true)
startService("PushService", true)

print("[Server] ReZero-Test server started.")