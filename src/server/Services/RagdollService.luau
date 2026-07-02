local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local RagdollService = {}

local function setCharacterRagdoll(character)
local humanoid = character:FindFirstChildOfClass("Humanoid")
if not humanoid then
return
end

humanoid.BreakJointsOnDeath = false
humanoid.RequiresNeck = false

for _, descendant in ipairs(character:GetDescendants()) do
if descendant:IsA("Motor6D") then
local part0 = descendant.Part0
local part1 = descendant.Part1

if part0 and part1 then
local attachment0 = Instance.new("Attachment")
attachment0.Name = descendant.Name .. "_RagdollAttachment0"
attachment0.CFrame = descendant.C0
attachment0.Parent = part0

local attachment1 = Instance.new("Attachment")
attachment1.Name = descendant.Name .. "_RagdollAttachment1"
attachment1.CFrame = descendant.C1
attachment1.Parent = part1

local constraint = Instance.new("BallSocketConstraint")
constraint.Name = descendant.Name .. "_RagdollConstraint"
constraint.Attachment0 = attachment0
constraint.Attachment1 = attachment1
constraint.LimitsEnabled = true
constraint.TwistLimitsEnabled = true
constraint.UpperAngle = 45
constraint.TwistLowerAngle = -45
constraint.TwistUpperAngle = 45
constraint.Parent = part0

descendant.Enabled = false
end
elseif descendant:IsA("BasePart") then
descendant.CanCollide = true
end
end

humanoid:ChangeState(Enum.HumanoidStateType.Physics)
end

local function setupCharacter(character)
local humanoid = character:WaitForChild("Humanoid", 10)
if not humanoid then
return
end

humanoid.BreakJointsOnDeath = false
humanoid.RequiresNeck = false
end

function RagdollService:RagdollPlayer(player)
local character = player.Character
if not character then
return
end

if character:GetAttribute("IsRagdolled") then
return
end

character:SetAttribute("IsRagdolled", true)
setCharacterRagdoll(character)
end

function RagdollService:Start()
Players.PlayerAdded:Connect(function(player)
player.CharacterAdded:Connect(function(character)
setupCharacter(character)
end)
end)

for _, player in ipairs(Players:GetPlayers()) do
if player.Character then
setupCharacter(player.Character)
end
end
end

return RagdollService
