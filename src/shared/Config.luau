-- ゲームバランス定数

local Config = {}

-- ===== 初期ステータス =====
Config.InitialStats = {
	JumpPower      = 0,
	Speed          = 0,
	PowerGauge     = 0,
	Coins          = 0,
	RebirthCount   = 0,
	TotalDistance  = 0,
	EquippedShoes  = "none",
	EquippedTrail  = "none",
}

-- ===== クリック育成（ジャンプ力）=====
Config.Click = {
	BasePerClick = 3,
}

-- ===== 走行距離育成（スピード）=====
Config.Running = {
	SpeedPerDistance  = 0.1,
	PowerPerDistance  = 0.05,
}

-- ===== ジャンプ力反映 =====
Config.Jump = {
	Base       = 50,
	Multiplier = 0.15,
	Max        = 400,
}

-- ===== スピード反映 =====
Config.Speed = {
	Base       = 16,
	Multiplier = 0.08,
	Max        = 120,
}

-- ===== 進化段階（JumpPower基準）=====
Config.EvolutionThresholds = { 50, 200, 800, 3000, 15000 }

-- ===== リバース =====
Config.Rebirth = {
	CoinsPerPower          = 0.1,
	ClickBonusPerRebirth   = 0.5,
	SpeedBonusPerRebirth   = 0.02,
	MinPowerGauge          = 100,
}

-- ===== ショップ（シューズ）=====
Config.Shoes = {
	starter = {
		name        = "スターターシューズ",
		cost        = 0,
		clickBonus  = 0,
		runBonus    = 0,
		description = "最初の一足。",
	},
	runner = {
		name        = "🏃 ランナーシューズ",
		cost        = 50,
		clickBonus  = 1,
		runBonus    = 0.05,
		description = "走るのが少し楽しくなる。",
	},
	springs = {
		name        = "🦘 スプリングシューズ",
		cost        = 200,
		clickBonus  = 3,
		runBonus    = 0.1,
		description = "バネの力でジャンプ力UP！",
	},
	rocket = {
		name        = "🚀 ロケットシューズ",
		cost        = 1000,
		clickBonus  = 8,
		runBonus    = 0.3,
		description = "宇宙を目指す者のための一足。",
	},
	legendary = {
		name        = "👑 レジェンダリーシューズ",
		cost        = 5000,
		clickBonus  = 20,
		runBonus    = 1.0,
		description = "伝説の靴。全てが加速する。",
	},
	galaxy = {
		name        = "🌌 ギャラクシーシューズ",
		cost        = 25000,
		clickBonus  = 50,
		runBonus    = 3.0,
		description = "銀河を駆ける者だけが履ける。",
	},
}
Config.ShoesOrder = { "starter", "runner", "springs", "rocket", "legendary", "galaxy" }

-- ===== トレイル（見た目装備）=====
Config.Trails = {
	none    = { name = "なし",              cost = 0,     description = "トレイルなし" },
	fire    = { name = "🔥 炎トレイル",     cost = 100,   description = "足元に炎が走る" },
	ice     = { name = "❄️ 氷トレイル",    cost = 300,   description = "氷の結晶が散る" },
	star    = { name = "⭐ 星トレイル",     cost = 800,   description = "星の軌跡を残す" },
	rainbow = { name = "🌈 虹トレイル",     cost = 2000,  description = "虹色の光が溢れる" },
	galaxy  = { name = "🌌 銀河トレイル",   cost = 10000, description = "銀河を纏う" },
}
Config.TrailsOrder = { "none", "fire", "ice", "star", "rainbow", "galaxy" }

-- ===== トレーニングゾーンの範囲（参照用に保持）=====
Config.TrainingZoneBounds = {
	MinX = -30, MaxX = 30,
	MinZ =  20, MaxZ = 60,
	MinY =  -5, MaxY = 20,
}

-- ===== リバースゾーンの範囲 =====
Config.RebirthZoneBounds = {
	MinX = -50, MaxX = -30,
	MinZ = -12, MaxZ = 12,
	MinY =  -5, MaxY = 20,
}

-- ===== ショップゾーンの範囲 =====
Config.ShopZoneBounds = {
	MinX =  40, MaxX =  70,
	MinZ = -12, MaxZ =  12,
	MinY =  -5, MaxY =  20,
}

return Config
