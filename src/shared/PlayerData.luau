-- プレイヤーステータス管理モジュール（セッション中メモリのみ）

local Config = require(script.Parent.Config)

local PlayerData = {}

-- 内部ステータステーブル
local data = {
	DashPower     = Config.InitialStats.DashPower,
	JumpPower     = Config.InitialStats.JumpPower,
	FlightPower   = Config.InitialStats.FlightPower,
	MaxAltitude   = 0,
	Coins         = 0,
	CurrentPlanet = "Earth",
}

-- 現在のデータテーブルを返す（コピーで返すことで外部からの直接書き換えを防ぐ）
function PlayerData.getData(): { [string]: any }
	local copy = {}
	for k, v in pairs(data) do
		copy[k] = v
	end
	return copy
end

-- 指定ステータスに amount を加算する
function PlayerData.addPower(statName: string, amount: number)
	assert(data[statName] ~= nil, "PlayerData.addPower: 不明なステータス名: " .. tostring(statName))
	assert(type(amount) == "number", "PlayerData.addPower: amount は数値である必要があります")
	data[statName] = data[statName] + amount
end

-- 現在の進化段階を返す（0 = 初期、Config.EvolutionThresholds の数だけ段階が上がる）
function PlayerData.getEvolutionStage(): number
	local thresholds = Config.EvolutionThresholds
	local stage = 0
	for _, threshold in ipairs(thresholds) do
		if data.DashPower >= threshold then
			stage += 1
		else
			break
		end
	end
	return stage
end

-- 初期状態にリセット（テスト用）
function PlayerData.reset()
	data.DashPower     = Config.InitialStats.DashPower
	data.JumpPower     = Config.InitialStats.JumpPower
	data.FlightPower   = Config.InitialStats.FlightPower
	data.MaxAltitude   = 0
	data.Coins         = 0
	data.CurrentPlanet = "Earth"
end

return PlayerData
