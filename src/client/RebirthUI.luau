-- リバースステーションUI

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local PlayerData         = require(ReplicatedStorage.Shared.PlayerData)
local Config             = require(ReplicatedStorage.Shared.Config)
local MiniHUD            = require(script.Parent.MiniHUD)
local TrainingUI         = require(script.Parent.TrainingUI)
local SoundManager       = require(script.Parent.SoundManager)
local MovementController = require(script.Parent.MovementController)

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

-- ─────────────────────────────────────────
-- ヘルパー
-- ─────────────────────────────────────────

local function refreshPanel()
	local d      = PlayerData.getData()
	local power  = math.floor(d.PowerGauge)
	local earned = math.floor(power * Config.Rebirth.CoinsPerPower)
	local canDo  = PlayerData.canRebirth()

	powerLabel.Text       = "⚡ パワー: " .. power
	coinPreviewLabel.Text = "→ 💰 " .. earned .. " コイン獲得！"

	local nextCount  = (d.RebirthCount :: number) + 1
	local clickBonus = nextCount * Config.Rebirth.ClickBonusPerRebirth
	local speedBonus = nextCount * Config.Rebirth.SpeedBonusPerRebirth
	bonusLabel.Text = "次のリバースで: クリック+" .. clickBonus .. ", 走行効率+" .. speedBonus

	if canDo then
		rebirthBtn.BackgroundColor3 = Color3.fromRGB(212, 175, 55)
		rebirthBtn.Text             = "🔄 リバース！"
		rebirthBtn.Active           = true
	else
		rebirthBtn.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
		rebirthBtn.Text             = "パワーが " .. Config.Rebirth.MinPowerGauge .. " 以上必要です"
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
	-- 画面フラッシュ
	flashFrame.BackgroundTransparency = 0.3
	TweenService:Create(
		flashFrame,
		TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 }
	):Play()

	-- 結果テキスト表示
	resultLabel.Text            = "🔄 リバース完了！ 0コイン獲得！"
	resultLabel.TextTransparency = 0
	resultLabel.Visible         = true

	countUpAnim(0, coins, 1.2, function(n)
		resultLabel.Text = "🔄 リバース完了！ " .. n .. "コイン獲得！"
	end)

	-- 2秒後にフェードアウト
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
-- 公開API
-- ─────────────────────────────────────────

function RebirthUI.show()
	if mainPanel then
		refreshPanel()
		mainPanel.Visible = true
	end
end

function RebirthUI.hide()
	if mainPanel then
		mainPanel.Visible = false
	end
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
	ff.BackgroundColor3       = Color3.fromRGB(255, 255, 200)
	ff.BackgroundTransparency = 1
	ff.BorderSizePixel        = 0
	ff.ZIndex                 = 90
	ff.Parent                 = screenGui
	flashFrame = ff

	-- メインパネル（初期非表示）
	local panel = Instance.new("Frame")
	panel.Name                   = "MainPanel"
	panel.AnchorPoint            = Vector2.new(0.5, 0.5)
	panel.Size                   = UDim2.new(0, 500, 0, 400)
	panel.Position               = UDim2.new(0.5, 0, 0.5, 0)
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
	panelList.Padding             = UDim.new(0, 14)
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
	pwrLbl.Size                   = UDim2.new(1, 0, 0, 32)
	pwrLbl.BackgroundTransparency = 1
	pwrLbl.Text                   = "⚡ パワー: 0"
	pwrLbl.TextColor3             = Color3.fromRGB(150, 220, 255)
	pwrLbl.Font                   = Enum.Font.GothamBold
	pwrLbl.TextSize               = 22
	pwrLbl.ZIndex                 = 11
	pwrLbl.Parent                 = panel
	powerLabel = pwrLbl

	-- コイン変換プレビュー
	local coinLbl = Instance.new("TextLabel")
	coinLbl.Size                   = UDim2.new(1, 0, 0, 32)
	coinLbl.BackgroundTransparency = 1
	coinLbl.Text                   = "→ 💰 0 コイン獲得！"
	coinLbl.TextColor3             = Color3.fromRGB(255, 215, 0)
	coinLbl.Font                   = Enum.Font.GothamBold
	coinLbl.TextSize               = 22
	coinLbl.ZIndex                 = 11
	coinLbl.Parent                 = panel
	coinPreviewLabel = coinLbl

	-- ボーナス説明
	local bonusLbl = Instance.new("TextLabel")
	bonusLbl.Size                   = UDim2.new(1, 0, 0, 28)
	bonusLbl.BackgroundTransparency = 1
	bonusLbl.Text                   = "次のリバースで: クリック+0.5, 走行効率+0.02"
	bonusLbl.TextColor3             = Color3.fromRGB(180, 180, 180)
	bonusLbl.Font                   = Enum.Font.Gotham
	bonusLbl.TextSize               = 15
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
		SoundManager.playRebirth()
		playRebirthEffect(result.coins)
		refreshPanel()
		MiniHUD.update()
		MovementController.update()
		-- リーダーボードにリバース回数を送信（最高高度はリセットされるので0）
		if updateLeaderboardRE then
			updateLeaderboardRE:FireServer(0, result.newRebirthCount)
		end
	end)

	-- 閉じるボタン（右上・絶対配置）
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name             = "CloseButton"
	closeBtn.AnchorPoint      = Vector2.new(1, 0)
	closeBtn.Size             = UDim2.new(0, 36, 0, 36)
	closeBtn.Position         = UDim2.new(1, -8, 0, 8)
	closeBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
	closeBtn.BorderSizePixel  = 0
	closeBtn.Text             = "✕"
	closeBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
	closeBtn.Font             = Enum.Font.GothamBold
	closeBtn.TextSize         = 18
	closeBtn.ZIndex           = 12
	closeBtn.Parent           = panel

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent       = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		RebirthUI.hide()
	end)

	-- リバース完了テキスト（mainPanelの外・画面中央）
	local resLbl = Instance.new("TextLabel")
	resLbl.Name                   = "ResultLabel"
	resLbl.AnchorPoint            = Vector2.new(0.5, 0.5)
	resLbl.Size                   = UDim2.new(0, 560, 0, 70)
	resLbl.Position               = UDim2.new(0.5, 0, 0.35, 0)
	resLbl.BackgroundTransparency = 1
	resLbl.Text                   = ""
	resLbl.TextColor3             = Color3.fromRGB(255, 215, 0)
	resLbl.Font                   = Enum.Font.GothamBold
	resLbl.TextSize               = 36
	resLbl.Visible                = false
	resLbl.ZIndex                 = 95
	resLbl.Parent                 = screenGui
	resultLabel = resLbl

	refreshPanel()
end

return RebirthUI
