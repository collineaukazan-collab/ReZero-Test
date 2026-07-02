local GameConfig = {}

GameConfig.SpawnPosition = Vector3.new(0, 5, 0)
GameConfig.SpawnPlatformPosition = Vector3.new(0, 0, 0)

GameConfig.StairSegmentHeight = 180
GameConfig.MoneyPerStud = 1
GameConfig.DefaultMoneyMultiplier = 1

GameConfig.HeightUpdateInterval = 0.2
GameConfig.ClientRenderUpdateInterval = 0.25

GameConfig.FallDeathY = -120
GameConfig.KillWhenOutsideTowerRadius = true
GameConfig.TowerSafeRadius = 95
GameConfig.MinimumStudsBeforeFallKill = 25

GameConfig.DefaultQuality = "Medium"

GameConfig.QualitySettings = {
Low = {
RenderDistance = 400,
},

Medium = {
RenderDistance = 900,
},

High = {
RenderDistance = 1600,
},
}

GameConfig.QualityOrder = { "Low", "Medium", "High" }

GameConfig.DataStoreName = "ReZeroLoopData_v1"

GameConfig.DeathFadeDuration = 0.35
GameConfig.DeathBlackScreenTime = 0.65
GameConfig.RespawnSoundId = "rbxassetid://0"

GameConfig.Atmosphere = {
Brightness = 0.7,
Ambient = Color3.fromRGB(18, 18, 24),
OutdoorAmbient = Color3.fromRGB(5, 5, 8),
FogColor = Color3.fromRGB(10, 10, 14),
FogStart = 25,
FogEnd = 280,
ClockTime = 0,
}

return GameConfig
