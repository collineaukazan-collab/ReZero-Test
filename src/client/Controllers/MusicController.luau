local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local MusicController = {}

local currentSound = nil
local lastTrackId = nil
local random = Random.new()

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

local function getValidTracks()
	local validTracks = {}

	for _, soundId in ipairs(GameConfig.MusicTracks or {}) do
		if type(soundId) == "string" and soundId ~= "" and soundId ~= "rbxassetid://0" then
			table.insert(validTracks, soundId)
		end
	end

	return validTracks
end

local function chooseRandomTrack(tracks)
	if #tracks == 0 then
		return nil
	end

	if #tracks == 1 then
		return tracks[1]
	end

	local chosen = nil

	for _ = 1, 10 do
		chosen = tracks[random:NextInteger(1, #tracks)]

		if chosen ~= lastTrackId then
			break
		end
	end

	return chosen
end

local function playNextTrack()
	local tracks = getValidTracks()

	if #tracks == 0 then
		warn("[MusicController] No valid music tracks configured.")
		return
	end

	local musicGroup = getOrCreateSoundGroup("Music", GameConfig.DefaultMusicVolume or 0.6)
	local trackId = chooseRandomTrack(tracks)

	if not trackId then
		return
	end

	lastTrackId = trackId

	if currentSound then
		currentSound:Destroy()
		currentSound = nil
	end

	local sound = Instance.new("Sound")
	sound.Name = "BackgroundMusic"
	sound.SoundId = trackId
	sound.Volume = 1
	sound.Looped = false
	sound.SoundGroup = musicGroup
	sound.Parent = SoundService

	currentSound = sound

	sound.Ended:Connect(function()
		task.delay(GameConfig.MusicDelayBetweenTracks or 2, function()
			if currentSound == sound then
				playNextTrack()
			end
		end)
	end)

	sound:Play()
end

function MusicController:Start()
	playNextTrack()
end

return MusicController