local Services = script:WaitForChild("Services")

local PlayerDataService = require(Services.PlayerDataService)
local WorldService = require(Services.WorldService)
local RemoteService = require(Services.RemoteService)
local LeaderboardService = require(Services.LeaderboardService)
local HeightService = require(Services.HeightService)
local RewardService = require(Services.RewardService)
local RagdollService = require(Services.RagdollService)

local CharacterService = Services:FindFirstChild("CharacterService")
local InsanityService = require(Services.InsanityService)

print("[Server] Starting ReZero-Test")

PlayerDataService:Start()
WorldService:Start()
RemoteService:Start(PlayerDataService)
LeaderboardService:Start(PlayerDataService)

if CharacterService then
	require(CharacterService):Start()
end

RagdollService:Start()
HeightService:Start(PlayerDataService, RagdollService)
InsanityService:Start(RagdollService)
RewardService:Start(PlayerDataService)

print("[Server] ReZero-Test started")