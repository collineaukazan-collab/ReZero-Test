local GameConfig = {}

GameConfig.SpawnPosition = Vector3.new(0, 5, 0)
GameConfig.SpawnPlatformPosition = Vector3.new(0, 0, 0)

GameConfig.StairSegmentHeight = 180
GameConfig.MoneyPerStud = 1
GameConfig.DefaultMoneyMultiplier = 1

GameConfig.HeightUpdateInterval = 0.2
GameConfig.ClientRenderUpdateInterval = 0.25

GameConfig.FallDeathY = -80
GameConfig.KillWhenOutsideTowerRadius = true
GameConfig.TowerSafeRadius = 85
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

return GameConfig
