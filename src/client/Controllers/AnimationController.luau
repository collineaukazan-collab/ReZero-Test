local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationConfig = require(ReplicatedStorage.Shared.Config.AnimationConfig)

local AnimationController = {}

local localPlayer = Players.LocalPlayer

local function setAnimationId(animationObject, animationId)
	if not animationObject then
		return
	end

	if type(animationId) ~= "string" or animationId == "" then
		return
	end

	animationObject.AnimationId = animationId
end

local function applyR6Animations(character)
	local animate = character:WaitForChild("Animate", 10)
	if not animate then
		warn("[AnimationController] Animate script not found.")
		return
	end

	local config = AnimationConfig.R6

	local idle = animate:FindFirstChild("idle")
	if idle then
		setAnimationId(idle:FindFirstChild("Animation1"), config.Idle1)
		setAnimationId(idle:FindFirstChild("Animation2"), config.Idle2)
	end

	local walk = animate:FindFirstChild("walk")
	if walk then
		setAnimationId(walk:FindFirstChild("WalkAnim"), config.Walk)
	end

	local run = animate:FindFirstChild("run")
	if run then
		setAnimationId(run:FindFirstChild("RunAnim"), config.Run)
	end

	local jump = animate:FindFirstChild("jump")
	if jump then
		setAnimationId(jump:FindFirstChild("JumpAnim"), config.Jump)
	end

	local fall = animate:FindFirstChild("fall")
	if fall then
		setAnimationId(fall:FindFirstChild("FallAnim"), config.Fall)
	end

	local climb = animate:FindFirstChild("climb")
	if climb then
		setAnimationId(climb:FindFirstChild("ClimbAnim"), config.Climb)
	end

	local sit = animate:FindFirstChild("sit")
	if sit then
		setAnimationId(sit:FindFirstChild("SitAnim"), config.Sit)
	end

	print("[AnimationController] R6 animations applied.")
end

function AnimationController:Start()
	localPlayer.CharacterAdded:Connect(function(character)
		task.wait(0.3)
		applyR6Animations(character)
	end)

	if localPlayer.Character then
		task.wait(0.3)
		applyR6Animations(localPlayer.Character)
	end
end

return AnimationController