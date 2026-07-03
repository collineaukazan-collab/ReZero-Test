local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local StaminaController = {}

local localPlayer = Players.LocalPlayer

local stamina = GameConfig.Stamina.Max
local sprintHeld = false
local exhausted = false
local lastSprintTime = 0

local currentHumanoid = nil
local currentCharacter = nil

local function isSprintKey(input)
	return input.KeyCode == Enum.KeyCode.LeftShift
		or input.KeyCode == Enum.KeyCode.RightShift
end

local function setupCharacter(character)
	currentCharacter = character
	currentHumanoid = character:WaitForChild("Humanoid", 10)

	stamina = GameConfig.Stamina.Max
	exhausted = false
	localPlayer:SetAttribute("Stamina", stamina)

	if currentHumanoid then
		currentHumanoid.WalkSpeed = GameConfig.Stamina.WalkSpeed
	end
end

function StaminaController:Start()
	localPlayer:SetAttribute("Stamina", stamina)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if isSprintKey(input) then
			sprintHeld = true
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if isSprintKey(input) then
			sprintHeld = false
		end
	end)

	localPlayer.CharacterAdded:Connect(function(character)
		setupCharacter(character)
	end)

	if localPlayer.Character then
		setupCharacter(localPlayer.Character)
	end

	RunService.RenderStepped:Connect(function(deltaTime)
		if not currentCharacter or not currentHumanoid or currentHumanoid.Health <= 0 then
			return
		end

		if currentCharacter:GetAttribute("IsRagdolled") then
			currentHumanoid.WalkSpeed = 0
			return
		end

		local moving = currentHumanoid.MoveDirection.Magnitude > 0.05

		local recoverToSprint = GameConfig.Stamina.RecoverToSprint or 18
		local minToSprint = GameConfig.Stamina.MinToSprint or 0

		if exhausted and stamina >= recoverToSprint then
			exhausted = false
		end

		local canSprint =
			sprintHeld
			and moving
			and not exhausted
			and stamina > minToSprint
			and stamina > 0

		if canSprint then
			currentHumanoid.WalkSpeed = GameConfig.Stamina.SprintSpeed
			stamina = math.max(0, stamina - GameConfig.Stamina.DrainPerSecond * deltaTime)
			lastSprintTime = os.clock()

			if stamina <= 0 then
				stamina = 0
				exhausted = true
				currentHumanoid.WalkSpeed = GameConfig.Stamina.WalkSpeed
			end
		else
			currentHumanoid.WalkSpeed = GameConfig.Stamina.WalkSpeed

			if os.clock() - lastSprintTime >= GameConfig.Stamina.RegenDelay then
				stamina = math.min(
					GameConfig.Stamina.Max,
					stamina + GameConfig.Stamina.RegenPerSecond * deltaTime
				)
			end
		end

		localPlayer:SetAttribute("Stamina", stamina)
	end)
end

return StaminaController