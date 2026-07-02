local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local AtmosphereController = {}

function AtmosphereController:Start()
local atmosphereConfig = GameConfig.Atmosphere

Lighting.Brightness = atmosphereConfig.Brightness
Lighting.Ambient = atmosphereConfig.Ambient
Lighting.OutdoorAmbient = atmosphereConfig.OutdoorAmbient
Lighting.FogColor = atmosphereConfig.FogColor
Lighting.FogStart = atmosphereConfig.FogStart
Lighting.FogEnd = atmosphereConfig.FogEnd
Lighting.ClockTime = atmosphereConfig.ClockTime

local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
if not atmosphere then
atmosphere = Instance.new("Atmosphere")
atmosphere.Parent = Lighting
end

atmosphere.Density = 0.15
atmosphere.Offset = 0.15
atmosphere.Color = Color3.fromRGB(80, 80, 95)
atmosphere.Decay = Color3.fromRGB(12, 12, 18)
atmosphere.Glare = 0
atmosphere.Haze = 2.2

local colorCorrection = Lighting:FindFirstChild("DarkTowerColorCorrection")
if not colorCorrection then
colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Name = "DarkTowerColorCorrection"
colorCorrection.Parent = Lighting
end

colorCorrection.Brightness = 0.25
colorCorrection.Contrast = 0.25
colorCorrection.Saturation = -0.15
colorCorrection.TintColor = Color3.fromRGB(205, 210, 230)
end

return AtmosphereController
