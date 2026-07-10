local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local DeathEffectsController = {}

local localPlayer = Players.LocalPlayer

local gui = nil
local blackFrame = nil
local forceBlackScreenRemote = nil

local function getAudioConfig()
	return GameConfig.Audio or {}
end

local function getOrCreateSfxGroup()
	local group = SoundService:FindFirstChild("SFX")

	if not group then
		group = Instance.new("SoundGroup")
		group.Name = "SFX"
		group.Volume = getAudioConfig().SfxVolume or 0.8
		group.Parent = SoundService
	end

	return group
end

local function normalizeSoundId(id)
	if not id or id == "" then
		return ""
	end

	id = tostring(id)

	if string.find(id, "rbxassetid://") then
		return id
	end

	return "rbxassetid://" .. id
end

local function playSound(soundId)
	soundId = normalizeSoundId(soundId)

	if soundId == "" then
		return
	end

	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = 1
	sound.SoundGroup = getOrCreateSfxGroup()
	sound.Parent = SoundService

	sound:Play()

	task.delay(5, function()
		if sound then
			sound:Destroy()
		end
	end)
end

local function createGui()
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	local old = playerGui:FindFirstChild("DeathEffectsGui")
	if old then
		old:Destroy()
	end

	gui = Instance.new("ScreenGui")
	gui.Name = "DeathEffectsGui"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 10000
	gui.Parent = playerGui

	blackFrame = Instance.new("Frame")
	blackFrame.Name = "BlackFrame"
	blackFrame.Size = UDim2.fromScale(1, 1)
	blackFrame.Position = UDim2.fromScale(0, 0)
	blackFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	blackFrame.BackgroundTransparency = 1
	blackFrame.Visible = false
	blackFrame.Parent = gui
end

local function showBlackInstant()
	if not blackFrame then
		return
	end

	blackFrame.Visible = true
	blackFrame.BackgroundTransparency = 0
end

local function hideBlackInstant()
	if not blackFrame then
		return
	end

	-- Pas de fade-in / fade-out au respawn : ça disparaît d'un coup.
	blackFrame.Visible = false
	blackFrame.BackgroundTransparency = 1
end

function DeathEffectsController:Start()
	createGui()

	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	forceBlackScreenRemote = remotes:WaitForChild("ForceBlackScreen")

	forceBlackScreenRemote.OnClientEvent:Connect(function()
		showBlackInstant()
		playSound(getAudioConfig().DeathSoundId)
	end)

	localPlayer.CharacterAdded:Connect(function()
		hideBlackInstant()

		task.delay(0.15, function()
			hideBlackInstant()
			playSound(getAudioConfig().RespawnSoundId)
		end)
	end)

	if localPlayer.Character then
		hideBlackInstant()
	end

	print("[DeathEffectsController] Started instant respawn black screen.")
end

return DeathEffectsController