local Services = script:WaitForChild("Services")

local PlayerDataService = require(Services.PlayerDataService)
local WorldService = require(Services.WorldService)
local RemoteService = require(Services.RemoteService)
local LeaderboardService = require(Services.LeaderboardService)
local HeightService = require(Services.HeightService)
local RewardService = require(Services.RewardService)
local RagdollService = require(Services.RagdollService)

print("[Server] Starting ReZero-Test")

PlayerDataService:Start()
WorldService:Start()
RemoteService:Start(PlayerDataService)
LeaderboardService:Start(PlayerDataService)
RagdollService:Start()
HeightService:Start(PlayerDataService, RagdollService)
RewardService:Start(PlayerDataService)

print("[Server] ReZero-Test started")
