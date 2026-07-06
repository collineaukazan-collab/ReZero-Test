local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local RemoteService = {}

local function getOrCreateRemotesFolder()
	local folder = ReplicatedStorage:FindFirstChild("Remotes")

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end

	return folder
end

local function ensureRemote(name, className)
	local folder = getOrCreateRemotesFolder()
	local remote = folder:FindFirstChild(name)

	if remote and remote.ClassName ~= className then
		remote:Destroy()
		remote = nil
	end

	if not remote then
		remote = Instance.new(className)
		remote.Name = name
		remote.Parent = folder
	end

	return remote
end

local function isValidQuality(value)
	if type(value) ~= "string" then
		return false
	end

	local settings = GameConfig.QualitySettings or {}

	return settings[value] ~= nil
end

local function getPlayerData(player)
	return {
		Auracoins = player:GetAttribute("Auracoins") or player:GetAttribute("Money") or 0,

		BestStuds = player:GetAttribute("BestStuds") or 0,
		BestFloor = player:GetAttribute("BestFloor") or 0,

		CurrentStuds = player:GetAttribute("CurrentStuds") or 0,
		CurrentFloor = player:GetAttribute("CurrentFloor") or 0,
		RunBestStuds = player:GetAttribute("RunBestStuds") or 0,

		GraphicsQuality = player:GetAttribute("GraphicsQuality") or GameConfig.DefaultQuality or "Medium",

		SinShards = player:GetAttribute("SinShards") or 0,
	}
end

function RemoteService:Start()
	local getPlayerDataRemote = ensureRemote("GetPlayerData", "RemoteFunction")

	local setGraphicsQualityRemote = ensureRemote("SetGraphicsQuality", "RemoteEvent")
	local setRestingRemote = ensureRemote("SetResting", "RemoteEvent")

	ensureRemote("FallStarted", "RemoteEvent")
	ensureRemote("ForceBlackScreen", "RemoteEvent")
	ensureRemote("ClearImpactVisuals", "RemoteEvent")

	-- Sins / push, au cas où les services démarrent après.
	ensureRemote("OpenSinMenu", "RemoteEvent")
	ensureRemote("SinStateChanged", "RemoteEvent")
	ensureRemote("EquipSin", "RemoteEvent")
	ensureRemote("PushRequest", "RemoteEvent")

	ensureRemote("GetSinState", "RemoteFunction")
	ensureRemote("RollSin", "RemoteFunction")

	getPlayerDataRemote.OnServerInvoke = function(player)
		return getPlayerData(player)
	end

	setGraphicsQualityRemote.OnServerEvent:Connect(function(player, quality)
		if not isValidQuality(quality) then
			return
		end

		player:SetAttribute("GraphicsQuality", quality)
	end)

	setRestingRemote.OnServerEvent:Connect(function(player, value)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")

		if not humanoid or humanoid.Health <= 0 then
			player:SetAttribute("IsResting", false)
			return
		end

		if character:GetAttribute("IsRagdolled") == true then
			player:SetAttribute("IsResting", false)
			return
		end

		player:SetAttribute("IsResting", value == true)
	end)

	print("[RemoteService] Started.")
end

return RemoteService