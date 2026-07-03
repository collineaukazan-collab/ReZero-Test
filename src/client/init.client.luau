local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Controllers = script:WaitForChild("Controllers")

local function requireController(name)
	local module = Controllers:FindFirstChild(name)

	if not module then
		warn("[Client] Missing controller:", name)
		return nil
	end

	local success, result = pcall(require, module)

	if not success then
		warn("[Client] Failed to require", name, result)
		return nil
	end

	return result
end

local GraphicsController = requireController("GraphicsController")
local StairRenderController = requireController("StairRenderController")
local UIController = requireController("UIController")
local AtmosphereController = requireController("AtmosphereController")
local DeathEffectsController = requireController("DeathEffectsController")
local DebugFlyController = requireController("DebugFlyController")
local InsanityBarController = requireController("InsanityBarController")
local InsanityEffectsController = requireController("InsanityEffectsController")
local StaminaController = requireController("StaminaController")
local MusicController = requireController("MusicController")
local AnimationController = requireController("AnimationController")

if GraphicsController and GraphicsController.Start then
	GraphicsController:Start()
end

if AtmosphereController and AtmosphereController.Start then
	AtmosphereController:Start()
end

if DeathEffectsController and DeathEffectsController.Start then
	DeathEffectsController:Start()
end

if DebugFlyController and DebugFlyController.Start then
	DebugFlyController:Start()
end

if InsanityBarController and InsanityBarController.Start then
	InsanityBarController:Start()
end

if InsanityEffectsController and InsanityEffectsController.Start then
	InsanityEffectsController:Start()
end

if StaminaController and StaminaController.Start then
	StaminaController:Start()
end

if MusicController and MusicController.Start then
	MusicController:Start()
end

if AnimationController and AnimationController.Start then
	AnimationController:Start()
end

if StairRenderController and StairRenderController.Start and GraphicsController then
	StairRenderController:Start(GraphicsController)
end

if UIController and UIController.Start and GraphicsController then
	UIController:Start(GraphicsController)
end

print("[Client] ReZero-Test started")