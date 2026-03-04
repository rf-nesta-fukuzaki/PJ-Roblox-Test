-- リバースステーションUI

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local PlayerData         = require(ReplicatedStorage.Shared.PlayerData)
local Config             = require(ReplicatedStorage.Shared.Config)
local Format             = require(ReplicatedStorage.Shared.Format)
local MiniHUD            = require(script.Parent.MiniHUD)
local SoundManager       = require(script.Parent.SoundManager)
local MovementController = require(script.Parent.MovementController)
local Effects            = require(script.Parent.Effects)

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local RebirthUI = {}

-- リーダーボード更新用RemoteEvent（非同期取得）
local updateLeaderboardRE = nil :: RemoteEvent?
task.spawn(function()
	updateLeaderboardRE = ReplicatedStorage:WaitForChild("UpdateLeaderboard") :: RemoteEvent
end)

-- ─────────────────────────────────────────
-- 内部参照
-- ─────────────────────────────────────────
local screenGui        = nil :: ScreenGui?
local mainPanel        = nil :: Frame?
local powerLabel       = nil :: TextLabel?
local coinPreviewLabel = nil :: TextLabel?
local rebirthBtn       = nil :: TextButton?
local bonusLabel       = nil :: TextLabel?
local flashFrame       = nil :: Frame?
local resultLabel      = nil :: TextLabel?
local progressFill     = nil :: Frame?
local progressLabel    = nil :: TextLabel?

-- ─────────────────────────────────────────
-- スライドアニメーション定数
-- ─────────────────────────────────────────
local PANEL_CENTER  = UDim2.new(0.5, 0, 0.5, 0)
local PANEL_OFFBOT  = UDim2.new(0.5, 0, 1.5, 0)

-- ─────────────────────────────────────────
-- ヘルパー
-- ─────────────────────────────────────────

local function refreshPanel()
	local d      = PlayerData.getData()
	local power  = math.floor(d.PowerGauge)
	local earned = math.floor(power * Config.Rebirth.CoinsPerPower)
	local canDo  = PlayerData.canRebirth()
	local minPG  = Config.Rebirth.MinPowerGauge

	powerLabel.Text       = "⚡ パワー: " .. Format.commaNumber(power)
	coinPreviewLabel.Text = "→ 💰 " .. Format.commaNumber(earned) .. " コイン獲得！"

	local nextCount  = (d.RebirthCount :: number) + 1
	local clickBonus = nextCount * Config.Rebirth.ClickBonusPerRebirth
	local speedBonus = nextCount * Config.Rebirth.SpeedBonusPerRebirth
	bonusLabel.Text = "次のリバースで: クリック+" .. clickBonus .. ", 走行効率+" .. speedBonus

	-- 進捗バー更新
	if progressFill and progressLabel then
		local ratio  = math.min(power / minPG, 1)
		progressFill.Size = UDim2.new(ratio, 0, 1, 0)
		local percent = math.floor(ratio * 1000) / 10  -- 小数点1桁
		progressLabel.Text = Format.commaNumber(power) .. " / " .. Format.commaNumber(minPG)
			.. " (" .. percent .. "%)"
	end

	if canDo then
		rebirthBtn.BackgroundColor3 = Color3.fromRGB(212, 175, 55)
		rebirthBtn.Text             = "🔄 リバース！"
		rebirthBtn.Active           = true
	else
		rebirthBtn.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
		rebirthBtn.Text             = "パワー " .. Format.commaNumber(minPG) .. " 以上必要"
		rebirthBtn.Active           = false
	end
end

local function countUpAnim(from: number, to: number, duration: number, onTick: (n: number) -> ())
	local startTime = tick()
	task.spawn(function()
		while true do
			local t = math.min((tick() - startTime) / duration, 1)
			onTick(math.floor(from + (to - from) * t))
			if t >= 1 then break end
			task.wait(0.016)
		end
	end)
end

local function playRebirthEffect(coins: number)
	-- 白→金フラッシュ（0.8秒）
	flashFrame.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
	flashFrame.BackgroundTransparency = 0.1
	TweenService:Create(
		flashFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundColor3 = Color3.fromRGB(255, 215, 0), BackgroundTransparency = 0.2 }
	):Play()
	task.delay(0.3, function()
		TweenService:Create(
			flashFrame,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 1 }
		):Play()
	end)

	-- 「🌟 REBIRTH! 🌟」巨大テキスト演出
	local sg = screenGui
	if sg then
		local rebirthText = Instance.new("TextLabel")
		rebirthText.AnchorPoint            = Vector2.new(0.5, 0.5)
		rebirthText.Size                   = UDim2.new(0, 600, 0, 100)
		rebirthText.Position               = UDim2.new(0.5, 0, 0.5, 60)
		rebirthText.BackgroundTransparency = 1
		rebirthText.Text                   = "🌟 REBIRTH! 🌟"
		rebirthText.TextColor3             = Color3.fromRGB(255, 215, 0)
		rebirthText.Font                   = Enum.Font.GothamBold
		rebirthText.TextSize               = 56
		rebirthText.TextTransparency       = 0
		rebirthText.ZIndex                 = 100
		rebirthText.Parent                 = sg

		local sc = Instance.new("UIScale")
		sc.Scale  = 0.3
		sc.Parent = rebirthText

		TweenService:Create(
			sc,
			TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = 1.15 }
		):Play()
		task.delay(0.4, function()
			TweenService:Create(sc, TweenInfo.new(0.1), { Scale = 1.0 }):Play()
		end)

		task.delay(1.8, function()
			TweenService:Create(
				rebirthText,
				TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ TextTransparency = 1 }
			):Play()
			task.delay(0.5, function() rebirthText:Destroy() end)
		end)
	end

	-- パネルシェイク
	Effects.shakeFrame(mainPanel, 0.5)

	-- 紙吹雪（金色パーティクル含む）
	Effects.rebirthConfetti()

	-- 結果テキスト（コインカウントアップ）
	resultLabel.Text             = "🔄 リバース完了！ 0コイン獲得！"
	resultLabel.TextTransparency = 0
	resultLabel.Visible          = true

	countUpAnim(0, coins, 1.2, function(n)
		resultLabel.Text = "🔄 リバース完了！ " .. Format.commaNumber(n) .. "コイン獲得！"
	end)

	task.delay(1.8, function()
		TweenService:Create(
			resultLabel,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ TextTransparency = 1 }
		):Play()
		task.delay(0.5, function()
			resultLabel.Visible = false
		end)
	end)
end

-- ─────────────────────────────────────────
-- 公開API（スライドアニメーション付き）
-- ─────────────────────────────────────────

function RebirthUI.show()
	if not mainPanel then return end
	refreshPanel()
	mainPanel.Position = PANEL_OFFBOT
	mainPanel.Visible  = true
	TweenService:Create(
		mainPanel,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = PANEL_CENTER }
	):Play()
end

function RebirthUI.hide()
	if not mainPanel then return end
	TweenService:Create(
		mainPanel,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Position = PANEL_OFFBOT }
	):Play()
	task.delay(0.2, function()
		if mainPanel then mainPanel.Visible = false end
	end)
end

-- ─────────────────────────────────────────
-- UI構築
-- ─────────────────────────────────────────

function RebirthUI.init()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name         = "RebirthUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent       = PlayerGui

	-- 全画面フラッシュ用フレーム
	local ff = Instance.new("Frame")
	ff.Name                   = "FlashFrame"
	ff.Size                   = UDim2.new(1, 0, 1, 0)
	ff.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
	ff.BackgroundTransparency = 1
	ff.BorderSizePixel        = 0
	ff.ZIndex                 = 90
	ff.Parent                 = screenGui
	flashFrame = ff

	-- メインパネル（初期非表示・下外）
	local panel = Instance.new("Frame")
	panel.Name                   = "MainPanel"
	panel.AnchorPoint            = Vector2.new(0.5, 0.5)
	panel.Size                   = UDim2.new(0, 520, 0, 440)
	panel.Position               = PANEL_OFFBOT
	panel.BackgroundColor3       = Color3.fromRGB(15, 15, 30)
	panel.BackgroundTransparency = 0.12
	panel.BorderSizePixel        = 0
	panel.Visible                = false
	panel.ZIndex                 = 10
	panel.Parent                 = screenGui
	mainPanel = panel

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 20)
	panelCorner.Parent       = panel

	local panelStroke = Instance.new("UIStroke")
	panelStroke.Color     = Color3.fromRGB(212, 175, 55)
	panelStroke.Thickness = 2
	panelStroke.Parent    = panel

	local panelPad = Instance.new("UIPadding")
	panelPad.PaddingLeft   = UDim.new(0, 24)
	panelPad.PaddingRight  = UDim.new(0, 24)
	panelPad.PaddingTop    = UDim.new(0, 20)
	panelPad.PaddingBottom = UDim.new(0, 20)
	panelPad.Parent        = panel

	local panelList = Instance.new("UIListLayout")
	panelList.FillDirection       = Enum.FillDirection.Vertical
	panelList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	panelList.VerticalAlignment   = Enum.VerticalAlignment.Top
	panelList.Padding             = UDim.new(0, 12)
	panelList.Parent              = panel

	-- タイトル
	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size                   = UDim2.new(1, 0, 0, 44)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text                   = "🔄 リバースステーション"
	titleLbl.TextColor3             = Color3.fromRGB(255, 215, 0)
	titleLbl.Font                   = Enum.Font.GothamBold
	titleLbl.TextSize               = 28
	titleLbl.ZIndex                 = 11
	titleLbl.Parent                 = panel

	-- パワー表示
	local pwrLbl = Instance.new("TextLabel")
	pwrLbl.Size                   = UDim2.new(1, 0, 0, 28)
	pwrLbl.BackgroundTransparency = 1
	pwrLbl.Text                   = "⚡ パワー: 0"
	pwrLbl.TextColor3             = Color3.fromRGB(150, 220, 255)
	pwrLbl.Font                   = Enum.Font.GothamBold
	pwrLbl.TextSize               = 20
	pwrLbl.ZIndex                 = 11
	pwrLbl.Parent                 = panel
	powerLabel = pwrLbl

	-- コイン変換プレビュー
	local coinLbl = Instance.new("TextLabel")
	coinLbl.Size                   = UDim2.new(1, 0, 0, 28)
	coinLbl.BackgroundTransparency = 1
	coinLbl.Text                   = "→ 💰 0 コイン獲得！"
	coinLbl.TextColor3             = Color3.fromRGB(255, 215, 0)
	coinLbl.Font                   = Enum.Font.GothamBold
	coinLbl.TextSize               = 20
	coinLbl.ZIndex                 = 11
	coinLbl.Parent                 = panel
	coinPreviewLabel = coinLbl

	-- ───────────────────────────────────
	-- 進捗バー
	-- ───────────────────────────────────
	local progressContainer = Instance.new("Frame")
	progressContainer.Size                   = UDim2.new(1, 0, 0, 36)
	progressContainer.BackgroundTransparency = 1
	progressContainer.BorderSizePixel        = 0
	progressContainer.ZIndex                 = 11
	progressContainer.Parent                 = panel

	-- バー背景
	local progressBg = Instance.new("Frame")
	progressBg.Size                   = UDim2.new(1, 0, 0, 16)
	progressBg.Position               = UDim2.new(0, 0, 0, 0)
	progressBg.BackgroundColor3       = Color3.fromRGB(50, 50, 70)
	progressBg.BackgroundTransparency = 0
	progressBg.BorderSizePixel        = 0
	progressBg.ZIndex                 = 11
	progressBg.Parent                 = progressContainer

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 6)
	bgCorner.Parent       = progressBg

	-- バー中身（グラデーション 青→金）
	local fill = Instance.new("Frame")
	fill.Name                   = "ProgressFill"
	fill.Size                   = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3       = Color3.fromRGB(80, 150, 255)
	fill.BackgroundTransparency = 0
	fill.BorderSizePixel        = 0
	fill.ZIndex                 = 12
	fill.Parent                 = progressBg
	progressFill = fill

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 6)
	fillCorner.Parent       = fill

	local fillGrad = Instance.new("UIGradient")
	fillGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0,   Color3.fromRGB(80,  150, 255)),
		ColorSequenceKeypoint.new(0.6, Color3.fromRGB(200, 100, 255)),
		ColorSequenceKeypoint.new(1,   Color3.fromRGB(255, 215,   0)),
	})
	fillGrad.Parent = fill

	-- パーセントテキスト
	local progressLbl = Instance.new("TextLabel")
	progressLbl.Size                   = UDim2.new(1, 0, 0, 18)
	progressLbl.Position               = UDim2.new(0, 0, 0, 18)
	progressLbl.BackgroundTransparency = 1
	progressLbl.Text                   = "0 / 1,000,000,000 (0%)"
	progressLbl.TextColor3             = Color3.fromRGB(180, 180, 180)
	progressLbl.Font                   = Enum.Font.Gotham
	progressLbl.TextSize               = 13
	progressLbl.ZIndex                 = 11
	progressLbl.Parent                 = progressContainer
	progressLabel = progressLbl

	-- ボーナス説明
	local bonusLbl = Instance.new("TextLabel")
	bonusLbl.Size                   = UDim2.new(1, 0, 0, 24)
	bonusLbl.BackgroundTransparency = 1
	bonusLbl.Text                   = "次のリバースで: クリック+5, 走行効率+0.5"
	bonusLbl.TextColor3             = Color3.fromRGB(180, 180, 180)
	bonusLbl.Font                   = Enum.Font.Gotham
	bonusLbl.TextSize               = 14
	bonusLbl.TextWrapped            = true
	bonusLbl.ZIndex                 = 11
	bonusLbl.Parent                 = panel
	bonusLabel = bonusLbl

	-- 区切り線
	local divider = Instance.new("Frame")
	divider.Size                   = UDim2.new(1, 0, 0, 2)
	divider.BackgroundColor3       = Color3.fromRGB(80, 80, 80)
	divider.BackgroundTransparency = 0
	divider.BorderSizePixel        = 0
	divider.ZIndex                 = 11
	divider.Parent                 = panel

	-- リバースボタン
	local rBtn = Instance.new("TextButton")
	rBtn.Size             = UDim2.new(1, 0, 0, 64)
	rBtn.BackgroundColor3 = Color3.fromRGB(212, 175, 55)
	rBtn.BorderSizePixel  = 0
	rBtn.Text             = "🔄 リバース！"
	rBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
	rBtn.Font             = Enum.Font.GothamBold
	rBtn.TextSize         = 26
	rBtn.AutoButtonColor  = true
	rBtn.ZIndex           = 11
	rBtn.Parent           = panel
	rebirthBtn = rBtn

	local rBtnCorner = Instance.new("UICorner")
	rBtnCorner.CornerRadius = UDim.new(0, 14)
	rBtnCorner.Parent       = rBtn

	rBtn.MouseButton1Click:Connect(function()
		if not PlayerData.canRebirth() then return end

		local result = PlayerData.doRebirth()
		SoundManager.playFanfare()
		playRebirthEffect(result.coins)
		refreshPanel()
		MiniHUD.update()
		MovementController.update()

		if updateLeaderboardRE then
			updateLeaderboardRE:FireServer(0, result.newRebirthCount)
		end
	end)

	-- リバース完了テキスト（画面中央）
	local resLbl = Instance.new("TextLabel")
	resLbl.Name                   = "ResultLabel"
	resLbl.AnchorPoint            = Vector2.new(0.5, 0.5)
	resLbl.Size                   = UDim2.new(0, 600, 0, 70)
	resLbl.Position               = UDim2.new(0.5, 0, 0.35, 0)
	resLbl.BackgroundTransparency = 1
	resLbl.Text                   = ""
	resLbl.TextColor3             = Color3.fromRGB(255, 215, 0)
	resLbl.Font                   = Enum.Font.GothamBold
	resLbl.TextSize               = 34
	resLbl.Visible                = false
	resLbl.ZIndex                 = 95
	resLbl.Parent                 = screenGui
	resultLabel = resLbl

	refreshPanel()
end

return RebirthUI
