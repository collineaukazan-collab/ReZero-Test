local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local InsanityAudioController = {}

local localPlayer = Players.LocalPlayer

local musicEqualizer = nil
local sfxEqualizer = nil

local currentAlpha = 0

local function getOrCreateSoundGroup(name)
	local group = SoundService:FindFirstChild(name)

	if not group then
		group = Instance.new("SoundGroup")
		group.Name = name
		group.Volume = 1
		group.Parent = SoundService
	end

	return group
end

local function getOrCreateEqualizer(group, name)
	local equalizer = group:FindFirstChild(name)

	if not equalizer then
		equalizer = Instance.new("EqualizerSoundEffect")
		equalizer.Name = name
		equalizer.LowGain = 0
		equalizer.MidGain = 0
		equalizer.HighGain = 0
		equalizer.Enabled = true
		equalizer.Parent = group
	end

	return equalizer
end

local function getTargetAlpha()
	local insanity = localPlayer:GetAttribute("Insanity") or 0

	if insanity <= 90 then
		return 0
	end

	return math.clamp((insanity - 90) / 10, 0, 1)
end

function InsanityAudioController:Start()
	local musicGroup = getOrCreateSoundGroup("Music")
	local sfxGroup = getOrCreateSoundGroup("SFX")

	musicEqualizer = getOrCreateEqualizer(musicGroup, "InsanityMuffle")
	sfxEqualizer = getOrCreateEqualizer(sfxGroup, "InsanityMuffle")

	RunService.RenderStepped:Connect(function(dt)
		local targetAlpha = getTargetAlpha()
		local speed = 1 - math.exp(-dt * 4)

		currentAlpha += (targetAlpha - currentAlpha) * speed

		local musicHigh = -32 * currentAlpha
		local musicMid = -16 * currentAlpha
		local musicLow = 2 * currentAlpha

		local sfxHigh = -14 * currentAlpha
		local sfxMid = -7 * currentAlpha

		musicEqualizer.HighGain = musicHigh
		musicEqualizer.MidGain = musicMid
		musicEqualizer.LowGain = musicLow

		sfxEqualizer.HighGain = sfxHigh
		sfxEqualizer.MidGain = sfxMid
		sfxEqualizer.LowGain = 0
	end)

	print("[InsanityAudioController] Started.")
end

return InsanityAudioController