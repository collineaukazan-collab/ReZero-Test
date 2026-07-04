local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local NumberUtil = require(ReplicatedStorage.Shared.Utils.NumberUtil)

local DeathEffectsController = {}

local localPlayer = Players.LocalPlayer

local blackFrame = nil
local deathSound = nil
local respawnSound = nil
local fallDarkened = false
local cameraConnection = nil
local summaryFrame = nil
local summaryText = nil

local function getAudioConfig()
	return GameConfig.Audio or {}
end

local function normalizeSoundId(id)
	if id == nil then
		return ""
	end

	id = tostring(id)

	if id == "" or id == "0" or id == "rbxassetid://0" then
		return ""
	end

	if string.find(id, "rbxassetid://") == 1 then
		return id
	end

	return "rbxassetid://" .. id
end

local function getOrCreateSoundGroup(name, defaultVolume)
	local group = SoundService:FindFirstChild(name)

	if not group then
		group = Instance.new("SoundGroup")
		group.Name = name
		group.Volume = defaultVolume
		group.Parent = SoundService
	end

	return group
end

local function isValidSoundId(soundId)
	soundId = normalizeSoundId(soundId)

	return type(soundId) == "string"
		and soundId ~= ""
		and soundId ~= "rbxassetid://0"
end

local function setupSounds()
	local audio = getAudioConfig()
	local sfxGroup = getOrCreateSoundGroup("SFX", audio.SfxVolume or 0.8)

	if deathSound then
		deathSound:Destroy()
		deathSound = nil
	end

	if respawnSound then
		respawnSound:Destroy()
		respawnSound = nil
	end

	deathSound = Instance.new("Sound")
	deathSound.Name = "DeathSound"
	deathSound.Volume = 1
	deathSound.SoundGroup = sfxGroup
	deathSound.Parent = SoundService
	deathSound.SoundId = normalizeSoundId(audio.DeathSoundId)

	respawnSound = Instance.new("Sound")
	respawnSound.Name = "RespawnSound"
	respawnSound.Volume = 1
	respawnSound.SoundGroup = sfxGroup
	respawnSound.Parent = SoundService
	respawnSound.SoundId = normalizeSoundId(audio.RespawnSoundId)

	if deathSound.SoundId ~= "" then
		print("[DeathEffectsController] Death sound:", deathSound.SoundId)
	end

	if respawnSound.SoundId ~= "" then
		print("[DeathEffectsController] Respawn sound:", respawnSound.SoundId)
	end
end

local function playSound(sound)
	if not sound then
		return
	end

	if not isValidSoundId(sound.SoundId) then
		return
	end

	sound:Play()
end

local function setBlackInstant()
	if blackFrame then
		blackFrame.BackgroundTransparency = 0
	end
end

local function fadeBlackOut()
	if not blackFrame then
		return
	end

	local tween = TweenService:Create(
		blackFrame,
		TweenInfo.new(GameConfig.RespawnFadeOutTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 }
	)

	tween:Play()
end

local function darkenDuringFall()
	if fallDarkened or not blackFrame then
		return
	end

	fallDarkened = true

	local tween = TweenService:Create(
		blackFrame,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = GameConfig.FallDarkenTransparency }
	)

	tween:Play()
end

local function stopFallCamera()
	if cameraConnection then
		cameraConnection:Disconnect()
		cameraConnection = nil
	end
end

local function startFallCamera()
	stopFallCamera()

	cameraConnection = RunService.RenderStepped:Connect(function()
		local character = localPlayer.Character
		if not character then
			return
		end

		local camera = Workspace.CurrentCamera
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local head = character:FindFirstChild("Head")

		if not camera then
			return
		end

		if head and character:GetAttribute("IsRagdolled") then
			camera.CameraSubject = head
		elseif humanoid then
			camera.CameraSubject = humanoid
		end
	end)
end

local function createSummaryGui(parent)
	summaryFrame = Instance.new("Frame")
	summaryFrame.Name = "DeathSummary"
	summaryFrame.Size = UDim2.new(0, 360, 0, 160)
	summaryFrame.Position = UDim2.new(0.5, -180, 0.72, -80)
	summaryFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
	summaryFrame.BackgroundTransparency = 0.05
	summaryFrame.BorderSizePixel = 0
	summaryFrame.Visible = false
	summaryFrame.Parent = parent

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(70, 70, 90)
	stroke.Thickness = 1
	stroke.Transparency = 0.2
	stroke.Parent = summaryFrame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, -24, 0, 32)
	title.Position = UDim2.new(0, 12, 0, 10)
	title.Font = Enum.Font.GothamMedium
	title.TextSize = 19
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Color3.fromRGB(235, 235, 245)
	title.Text = "RÉSUMÉ DE LA CHUTE"
	title.Parent = summaryFrame

	summaryText = Instance.new("TextLabel")
	summaryText.Name = "Text"
	summaryText.BackgroundTransparency = 1
	summaryText.Size = UDim2.new(1, -24, 1, -54)
	summaryText.Position = UDim2.new(0, 12, 0, 46)
	summaryText.Font = Enum.Font.Gotham
	summaryText.TextSize = 15
	summaryText.TextXAlignment = Enum.TextXAlignment.Left
	summaryText.TextYAlignment = Enum.TextYAlignment.Top
	summaryText.TextColor3 = Color3.fromRGB(220, 220, 230)
	summaryText.TextWrapped = true
	summaryText.Parent = summaryFrame
end

local function showDeathSummary()
	if not summaryFrame or not summaryText then
		return
	end

	local reward = math.floor(localPlayer:GetAttribute("LastReward") or 0)
	local studs = math.floor(localPlayer:GetAttribute("LastRunStuds") or 0)
	local floor = math.floor(localPlayer:GetAttribute("LastRunFloor") or 0)
	local multiplier = tonumber(localPlayer:GetAttribute("LastRunMultiplier")) or 1

	if reward <= 0 and studs <= 0 then
		return
	end

	summaryText.Text =
		"Hauteur atteinte : " .. NumberUtil.formatInteger(studs) .. " studs\n"
		.. "Étage atteint : " .. NumberUtil.formatInteger(floor) .. "\n"
		.. "Multiplicateur : x" .. tostring(multiplier) .. "\n"
		.. "Argent gagné : +" .. NumberUtil.formatInteger(reward)

	summaryFrame.Visible = true

	task.delay(5, function()
		if summaryFrame then
			summaryFrame.Visible = false
		end
	end)
end

local function setupCharacter(character)
	fallDarkened = false
	stopFallCamera()

	task.delay(0.15, function()
		fadeBlackOut()
		playSound(respawnSound)
	end)

	task.delay(0.8, function()
		showDeathSummary()
	end)

	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then
		return
	end

	local camera = Workspace.CurrentCamera
	if camera then
		camera.CameraSubject = humanoid
	end

	humanoid.Died:Connect(function()
		setBlackInstant()
		playSound(deathSound)
		stopFallCamera()
	end)
end

function DeathEffectsController:Start()
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	local oldGui = playerGui:FindFirstChild("DeathEffectsGui")
	if oldGui then
		oldGui:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DeathEffectsGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 999
	screenGui.Parent = playerGui

	blackFrame = Instance.new("Frame")
	blackFrame.Name = "BlackFrame"
	blackFrame.Size = UDim2.fromScale(1, 1)
	blackFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	blackFrame.BackgroundTransparency = 1
	blackFrame.Parent = screenGui

	createSummaryGui(screenGui)
	setupSounds()

	local remotes = ReplicatedStorage:WaitForChild("Remotes")

	remotes:WaitForChild("FallStarted").OnClientEvent:Connect(function()
		darkenDuringFall()
		startFallCamera()
	end)

	remotes:WaitForChild("ForceBlackScreen").OnClientEvent:Connect(function()
		setBlackInstant()
	end)

	localPlayer.CharacterAdded:Connect(function(character)
		setupSounds()
		setupCharacter(character)
	end)

	if localPlayer.Character then
		setupCharacter(localPlayer.Character)
	end
end

return DeathEffectsController