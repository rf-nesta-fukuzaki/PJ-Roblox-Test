-- ゲームバランス定数

local Config = {}

-- 初期ステータス値
Config.InitialStats = {
	JumpPower = 0,
	Speed     = 0,
}

-- クリックあたりの成長量
Config.PowerPerClick = {
	JumpPower = 1,
	Speed     = 1,
}

-- 進化段階の閾値（JumpPower基準）
Config.EvolutionThresholds = { 100, 500, 2000, 10000, 50000 }

-- ジャンプ力の計算パラメータ
Config.Jump = {
	Base       = 50,   -- 初期ジャンプ力
	Multiplier = 0.1,  -- JumpPower 1あたりの加算値
	Max        = 400,  -- 上限
}

-- スピードの計算パラメータ
Config.Speed = {
	Base       = 16,   -- 初期移動速度
	Multiplier = 0.05, -- Speed 1あたりの加算値
	Max        = 120,  -- 上限
}

-- トレーニングゾーンの範囲（Phase 5で使用）
Config.TrainingZoneBounds = {
	MinX = -30, MaxX = 30,
	MinZ =  20, MaxZ = 60,
	MinY =  -5, MaxY = 20,
}

return Config
