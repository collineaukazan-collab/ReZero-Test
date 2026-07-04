local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local MusicController = {}

local random = Random.new()
local currentSound = nil
local lastTrackId = nil
local orderedIndex = 0

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

local function getValidTracks()
	local audio = getAudioConfig()
	local tracks = {}

	for _, id in ipairs(audio.BackgroundTracks or {}) do
		local soundId = normalizeSoundId(id)

		if soundId ~= "" then
			table.insert(tracks, soundId)
		end
	end

	return tracks
end

local function chooseTrack(tracks)
	local audio = getAudioConfig()

	if #tracks == 0 then
		return nil
	end

	if #tracks == 1 then
		return tracks[1]
	end

	if audio.BackgroundRandom == false then
		orderedIndex += 1

		if orderedIndex > #tracks then
			orderedIndex = 1
		end

		return tracks[orderedIndex]
	end

	for _ = 1, 8 do
		local chosen = tracks[random:NextInteger(1, #tracks)]

		if chosen ~= lastTrackId then
			return chosen
		end
	end

	return tracks[random:NextInteger(1, #tracks)]
end

local function stopCurrent()
	if currentSound then
		currentSound:Stop()
		currentSound:Destroy()
		currentSound = nil
	end
end

function MusicController:PlayNext()
	local audio = getAudioConfig()
	local tracks = getValidTracks()
	local trackId = chooseTrack(tracks)

	if not trackId then
		warn("[MusicController] No background tracks in GameConfig.Audio.BackgroundTracks.")
		return false
	end

	stopCurrent()

	local musicGroup = getOrCreateSoundGroup("Music", audio.MusicVolume or 0.6)

	local sound = Instance.new("Sound")
	sound.Name = "BackgroundMusic"
	sound.SoundId = trackId
	sound.Volume = 1
	sound.Looped = audio.BackgroundLoop == true and #tracks == 1
	sound.SoundGroup = musicGroup
	sound.Parent = SoundService

	currentSound = sound
	lastTrackId = trackId

	sound.Ended:Connect(function()
		if currentSound ~= sound then
			return
		end

		if #tracks == 1 and audio.BackgroundLoop == true then
			return
		end

		task.delay(audio.DelayBetweenBackgroundTracks or 1, function()
			if currentSound == sound then
				self:PlayNext()
			end
		end)
	end)

	print("[MusicController] Playing background:", trackId)
	sound:Play()

	return true
end

function MusicController:Start()
	self:PlayNext()
end

return MusicController