local Services = script:WaitForChild("Services")

local PlayerDataService = require(Services.PlayerDataService)
local WorldService = require(Services.WorldService)
local RemoteService = require(Services.RemoteService)
local LeaderboardService = require(Services.LeaderboardService)
local HeightService = require(Services.HeightService)
local RewardService = require(Services.RewardService)

print("[Server] Starting ReZero-Test")

PlayerDataService:Start()
WorldService:Start()
RemoteService:Start(PlayerDataService)
LeaderboardService:Start(PlayerDataService)
HeightService:Start(PlayerDataService)
RewardService:Start(PlayerDataService)

print("[Server] ReZero-Test started")
