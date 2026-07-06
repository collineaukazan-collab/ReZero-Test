local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local SinAltarService = {}

local function getRemotesFolder()
	local folder = ReplicatedStorage:FindFirstChild("Remotes")

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage.Remotes
	end

	return folder
end

local function getOrCreateOpenMenuRemote()
	local folder = ReplicatedStorage:FindFirstChild("Remotes")

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage.Remotes
	end

	local remote = folder:FindFirstChild("OpenSinMenu")

	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = "OpenSinMenu"
		remote.Parent = folder
	end

	return remote
end

local function clearOldAltar()
	local old = workspace:FindFirstChild("SinAltar")
	if old then
		old:Destroy()
	end
end

function SinAltarService:Start()
	clearOldAltar()

	local config = GameConfig.Sins or {}
	local openRemote = getOrCreateOpenMenuRemote()

	local altar = Instance.new("Part")
	altar.Name = "SinAltar"
	altar.Anchored = true
	altar.CanCollide = true
	altar.CanTouch = true
	altar.CanQuery = true
	altar.Size = Vector3.new(5, 6, 1)
	altar.Position = config.AltarPosition or Vector3.new(0, 4, 0)
	altar.Material = Enum.Material.Slate
	altar.Color = Color3.fromRGB(20, 14, 26)
	altar.Parent = workspace

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "OpenSinsPrompt"
	prompt.ActionText = "Open Sins"
	prompt.ObjectText = "Sins"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.Parent = altar

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "SinAltarBillboard"
	billboard.Size = UDim2.fromOffset(120, 120)
	billboard.StudsOffset = Vector3.new(0, 4.2, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = altar

	local image = Instance.new("ImageLabel")
	image.Name = "Image"
	image.BackgroundTransparency = 1
	image.Size = UDim2.fromScale(1, 1)
	image.Image = config.AltarImageId or "rbxassetid://0"
	image.Parent = billboard

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Position = UDim2.new(0, -30, 1, -14)
	title.Size = UDim2.new(1, 60, 0, 26)
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 22
	title.TextStrokeTransparency = 0
	title.TextColor3 = Color3.fromRGB(255, 105, 255)
	title.Text = "SINS"
	title.Parent = billboard

	prompt.Triggered:Connect(function(player)
		openRemote:FireClient(player)
	end)

	print("[SinAltarService] Started.")
end

return SinAltarService