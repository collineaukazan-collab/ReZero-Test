local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local MusicController = {}

local random = Random.new()
local currentSound = nil
local lastTrackId = nil

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
	local tracks = {}

	for _, id in ipairs(GameConfig.MusicTracks or {}) do
		if type(id) == "string"
			and id ~= ""
			and id ~= "rbxassetid://0"
		then
			table.insert(tracks, id)
		end
	end

	return tracks
end

local function chooseTrack(tracks)
	if #tracks == 0 then
		return nil
	end

	if #tracks == 1 then
		return tracks[1]
	end

	for _ = 1, 8 do
		local chosen = tracks[random:NextInteger(1, #tracks)]
		if chosen ~= lastTrackId then
			return chosen
		end
	end

	return tracks[random:NextInteger(1, #tracks)]
end

local function playNext()
	local tracks = getValidTracks()

	if #tracks == 0 then
		warn("[MusicController] No music tracks in GameConfig.MusicTracks.")
		return
	end

	local trackId = chooseTrack(tracks)
	if not trackId then
		return
	end

	lastTrackId = trackId

	if currentSound then
		currentSound:Destroy()
		currentSound = nil
	end

	local musicGroup = getOrCreateSoundGroup("Music", GameConfig.DefaultMusicVolume or 0.6)

	local sound = Instance.new("Sound")
	sound.Name = "BackgroundMusic"
	sound.SoundId = trackId
	sound.Volume = 1
	sound.Looped = false
	sound.SoundGroup = musicGroup
	sound.Parent = SoundService

	currentSound = sound

	sound.Ended:Connect(function()
		task.delay(GameConfig.MusicDelayBetweenTracks or 1, function()
			if currentSound == sound then
				playNext()
			end
		end)
	end)

	sound:Play()
end

function MusicController:Start()
	playNext()
end

return MusicController