local Controllers = script:WaitForChild("Controllers")

local GraphicsController = require(Controllers.GraphicsController)
local StairRenderController = require(Controllers.StairRenderController)
local UIController = require(Controllers.UIController)
local AtmosphereController = require(Controllers.AtmosphereController)
local DeathEffectsController = require(Controllers.DeathEffectsController)

print("[Client] Starting ReZero-Test")

GraphicsController:Start()
AtmosphereController:Start()
DeathEffectsController:Start()
StairRenderController:Start(GraphicsController)
UIController:Start(GraphicsController)

print("[Client] ReZero-Test started")
