local Players = game:GetService("Players")

local LeaderboardService = {}

local function getOrCreateIntValue(parent, name)
	local value = parent:FindFirstChild(name)

	if not value then
		value = Instance.new("IntValue")
		value.Name = name
		value.Parent = parent
	end

	return value
end

local function waitForProfile(player, playerDataService)
	for _ = 1, 50 do
		local profile = playerDataService:Get(player)
		if profile then
			return profile
		end

		task.wait(0.1)
	end

	return playerDataService:Get(player)
end

local function setupLeaderboard(player, playerDataService)
	waitForProfile(player, playerDataService)

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local studsValue = getOrCreateIntValue(leaderstats, "Studs")
	local bestValue = getOrCreateIntValue(leaderstats, "Best")
	local moneyValue = getOrCreateIntValue(leaderstats, "Money")

	local function sync()
		studsValue.Value = math.floor(player:GetAttribute("CurrentStuds") or 0)
		bestValue.Value = math.floor(player:GetAttribute("BestStuds") or 0)
		moneyValue.Value = math.floor(player:GetAttribute("Money") or 0)
	end

	sync()

	player:GetAttributeChangedSignal("CurrentStuds"):Connect(sync)
	player:GetAttributeChangedSignal("BestStuds"):Connect(sync)
	player:GetAttributeChangedSignal("Money"):Connect(sync)
end

function LeaderboardService:Start(playerDataService)
	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			setupLeaderboard(player, playerDataService)
		end)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			setupLeaderboard(player, playerDataService)
		end)
	end
end

return LeaderboardService
