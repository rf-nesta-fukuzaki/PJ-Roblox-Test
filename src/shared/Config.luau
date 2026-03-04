-- ゲームバランス定数

local Config = {}

-- 初期ステータス値
Config.InitialStats = {
	DashPower   = 0,
	JumpPower   = 0,
	FlightPower = 0,
}

-- クリックあたりの成長量
Config.PowerPerClick = {
	DashPower   = 1,
	JumpPower   = 1,
	FlightPower = 1,
}

-- 進化段階の閾値（DashPower基準）
Config.EvolutionThresholds = { 100, 500, 2000, 10000, 50000 }

-- 惑星アンロックに必要な到達高度
Config.PlanetAltitude = {
	Moon   = 1000,
	Mars   = 5000,
	Saturn = 20000,
}

return Config
