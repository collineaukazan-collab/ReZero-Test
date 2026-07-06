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

GameConfig.RagdollMinAirTime = 0.35
GameConfig.RagdollMinFallDistance = 18
GameConfig.FallingVelocityToRagdoll = -22

GameConfig.CenterPullEnabled = true
GameConfig.CenterPullTargetRadius = 2
GameConfig.CenterPullSpeed = 22
GameConfig.CenterPullMaxForce = 2600

GameConfig.DynamicGroundDeathEnabled = true
GameConfig.DynamicGroundDeathMinSpeed = 80
GameConfig.DynamicGroundDeathMaxBonus = 45
GameConfig.DynamicGroundDeathSpeedMultiplier = 0.22

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

GameConfig.Audio = {
	MusicLibrary = {
		{
			Name = "Solarex",
			SoundId = "112802475655427",
		},

		{
			Name = "phonk",
			SoundId = "14145623221",
		},

		{
		 	Name = "",
		 	SoundId = "",
		},
	},

	-- Si MusicLibrary est vide, le script utilise cette ancienne liste.
	BackgroundTracks = {},

	-- true = musique suivante au hasard.
	-- false = ordre normal.
	BackgroundRandom = false,

	-- Loop par défaut quand le joueur rejoint.
	RadioDefaultLoop = false,

	MusicVolume = 0.6,

	DeathSoundId = "314390675",
	RespawnSoundId = "137385031681735",

	SfxVolume = 0.8,

	DelayBetweenBackgroundTracks = 1,
}

-- Compatibilité avec les anciens scripts.
GameConfig.RespawnSoundId = GameConfig.Audio.RespawnSoundId
GameConfig.DefaultMusicVolume = GameConfig.Audio.MusicVolume
GameConfig.DefaultSfxVolume = GameConfig.Audio.SfxVolume
GameConfig.MusicTracks = GameConfig.Audio.BackgroundTracks
GameConfig.MusicDelayBetweenTracks = GameConfig.Audio.DelayBetweenBackgroundTracks

GameConfig.DeathBlackScreenTime = 0.9
GameConfig.RespawnFadeOutTime = 0.45
GameConfig.FallDarkenTransparency = 0.25

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

	MinToSprint = 0,
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

	CollapsePushSpeed = 190,
	CollapseDownSpeed = -135,

	ScreenDarknessAtMax = 0.45,
	ShakeStartRatio = 0.9,
	ShakeAtMax = 0.025,
}

GameConfig.InsanityVisual = {
	StartRatio = 0.9,

	MaxZoomAmount = 3.5,

	EdgeDarknessAtMax = 0.82,
	EdgeSizeAtMax = 0.22,

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

GameConfig.TowerSandFloor = {
	Enabled = true,

	-- Zone de sable dans la tour.
	Center = GameConfig.StairCenter,
	Size = 170,

	-- Hauteur moyenne du sable.
	BaseY = 0,
	BottomY = -4,

	-- Plus le Step est petit, plus le relief est précis.
	Step = 6,

	-- Relief très léger.
	ReliefHeight = 1.15,
	BigReliefScale = 0.035,
	SmallReliefScale = 0.09,

	-- Zones plates pour éviter un spawn bancal.
	FlatSpawnRadius = 18,
	FlatStairRadius = 34,

	-- Position du spawn par rapport au centre de la tour.
	SpawnOffset = Vector3.new(-20, 0, -30),
	PlayerSpawnYOffset = 5,

	-- Efface seulement la petite zone de terrain de la tour avant de refaire le sable.
	ClearOldSandArea = true,
}

GameConfig.TowerSandstorm = {
	Enabled = true,

	Center = GameConfig.StairCenter,

	-- Taille de la mini tempête.
	Radius = 85,

	-- Hauteur des particules autour du joueur.
	HeightOffset = 0,

	-- Intensité.
	Rate = 10,

	-- Vitesse du vent.
	WindSpeed = 5,

	-- Taille des particules.
	ParticleMinSize = 5,
	ParticleMaxSize = 13,

	-- Couleur sable.
	Color = Color3.fromRGB(210, 178, 115),
}

return GameConfig
