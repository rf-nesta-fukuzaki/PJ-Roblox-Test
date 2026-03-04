-- サウンド管理モジュール（UIサウンドはSoundServiceに配置して2D再生）

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local SoundManager = {}

-- サウンド定義
local SOUND_DEFS = {
	click     = { id = "rbxassetid://9120386458", volume = 0.3,  looped = false },
	evolution = { id = "rbxassetid://1369158732", volume = 0.5,  looped = false },
	newRecord = { id = "rbxassetid://4612355532", volume = 0.4,  looped = false },
	landing   = { id = "rbxassetid://130113322",  volume = 0.3,  looped = false },
	rebirth   = { id = "rbxassetid://1369158732", volume = 0.8,  looped = false },
	purchase  = { id = "rbxassetid://9120386458", volume = 0.5,  looped = false },
	combo     = { id = "rbxassetid://9120386458", volume = 0.4,  looped = false },
	fanfare   = { id = "rbxassetid://1369158732", volume = 1.0,  looped = false },
	bgm       = { id = "rbxassetid://1837849285", volume = 0.1,  looped = true  },
}

local sounds = {} :: { [string]: Sound }

function SoundManager.init()
	for name, def in pairs(SOUND_DEFS) do
		local s = Instance.new("Sound")
		s.Name               = "GameSound_" .. name
		s.SoundId            = def.id
		s.Volume             = def.volume
		s.Looped             = def.looped
		s.RollOffMaxDistance = 0
		s.Parent             = SoundService
		sounds[name]         = s
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

function SoundManager.playCombo()
	local s = sounds.combo
	if s then
		s.PlaybackSpeed = 1.3
		s:Play()
		s.PlaybackSpeed = 1
	end
end

function SoundManager.playBGM()
	local s = sounds.bgm
	if s and not s.IsPlaying then
		-- 音量 0 から開始し、3秒かけて 0.1 にフェードイン
		s.Volume = 0
		s:Play()
		TweenService:Create(s, TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Volume = 0.1 }):Play()
	end
end

-- リバース時のファンファーレ（BGMを 0.5秒フェードアウト→ファンファーレ→1秒後BGM復帰）
function SoundManager.playFanfare()
	local bgm     = sounds.bgm
	local fanfare = sounds.fanfare
	if not fanfare then return end

	task.spawn(function()
		-- BGM を 0.5秒でフェードアウトして一時停止
		if bgm and bgm.IsPlaying then
			TweenService:Create(bgm, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { Volume = 0 }):Play()
			task.wait(0.5)
			bgm:Pause()
		end

		fanfare:Play()
		fanfare.Ended:Wait()

		-- 1秒待ってから BGM を 0.1 にフェードインして再生
		task.wait(1)
		if bgm then
			bgm.Volume = 0
			bgm:Resume()
			TweenService:Create(bgm, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Volume = 0.1 }):Play()
		end
	end)
end

return SoundManager
