local GameConfig = {}

-- Centre réel de l'escalier.
-- Si ton escalier n'est pas centré ici, change X/Z.
GameConfig.StairCenter = Vector3.new(-70, 0, 0)

-- Spawn par rapport au centre de l'escalier.
GameConfig.SpawnOffsetFromStair = Vector3.new(-20, 0, -30)
GameConfig.SpawnPosition = GameConfig.StairCenter + GameConfig.SpawnOffsetFromStair

GameConfig.StairSegmentHeight = 180
GameConfig.MoneyPerStud = 1
GameConfig.DefaultMoneyMultiplier = 1

GameConfig.HeightUpdateInterval = 0.08
GameConfig.ClientRenderUpdateInterval = 0.25

GameConfig.FallDeathY = -25
GameConfig.GroundDeathY = 7
GameConfig.MaxRagdollFallTime = 100

GameConfig.MinimumStudsBeforeFallKill = 15

-- Déclenchement du ragdoll.
GameConfig.RagdollMinAirTime = 0.35
GameConfig.RagdollMinFallDistance = 18
GameConfig.FallingVelocityToRagdoll = -22

-- Attraction vers le centre de l'escalier.
GameConfig.CenterPullEnabled = true
GameConfig.CenterPullTargetRadius = 2
GameConfig.CenterPullSpeed = 22
GameConfig.CenterPullMaxForce = 2600

-- Écran noir/mort plus tôt si le corps tombe très vite.
GameConfig.DynamicGroundDeathEnabled = true
GameConfig.DynamicGroundDeathMinSpeed = 80
GameConfig.DynamicGroundDeathMaxBonus = 45
GameConfig.DynamicGroundDeathSpeedMultiplier = 0.22

-- Chute contrôlable.
GameConfig.FallAccelerationEnabled = true
GameConfig.FallAcceleration = 120
GameConfig.MaxFallSpeed = -420

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

GameConfig.RespawnSoundId = "137385031681735"

GameConfig.DeathBlackScreenTime = 0.9
GameConfig.RespawnFadeOutTime = 0.45
GameConfig.FallDarkenTransparency = 0.25

GameConfig.DefaultMusicVolume = 0.6
GameConfig.DefaultSfxVolume = 0.8

GameConfig.DefaultImpactMarksEnabled = true
GameConfig.MaxImpactMarks = 40
GameConfig.MaxPersistentCorpses = 8

GameConfig.Stamina = {
	Max = 100,

	WalkSpeed = 18,
	SprintSpeed = 29,

	DrainPerSecond = 24,
	RegenPerSecond = 18,
	RegenDelay = 0.75,

	-- Tu peux laisser à 0.
	MinToSprint = 0,

	-- Quand la stamina tombe à 0, il faut attendre cette valeur avant de recourir.
	RecoverToSprint = 18,
}

GameConfig.Rest = {
	DrainPerSecond = 28,
	DisableJump = true,
}

GameConfig.Insanity = {
	Max = 100,

	BaseGainPerSecond = 5,
	GainPerFloorPerSecond = 1,
	DecayPerSecondAtFloorZero = 25,

	FullDurationBeforeCollapse = 1,

	-- Poussée quand l'insanity arrive à 100.
	CollapsePushSpeed = 190,
	CollapseDownSpeed = -135,

	-- Anciennes valeurs gardées pour compatibilité avec d'autres fichiers.
	ScreenDarknessAtMax = 0.45,
	ShakeStartRatio = 0.9,
	ShakeAtMax = 0.025,
}

GameConfig.InsanityVisual = {
	-- L'effet visuel commence seulement au-dessus de 90%.
	StartRatio = 0.9,

	-- Petit zoom propre.
	MaxZoomAmount = 3.5,

	-- Contours noirs.
	EdgeDarknessAtMax = 0.82,
	EdgeSizeAtMax = 0.22,

	-- Très légère vibration au-dessus de 90%.
	ShakeStartRatio = 0.9,
	ShakeAtMax = 0.025,
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

GameConfig.MusicTracks = {
	-- Mets tes vrais IDs Roblox audio ici.
	-- Exemple :
	-- "rbxassetid://1234567890",
	-- "rbxassetid://9876543210",
}

GameConfig.MusicFadeTime = 1
GameConfig.MusicDelayBetweenTracks = 1

return GameConfig