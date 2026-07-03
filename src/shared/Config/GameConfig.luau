local GameConfig = {}

GameConfig.SpawnPosition = Vector3.new(0, 5, 0)
GameConfig.SpawnPlatformPosition = Vector3.new(0, 0, 0)

GameConfig.StairSegmentHeight = 180
GameConfig.MoneyPerStud = 1
GameConfig.DefaultMoneyMultiplier = 1

GameConfig.HeightUpdateInterval = 0.08
GameConfig.ClientRenderUpdateInterval = 0.25

GameConfig.FallDeathY = -25
GameConfig.GroundDeathY = 7
GameConfig.MaxRagdollFallTime = 8

GameConfig.KillWhenOutsideTowerRadius = true
GameConfig.TowerSafeRadius = 140
GameConfig.MinimumStudsBeforeFallKill = 15

-- Ragdoll uniquement après une vraie chute, pas un simple saut.
GameConfig.RagdollMinAirTime = 0.45
GameConfig.RagdollMinFallDistance = 28
GameConfig.FallingVelocityToRagdoll = -22

-- Ramène doucement le corps vers le centre sans bloquer les membres.
GameConfig.CenterPullEnabled = true
GameConfig.CenterPullStartRadius = 28
GameConfig.CenterPullStrength = 75
GameConfig.CenterPullMaxForce = 8500

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

GameConfig.RespawnSoundId = ""

GameConfig.DeathBlackScreenTime = 0.9
GameConfig.RespawnFadeOutTime = 0.45
GameConfig.FallDarkenTransparency = 0.55

GameConfig.DefaultMusicVolume = 0.6
GameConfig.DefaultSfxVolume = 0.8

GameConfig.DefaultImpactMarksEnabled = true
GameConfig.MaxImpactMarks = 35
GameConfig.MaxPersistentCorpses = 8

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