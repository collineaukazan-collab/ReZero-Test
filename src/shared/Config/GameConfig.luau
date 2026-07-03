local GameConfig = {}

GameConfig.SpawnPosition = Vector3.new(0, 5, 0)
GameConfig.SpawnPlatformPosition = Vector3.new(0, 0, 0)

-- Centre réel de l'escalier.
-- Si ton escalier n'est pas centré en X=0, Z=0, change ces valeurs.
GameConfig.StairCenter = Vector3.new(-70, 0, 0)

GameConfig.StairSegmentHeight = 180
GameConfig.MoneyPerStud = 1
GameConfig.DefaultMoneyMultiplier = 1

GameConfig.HeightUpdateInterval = 0.08
GameConfig.ClientRenderUpdateInterval = 0.25

GameConfig.FallDeathY = -25
GameConfig.GroundDeathY = 7
GameConfig.MaxRagdollFallTime = 100

GameConfig.MinimumStudsBeforeFallKill = 15

GameConfig.RagdollMinAirTime = 0.35
GameConfig.RagdollMinFallDistance = 18
GameConfig.FallingVelocityToRagdoll = -22

-- Attraction vers le centre de l'escalier.
-- Elle est volontairement faible mais constante.
GameConfig.CenterPullEnabled = true
GameConfig.CenterPullStartRadius = 6
GameConfig.CenterPullTargetRadius = 2
GameConfig.CenterPullSpeed = 22
GameConfig.CenterPullMaxForce = 2600

GameConfig.DefaultQuality = "Medium"

GameConfig.QualitySettings = {
	Low = {
		RenderDistanceAbove = 450,
		RenderDistanceBelow = 450,
	},

	Medium = {
		RenderDistanceAbove = 900,
		RenderDistanceBelow = 900,
	},

	High = {
		RenderDistanceAbove = 1600,
		RenderDistanceBelow = 1600,
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
GameConfig.MaxImpactMarks = 40
GameConfig.MaxPersistentCorpses = 8

GameConfig.Insanity = {
	Max = 100,

	BaseGainPerSecond = 1.2,
	GainPerFloorPerSecond = 0.35,
	DecayPerSecondAtFloorZero = 25,

	FullDurationBeforeCollapse = 1,

	CollapsePushSpeed = 85,
	CollapseDownSpeed = -35,

	ScreenDarknessAtMax = 0.45,
	ShakeStartRatio = 0.8,
	ShakeAtMax = 0.5,
}

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