local Controllers = script:WaitForChild("Controllers")

local function requireController(name, optional)
	local module = Controllers:FindFirstChild(name)

	if not module then
		if not optional then
			warn("[Client] Missing controller:", name)
		end

		return nil
	end

	local success, result = pcall(require, module)

	if not success then
		warn("[Client] Failed to require", name, result)
		return nil
	end

	return result
end

local function startController(name, optional, ...)
	local controller = requireController(name, optional)

	if not controller then
		return nil
	end

	if type(controller.Start) ~= "function" then
		warn("[Client] Controller has no Start function:", name)
		return controller
	end

	local args = { ... }

	local success, err = pcall(function()
		controller:Start(table.unpack(args))
	end)

	if not success then
		warn("[Client] Failed to start controller:", name, err)
	end

	return controller
end

local GraphicsController = startController("GraphicsController", true)

startController("AtmosphereController", true)
startController("TowerSandstormController", true)
startController("DeathEffectsController", true)
startController("DebugFlyController", true)
startController("InsanityBarController", true)
startController("InsanityEffectsController", true)
startController("StaminaController", true)

local MusicController = startController("MusicController", true)

if MusicController then
	startController("MusicPlayerController", true, MusicController)
end

startController("AuracoinPopupController", true)

startController("SinMenuController", true)
startController("SideButtonsController", true)
startController("ActionButtonsController", true)
startController("AnimationController", true)

if GraphicsController then
	startController("StairRenderController", true, GraphicsController)
	startController("UIController", true, GraphicsController)
else
	startController("StairRenderController", true)
	startController("UIController", true)
end

print("[Client] ReZero-Test started.")