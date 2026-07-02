local Controllers = script:WaitForChild("Controllers")

local GraphicsController = require(Controllers.GraphicsController)
local StairRenderController = require(Controllers.StairRenderController)
local UIController = require(Controllers.UIController)

print("[Client] Starting ReZero-Test")

GraphicsController:Start()
StairRenderController:Start(GraphicsController)
UIController:Start(GraphicsController)

print("[Client] ReZero-Test started")
