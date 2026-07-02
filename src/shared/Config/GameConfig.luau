local GameConfig = {}

GameConfig.SpawnPosition = Vector3.new(0, 5, 0)
GameConfig.SpawnPlatformPosition = Vector3.new(0, 0, 0)

GameConfig.StairSegmentHeight = 180
GameConfig.MoneyPerStud = 1
GameConfig.DefaultMoneyMultiplier = 1

GameConfig.HeightUpdateInterval = 0.1
GameConfig.ClientRenderUpdateInterval = 0.25

GameConfig.FallDeathY = -25
GameConfig.GroundDeathY = 5

GameConfig.KillWhenOutsideTowerRadius = true
GameConfig.TowerSafeRadius = 140
GameConfig.MinimumStudsBeforeFallKill = 20

GameConfig.FallingVelocityToRagdoll = -28
GameConfig.FallingHeightLossToRagdoll = 8

GameConfig.DefaultQuality = "Medium"

GameConfig.QualitySettings = {
	Low = {
		RenderDistanceAbove = 450,
		RenderDistanceBelow = 180,
	},

	Medium = {
		RenderDistanceAbove = 900,
		RenderDistanceBelow = 360,
	},

	High = {
		RenderDistanceAbove = 1600,
		RenderDistanceBelow = 720,
	},
}

GameConfig.QualityOrder = { "Low", "Medium", "High" }

GameConfig.DataStoreName = "ReZeroLoopData_v1"

GameConfig.DeathFadeDuration = 0.35
GameConfig.DeathBlackScreenTime = 0.75

GameConfig.RespawnSoundId = "rbxassetid://0"

GameConfig.DefaultMusicVolume = 0.6
GameConfig.DefaultSfxVolume = 0.8

GameConfig.Character = {
	WalkSpeed = 18,
	JumpPower = 55,
	JumpHeight = 7.2,
	HipHeight = 2.2,
	MaxSlopeAngle = 70,
}

GameConfig.Atmosphere = {
	Brightness = 0.75,
	Ambient = Color3.fromRGB(28, 28, 38),
	OutdoorAmbient = Color3.fromRGB(8, 8, 14),
	FogColor = Color3.fromRGB(10, 10, 18),
	FogStart = 60,
	FogEnd = 420,
	ClockTime = 0,
}

return GameConfig