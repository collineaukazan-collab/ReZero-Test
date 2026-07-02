local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local DeathEffectsController = {}

local localPlayer = Players.LocalPlayer

local screenGui = nil
local blackFrame = nil
local deathSound = nil

local function createGui()
local playerGui = localPlayer:WaitForChild("PlayerGui")

screenGui = playerGui:FindFirstChild("DeathEffectsGui")
if screenGui then
screenGui:Destroy()
end

screenGui = Instance.new("ScreenGui")
screenGui.Name = "DeathEffectsGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 999
screenGui.Parent = playerGui

blackFrame = Instance.new("Frame")
blackFrame.Name = "BlackFrame"
blackFrame.Size = UDim2.fromScale(1, 1)
blackFrame.Position = UDim2.fromScale(0, 0)
blackFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
blackFrame.BackgroundTransparency = 1
blackFrame.Parent = screenGui

deathSound = Instance.new("Sound")
deathSound.Name = "DeathRespawnSound"
deathSound.SoundId = GameConfig.RespawnSoundId
deathSound.Volume = 0.8
deathSound.Parent = SoundService
end

local function playDeathEffect()
if not blackFrame then
return
end

if deathSound and deathSound.SoundId ~= "" and deathSound.SoundId ~= "rbxassetid://0" then
deathSound:Play()
end

local fadeIn = TweenService:Create(
blackFrame,
TweenInfo.new(GameConfig.DeathFadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
{ BackgroundTransparency = 0 }
)

fadeIn:Play()
fadeIn.Completed:Wait()

task.wait(GameConfig.DeathBlackScreenTime)

local fadeOut = TweenService:Create(
blackFrame,
TweenInfo.new(GameConfig.DeathFadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
{ BackgroundTransparency = 1 }
)

fadeOut:Play()
end

local function setupCharacter(character)
local humanoid = character:WaitForChild("Humanoid", 10)
if not humanoid then
return
end

humanoid.Died:Connect(function()
task.spawn(playDeathEffect)
end)
end

function DeathEffectsController:Start()
createGui()

localPlayer.CharacterAdded:Connect(function(character)
setupCharacter(character)
end)

if localPlayer.Character then
setupCharacter(localPlayer.Character)
end
end

return DeathEffectsController
