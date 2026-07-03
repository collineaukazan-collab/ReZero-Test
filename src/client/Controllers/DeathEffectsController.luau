local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local DeathEffectsController = {}

local localPlayer = Players.LocalPlayer

local blackFrame = nil
local deathSound = nil
local fallDarkened = false

local function getOrCreateSoundGroup(name, volume)
	local group = SoundService:FindFirstChild(name)

	if not group then
		group = Instance.new("SoundGroup")
		group.Name = name
		group.Parent = SoundService
	end

	group.Volume = volume
	return group
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

local function playDeathSound()
	if not deathSound then
		return
	end

	if deathSound.SoundId == "" then
		return
	end

	deathSound:Play()
end

local function setupCharacter(character)
	fallDarkened = false

	task.delay(0.15, function()
		fadeBlackOut()
	end)

	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then
		return
	end

	humanoid.Died:Connect(function()
		setBlackInstant()
		playDeathSound()
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

	local sfxGroup = getOrCreateSoundGroup("SFX", GameConfig.DefaultSfxVolume)

	deathSound = Instance.new("Sound")
	deathSound.Name = "DeathRespawnSound"
	deathSound.Volume = 1
	deathSound.SoundGroup = sfxGroup
	deathSound.Parent = SoundService

	if GameConfig.RespawnSoundId ~= "" then
		deathSound.SoundId = GameConfig.RespawnSoundId
	end

	local remotes = ReplicatedStorage:WaitForChild("Remotes")

	remotes:WaitForChild("FallStarted").OnClientEvent:Connect(function()
		darkenDuringFall()
	end)

	remotes:WaitForChild("ForceBlackScreen").OnClientEvent:Connect(function()
		setBlackInstant()
	end)

	localPlayer.CharacterAdded:Connect(function(character)
		setupCharacter(character)
	end)

	if localPlayer.Character then
		setupCharacter(localPlayer.Character)
	end
end

return DeathEffectsController