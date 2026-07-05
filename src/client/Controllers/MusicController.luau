local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local MusicController = {}

local random = Random.new()

local library = {}
local currentSound = nil
local currentIndex = 1
local lastRandomIndex = nil
local isPaused = false
local playbackSpeed = 1
local loopEnabled = false
local started = false

local changedEvent = Instance.new("BindableEvent")
MusicController.Changed = changedEvent.Event

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

local function rebuildLibrary()
	local audio = getAudioConfig()
	local result = {}

	if type(audio.MusicLibrary) == "table" then
		for index, entry in ipairs(audio.MusicLibrary) do
			local name = "Music " .. tostring(index)
			local soundId = ""

			if type(entry) == "table" then
				name = tostring(entry.Name or entry.Title or name)
				soundId = normalizeSoundId(entry.SoundId or entry.Id or entry[1])
			else
				soundId = normalizeSoundId(entry)
			end

			if soundId ~= "" then
				table.insert(result, {
					Name = name,
					SoundId = soundId,
				})
			end
		end
	end

	if #result == 0 then
		for index, id in ipairs(audio.BackgroundTracks or GameConfig.MusicTracks or {}) do
			local soundId = normalizeSoundId(id)

			if soundId ~= "" then
				table.insert(result, {
					Name = "Music " .. tostring(index),
					SoundId = soundId,
				})
			end
		end
	end

	library = result

	if currentIndex > #library then
		currentIndex = 1
	end
end

local function fireChanged()
	changedEvent:Fire(MusicController:GetState())
end

local function stopCurrent()
	if currentSound then
		currentSound:Stop()
		currentSound:Destroy()
		currentSound = nil
	end
end

local function getNextIndex()
	local audio = getAudioConfig()

	if #library == 0 then
		return nil
	end

	if #library == 1 then
		return 1
	end

	if audio.BackgroundRandom == true then
		for _ = 1, 8 do
			local chosen = random:NextInteger(1, #library)

			if chosen ~= lastRandomIndex then
				lastRandomIndex = chosen
				return chosen
			end
		end

		lastRandomIndex = random:NextInteger(1, #library)
		return lastRandomIndex
	end

	local nextIndex = currentIndex + 1

	if nextIndex > #library then
		nextIndex = 1
	end

	return nextIndex
end

function MusicController:GetLibrary()
	rebuildLibrary()
	return library
end

function MusicController:GetCurrentSound()
	return currentSound
end

function MusicController:GetCurrentTrack()
	return library[currentIndex]
end

function MusicController:GetCurrentIndex()
	return currentIndex
end

function MusicController:GetVolume()
	local audio = getAudioConfig()
	local group = getOrCreateSoundGroup("Music", audio.MusicVolume or GameConfig.DefaultMusicVolume or 0.6)

	return group.Volume
end

function MusicController:SetVolume(value)
	local audio = getAudioConfig()
	local group = getOrCreateSoundGroup("Music", audio.MusicVolume or GameConfig.DefaultMusicVolume or 0.6)

	group.Volume = math.clamp(value, 0, 1)
	fireChanged()
end

function MusicController:GetLoopEnabled()
	return loopEnabled
end

function MusicController:SetLoopEnabled(value)
	loopEnabled = value == true

	if currentSound then
		currentSound.Looped = loopEnabled
	end

	fireChanged()
end

function MusicController:ToggleLoop()
	self:SetLoopEnabled(not loopEnabled)
end

function MusicController:SetPlaybackSpeed(value)
	playbackSpeed = math.clamp(value, 0.5, 1.5)

	if currentSound then
		currentSound.PlaybackSpeed = playbackSpeed
	end

	fireChanged()
end

function MusicController:Seek(alpha)
	if not currentSound then
		return
	end

	local length = currentSound.TimeLength

	if length <= 0 then
		return
	end

	currentSound.TimePosition = math.clamp(alpha, 0, 1) * length
	fireChanged()
end

function MusicController:GetState()
	local sound = currentSound
	local track = self:GetCurrentTrack()

	return {
		Track = track,
		Index = currentIndex,
		Count = #library,
		IsPlaying = sound ~= nil and sound.IsPlaying,
		IsPaused = isPaused,
		TimePosition = sound and sound.TimePosition or 0,
		TimeLength = sound and sound.TimeLength or 0,
		PlaybackSpeed = playbackSpeed,
		Volume = self:GetVolume(),
		LoopEnabled = loopEnabled,
	}
end

function MusicController:PlayIndex(index)
	rebuildLibrary()

	if #library == 0 then
		warn("[MusicController] No music in GameConfig.Audio.MusicLibrary or BackgroundTracks.")
		fireChanged()
		return false
	end

	index = math.clamp(math.floor(index or 1), 1, #library)
	currentIndex = index

	local track = library[currentIndex]

	stopCurrent()

	local audio = getAudioConfig()
	local musicGroup = getOrCreateSoundGroup("Music", audio.MusicVolume or GameConfig.DefaultMusicVolume or 0.6)

	local sound = Instance.new("Sound")
	sound.Name = "BackgroundMusic"
	sound.SoundId = track.SoundId
	sound.Volume = 1
	sound.Looped = loopEnabled
	sound.PlaybackSpeed = playbackSpeed
	sound.SoundGroup = musicGroup
	sound.Parent = SoundService

	currentSound = sound
	isPaused = false

	sound.Ended:Connect(function()
		if currentSound ~= sound then
			return
		end

		if loopEnabled then
			return
		end

		task.delay(audio.DelayBetweenBackgroundTracks or GameConfig.MusicDelayBetweenTracks or 1, function()
			if currentSound == sound and not loopEnabled then
				MusicController:Next()
			end
		end)
	end)

	print("[MusicController] Playing radio:", track.Name, track.SoundId)

	sound:Play()
	fireChanged()

	return true
end

function MusicController:Next()
	rebuildLibrary()

	local nextIndex = getNextIndex()

	if not nextIndex then
		fireChanged()
		return false
	end

	return self:PlayIndex(nextIndex)
end

function MusicController:Previous()
	rebuildLibrary()

	if #library == 0 then
		fireChanged()
		return false
	end

	local previousIndex = currentIndex - 1

	if previousIndex < 1 then
		previousIndex = #library
	end

	return self:PlayIndex(previousIndex)
end

function MusicController:TogglePause()
	if not currentSound then
		self:PlayIndex(currentIndex)
		return
	end

	if isPaused then
		currentSound:Resume()
		isPaused = false
	else
		currentSound:Pause()
		isPaused = true
	end

	fireChanged()
end

function MusicController:Start()
	if started then
		return
	end

	started = true

	local audio = getAudioConfig()
	loopEnabled = audio.RadioDefaultLoop == true

	rebuildLibrary()

	if #library == 0 then
		warn("[MusicController] No music configured.")
		fireChanged()
		return
	end

	self:PlayIndex(currentIndex)
end

return MusicController