-- プレイヤーステータス管理モジュール（セッション中メモリのみ）

local Config = require(script.Parent.Config)

local PlayerData = {}

-- 内部ステータステーブル
local data = {
	JumpPower       = Config.InitialStats.JumpPower,
	Speed           = Config.InitialStats.Speed,
	PowerGauge      = Config.InitialStats.PowerGauge,
	Coins           = Config.InitialStats.Coins,
	RebirthCount    = Config.InitialStats.RebirthCount,
	TotalDistance   = Config.InitialStats.TotalDistance,
	EquippedShoes   = "starter",
	EquippedTrail   = "none",
	MaxAltitude     = 0,
	OwnedShoes      = { "starter" },
	OwnedTrails     = { "none" },
	boostMultiplier = 1,
}

-- 現在のデータテーブルを返す（配列フィールドも含めてコピー）
function PlayerData.getData(): { [string]: any }
	local copy = {}
	for k, v in pairs(data) do
		copy[k] = v
	end
	-- 配列フィールドは中身もコピー
	copy.OwnedShoes = {}
	for i, v in ipairs(data.OwnedShoes) do
		copy.OwnedShoes[i] = v
	end
	copy.OwnedTrails = {}
	for i, v in ipairs(data.OwnedTrails) do
		copy.OwnedTrails[i] = v
	end
	return copy
end

-- 指定ステータスに amount を加算する
function PlayerData.addPower(statName: string, amount: number)
	assert(data[statName] ~= nil, "PlayerData.addPower: 不明なステータス名: " .. tostring(statName))
	assert(type(amount) == "number", "PlayerData.addPower: amount は数値である必要があります")
	data[statName] = data[statName] + amount
end

-- 現在の進化段階を返す（JumpPower基準）
function PlayerData.getEvolutionStage(): number
	local thresholds = Config.EvolutionThresholds
	local stage = 0
	for _, threshold in ipairs(thresholds) do
		if data.JumpPower >= threshold then
			stage += 1
		else
			break
		end
	end
	return stage
end

-- 最高高度を更新する。更新した場合は true、しなければ false を返す
function PlayerData.updateMaxAltitude(altitude: number): boolean
	if altitude > data.MaxAltitude then
		data.MaxAltitude = altitude
		return true
	end
	return false
end

-- Coins/RebirthCount/OwnedShoes/OwnedTrails/MaxAltitude を保持しつつリセット
function PlayerData.reset()
	data.JumpPower     = Config.InitialStats.JumpPower
	data.Speed         = Config.InitialStats.Speed
	data.PowerGauge    = Config.InitialStats.PowerGauge
	data.TotalDistance = Config.InitialStats.TotalDistance
	-- Coins, RebirthCount, OwnedShoes, OwnedTrails, MaxAltitude は保持
end

-- ===== 装備ボーナス計算 =====

-- クリック1回あたりのJumpPower成長量（シューズ＋リバースボーナス＋ブーストマルチプライヤー込み）
function PlayerData.getEffectiveClickPower(): number
	local shoes = Config.Shoes[data.EquippedShoes]
	local clickBonus = shoes and shoes.clickBonus or 0
	local base = Config.Click.BasePerClick
		+ clickBonus
		+ data.RebirthCount * Config.Rebirth.ClickBonusPerRebirth
	return base * data.boostMultiplier
end

-- ブーストマルチプライヤーの設定・取得（RandomEventsから呼ばれる）
function PlayerData.setBoostMultiplier(mult: number)
	data.boostMultiplier = mult
end

function PlayerData.getBoostMultiplier(): number
	return data.boostMultiplier
end

-- 走行距離1スタッドあたりのSpeed成長量（シューズ＋リバースボーナス込み）
function PlayerData.getEffectiveRunPower(): number
	local shoes = Config.Shoes[data.EquippedShoes]
	local runBonus = shoes and shoes.runBonus or 0
	return Config.Running.SpeedPerDistance
		+ runBonus
		+ data.RebirthCount * Config.Rebirth.SpeedBonusPerRebirth
end

-- ===== 走行距離加算 =====

function PlayerData.addDistance(distance: number)
	data.TotalDistance = data.TotalDistance + distance
	data.Speed         = data.Speed + distance * PlayerData.getEffectiveRunPower()
	data.PowerGauge    = data.PowerGauge + distance * Config.Running.PowerPerDistance
end

-- ===== リバース =====

function PlayerData.canRebirth(): boolean
	return data.PowerGauge >= Config.Rebirth.MinPowerGauge
end

function PlayerData.doRebirth(): { coins: number, newRebirthCount: number }
	local earned = math.floor(data.PowerGauge * Config.Rebirth.CoinsPerPower)
	data.Coins         = data.Coins + earned
	data.RebirthCount  = data.RebirthCount + 1
	data.JumpPower     = 0
	data.Speed         = 0
	data.PowerGauge    = 0
	data.TotalDistance = 0
	data.MaxAltitude   = 0
	-- EquippedShoes / EquippedTrail はリセットしない
	return { coins = earned, newRebirthCount = data.RebirthCount }
end

-- ===== ショップ（シューズ）=====

function PlayerData.hasShoes(id: string): boolean
	return table.find(data.OwnedShoes, id) ~= nil
end

function PlayerData.buyShoes(id: string): boolean
	local shoes = Config.Shoes[id]
	if not shoes then return false end
	if PlayerData.hasShoes(id) then return false end
	if data.Coins < shoes.cost then return false end
	data.Coins = data.Coins - shoes.cost
	table.insert(data.OwnedShoes, id)
	return true
end

function PlayerData.equipShoes(id: string): boolean
	if not PlayerData.hasShoes(id) then return false end
	data.EquippedShoes = id
	return true
end

-- ===== ショップ（トレイル）=====

function PlayerData.hasTrail(id: string): boolean
	return table.find(data.OwnedTrails, id) ~= nil
end

function PlayerData.buyTrail(id: string): boolean
	local trail = Config.Trails[id]
	if not trail then return false end
	if PlayerData.hasTrail(id) then return false end
	if data.Coins < trail.cost then return false end
	data.Coins = data.Coins - trail.cost
	table.insert(data.OwnedTrails, id)
	return true
end

function PlayerData.equipTrail(id: string): boolean
	if not PlayerData.hasTrail(id) then return false end
	data.EquippedTrail = id
	return true
end

return PlayerData
