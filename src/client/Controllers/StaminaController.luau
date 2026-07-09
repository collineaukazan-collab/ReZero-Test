local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local StaminaController = {}

local localPlayer = Players.LocalPlayer

local character = nil
local humanoid = nil

local stamina = 100
local exhausted = false
local shiftHeld = false
local lastSprintInputAt = 0
local started = false

local function getStaminaConfig()
	return GameConfig.Stamina or {}
end

local function getCharacterConfig()
	return GameConfig.Character or {}
end

local function getRestConfig()
	return GameConfig.Rest or {}
end

local function applyRigGroundFix()
	if not humanoid then
		return
	end

	if humanoid.RigType == Enum.HumanoidRigType.R6 then
		humanoid.HipHeight = 0
	else
		local charConfig = getCharacterConfig()
		humanoid.HipHeight = charConfig.HipHeight or humanoid.HipHeight
	end
end

local function getMaxStamina()
	local config = getStaminaConfig()
	local multiplier = localPlayer:GetAttribute("SinStaminaMultiplier") or 1

	return math.max(1, (config.Max or 100) * multiplier)
end

local function getWalkSpeed()
	local config = getStaminaConfig()
	local base = config.WalkSpeed or 16

	base *= localPlayer:GetAttribute("SinWalkSpeedMultiplier") or 1

	return base
end

local function getSprintSpeed()
	local config = getStaminaConfig()
	local base = config.SprintSpeed or 24

	base *= localPlayer:GetAttribute("SinRunSpeedMultiplier") or 1
	base *= localPlayer:GetAttribute("SinLustRunSpeedMultiplier") or 1

	return base
end

local function setJumpEnabled(enabled)
	if not humanoid then
		return
	end

	local charConfig = getCharacterConfig()

	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, enabled)

	if enabled then
		humanoid.JumpPower = charConfig.JumpPower or 55
		humanoid.JumpHeight = charConfig.JumpHeight or 7.2
	else
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
	end
end

local function isRagdolled()
	return character and character:GetAttribute("IsRagdolled") == true
end

local function isResting()
	return localPlayer:GetAttribute("IsResting") == true
end

local function isRunToggled()
	return localPlayer:GetAttribute("RunToggled") == true
end

local function canSprint()
	local config = getStaminaConfig()
	local minToSprint = config.MinToSprint or 0

	if exhausted then
		return false
	end

	if stamina <= minToSprint then
		return false
	end

	if isResting() then
		return false
	end

	if isRagdolled() then
		return false
	end

	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	return true
end

local function wantsToSprint()
	return shiftHeld or isRunToggled()
end

local function setStamina(value)
	local maxStamina = getMaxStamina()

	stamina = math.clamp(value, 0, maxStamina)
	localPlayer:SetAttribute("Stamina", stamina)
	localPlayer:SetAttribute("MaxStamina", maxStamina)
end

local function setupCharacter(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid", 10)

	local maxStamina = getMaxStamina()
	stamina = math.clamp(localPlayer:GetAttribute("Stamina") or maxStamina, 0, maxStamina)
	exhausted = false

	setStamina(stamina)

	if humanoid then
		local charConfig = getCharacterConfig()

		applyRigGroundFix()

		humanoid.WalkSpeed = getWalkSpeed()
		humanoid.JumpPower = charConfig.JumpPower or 55
		humanoid.JumpHeight = charConfig.JumpHeight or 7.2
		humanoid.MaxSlopeAngle = charConfig.MaxSlopeAngle or humanoid.MaxSlopeAngle

		humanoid.PlatformStand = false
		humanoid.AutoRotate = true

		humanoid.Died:Connect(function()
			localPlayer:SetAttribute("RunToggled", false)
			exhausted = false
		end)
	end
end

local function update(dt)
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	applyRigGroundFix()

	local config = getStaminaConfig()
	local restConfig = getRestConfig()

	local maxStamina = getMaxStamina()
	local drain = config.DrainPerSecond or 20
	local regen = config.RegenPerSecond or 15
	local regenDelay = config.RegenDelay or 0.75
	local recoverToSprint = config.RecoverToSprint or 18

	if stamina > maxStamina then
		stamina = maxStamina
	end

	if isRagdolled() then
		humanoid.WalkSpeed = 0
		setJumpEnabled(false)
		setStamina(stamina)
		return
	end

	if isResting() then
		humanoid.WalkSpeed = 0
		setJumpEnabled(not (restConfig.DisableJump == true))

		stamina += regen * dt
		setStamina(stamina)
		return
	end

	setJumpEnabled(true)

	local sprinting = wantsToSprint() and canSprint()

	if sprinting then
		stamina -= drain * dt
		lastSprintInputAt = os.clock()

		if stamina <= 0 then
			stamina = 0
			exhausted = true
			localPlayer:SetAttribute("RunToggled", false)
			sprinting = false
		end
	else
		if os.clock() - lastSprintInputAt >= regenDelay then
			stamina += regen * dt
		end

		if exhausted and stamina >= recoverToSprint then
			exhausted = false
		end
	end

	setStamina(stamina)

	if sprinting then
		humanoid.WalkSpeed = getSprintSpeed()
	else
		humanoid.WalkSpeed = getWalkSpeed()
	end
end

function StaminaController:Start()
	if started then
		return
	end

	started = true

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			shiftHeld = true
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			shiftHeld = false
		end
	end)

	localPlayer.CharacterAdded:Connect(setupCharacter)

	if localPlayer.Character then
		setupCharacter(localPlayer.Character)
	end

	localPlayer:GetAttributeChangedSignal("Stamina"):Connect(function()
		local value = localPlayer:GetAttribute("Stamina")

		if typeof(value) == "number" then
			stamina = math.clamp(value, 0, getMaxStamina())
		end
	end)

	RunService.RenderStepped:Connect(update)

	print("[StaminaController] Started.")
end

return StaminaController