local Controllers = script:WaitForChild("Controllers")

local GraphicsController = require(Controllers.GraphicsController)
local StairRenderController = require(Controllers.StairRenderController)
local UIController = require(Controllers.UIController)

local AtmosphereController = Controllers:FindFirstChild("AtmosphereController")
local DeathEffectsController = Controllers:FindFirstChild("DeathEffectsController")
local DebugFlyController = Controllers:FindFirstChild("DebugFlyController")
local InsanityBarController = Controllers:FindFirstChild("InsanityBarController")
local InsanityEffectsController = Controllers:FindFirstChild("InsanityEffectsController")

print("[Client] Starting ReZero-Test")

GraphicsController:Start()

if AtmosphereController then
	require(AtmosphereController):Start()
end

if DeathEffectsController then
	require(DeathEffectsController):Start()
end

if DebugFlyController then
	require(DebugFlyController):Start()
end

if InsanityBarController then
	require(InsanityBarController):Start()
end

if InsanityEffectsController then
	require(InsanityEffectsController):Start()
end

StairRenderController:Start(GraphicsController)
UIController:Start(GraphicsController)

print("[Client] ReZero-Test started")