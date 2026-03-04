-- サウンド管理モジュール（UIサウンドはSoundServiceに配置して2D再生）

local SoundService = game:GetService("SoundService")

local SoundManager = {}

-- サウンド定義
-- TODO: 各 SoundId を Roblox Marketplace の実際のアセットIDに差し替える
local SOUND_DEFS = {
	click     = { id = "rbxassetid://9120386458", volume = 0.3 },  -- 短いポン音
	evolution = { id = "rbxassetid://1369158732", volume = 0.5 },  -- ファンファーレ
	newRecord = { id = "rbxassetid://4612355532", volume = 0.4 },  -- チャイム
	landing   = { id = "rbxassetid://130113322",  volume = 0.3 },  -- 着地ドン
	rebirth   = { id = "rbxassetid://1369158732", volume = 0.8 },  -- リバース（華やかな音）
	purchase  = { id = "rbxassetid://9120386458", volume = 0.5 },  -- 購入チャリン音
}

local sounds = {} :: { [string]: Sound }

function SoundManager.init()
	for name, def in pairs(SOUND_DEFS) do
		local s = Instance.new("Sound")
		s.Name       = "GameSound_" .. name
		s.SoundId    = def.id
		s.Volume     = def.volume
		s.RollOffMaxDistance = 0  -- 距離減衰なし（2D再生）
		s.Parent     = SoundService
		sounds[name] = s
	end
end

function SoundManager.playClick()
	if sounds.click then sounds.click:Play() end
end

function SoundManager.playEvolution()
	if sounds.evolution then sounds.evolution:Play() end
end

function SoundManager.playNewRecord()
	if sounds.newRecord then sounds.newRecord:Play() end
end

function SoundManager.playLanding()
	if sounds.landing then sounds.landing:Play() end
end

function SoundManager.playRebirth()
	if sounds.rebirth then sounds.rebirth:Play() end
end

function SoundManager.playPurchase()
	if sounds.purchase then sounds.purchase:Play() end
end

return SoundManager
