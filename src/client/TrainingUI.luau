-- トレーニング画面のUI生成・管理

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local PlayerData = require(ReplicatedStorage.Shared.PlayerData)
local Config     = require(ReplicatedStorage.Shared.Config)

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local TrainingUI = {}

-- ─────────────────────────────────────────
-- ボタン定義
-- ─────────────────────────────────────────

local BUTTON_DEFS = {
	{
		statName    = "DashPower",
		label       = "🦵 脚力\nトレーニング",
		valuePrefix = "脚力",
		color       = Color3.fromRGB( 52, 152, 219),
		darkColor   = Color3.fromRGB( 31,  97, 141),
	},
	{
		statName    = "JumpPower",
		label       = "⬆️ ジャンプ\nトレーニング",
		valuePrefix = "ジャンプ力",
		color       = Color3.fromRGB( 39, 174,  96),
		darkColor   = Color3.fromRGB( 24, 106,  59),
	},
	{
		statName    = "FlightPower",
		label       = "🪽 飛行\nトレーニング",
		valuePrefix = "飛行力",
		color       = Color3.fromRGB(142,  68, 173),
		darkColor   = Color3.fromRGB( 86,  41, 105),
	},
}

-- ─────────────────────────────────────────
-- 内部参照
-- ─────────────────────────────────────────

-- { label: TextLabel, prefix: string } のテーブルをstatName毎に保持
local valueLabels      = {} :: { [string]: { label: TextLabel, prefix: string } }
local totalPowerLabel  = nil :: TextLabel?
local stageLabel       = nil :: TextLabel?
local evolutionNotice  = nil :: TextLabel?

-- 複数の進化通知が重なった場合に古いhide処理をキャンセルするバージョン管理
local noticeVersion = 0

-- ─────────────────────────────────────────
-- ヘルパー関数
-- ─────────────────────────────────────────

local function updateDisplay()
	local d     = PlayerData.getData()
	local total = (d.DashPower :: number) + (d.JumpPower :: number) + (d.FlightPower :: number)

	totalPowerLabel.Text = "総合パワー: " .. total
	stageLabel.Text      = "進化段階: Stage " .. PlayerData.getEvolutionStage()

	for statName, info in pairs(valueLabels) do
		info.label.Text = info.prefix .. ": " .. (d[statName] :: number)
	end
end

-- ボタンをぽんと大きくするアニメーション
local function playClickAnimation(button: TextButton)
	local uiScale = button:FindFirstChildOfClass("UIScale")
	if not uiScale then
		uiScale          = Instance.new("UIScale")
		uiScale.Scale    = 1
		uiScale.Parent   = button
	end
	TweenService:Create(
		uiScale,
		TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Scale = 1.13 }
	):Play()
	task.delay(0.07, function()
		TweenService:Create(
			uiScale,
			TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Scale = 1.0 }
		):Play()
	end)
end

-- 画面中央に進化演出を表示（2秒でフェードアウト）
local function showEvolutionNotice(stage: number)
	noticeVersion += 1
	local myVersion = noticeVersion

	evolutionNotice.Text                   = "⭐ 進化！ Stage " .. stage .. " ⭐"
	evolutionNotice.TextTransparency       = 0
	evolutionNotice.BackgroundTransparency = 0.15
	evolutionNotice.Visible                = true

	TweenService:Create(
		evolutionNotice,
		TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ TextTransparency = 1, BackgroundTransparency = 1 }
	):Play()

	task.delay(2, function()
		if noticeVersion == myVersion then
			evolutionNotice.Visible = false
		end
	end)
end

-- ─────────────────────────────────────────
-- UI構築
-- ─────────────────────────────────────────

function TrainingUI.init()
	local prevStage = PlayerData.getEvolutionStage()

	-- ScreenGui ------------------------------------------------
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name         = "TrainingUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent       = PlayerGui

	-- 上部ステータスバー ----------------------------------------
	local topBar = Instance.new("Frame")
	topBar.Name                   = "TopBar"
	topBar.Size                   = UDim2.new(1, 0, 0, 64)
	topBar.BackgroundColor3       = Color3.fromRGB(15, 15, 25)
	topBar.BackgroundTransparency = 0.15
	topBar.BorderSizePixel        = 0
	topBar.Parent                 = screenGui

	totalPowerLabel = Instance.new("TextLabel")
	totalPowerLabel.Size              = UDim2.new(0.5, -16, 1, 0)
	totalPowerLabel.Position          = UDim2.new(0, 16, 0, 0)
	totalPowerLabel.BackgroundTransparency = 1
	totalPowerLabel.Text              = "総合パワー: 0"
	totalPowerLabel.TextColor3        = Color3.fromRGB(255, 255, 255)
	totalPowerLabel.Font              = Enum.Font.GothamBold
	totalPowerLabel.TextSize          = 24
	totalPowerLabel.TextXAlignment    = Enum.TextXAlignment.Left
	totalPowerLabel.Parent            = topBar

	stageLabel = Instance.new("TextLabel")
	stageLabel.Size              = UDim2.new(0.5, -16, 1, 0)
	stageLabel.Position          = UDim2.new(0.5, 0, 0, 0)
	stageLabel.BackgroundTransparency = 1
	stageLabel.Text              = "進化段階: Stage 0"
	stageLabel.TextColor3        = Color3.fromRGB(255, 220, 50)
	stageLabel.Font              = Enum.Font.GothamBold
	stageLabel.TextSize          = 24
	stageLabel.TextXAlignment    = Enum.TextXAlignment.Right
	stageLabel.Parent            = topBar

	-- ボタンエリア（画面下部中央）-------------------------------
	local buttonArea = Instance.new("Frame")
	buttonArea.Name                   = "ButtonArea"
	buttonArea.AnchorPoint            = Vector2.new(0.5, 1)
	buttonArea.Size                   = UDim2.new(0, 680, 0, 230)
	buttonArea.Position               = UDim2.new(0.5, 0, 1, -24)
	buttonArea.BackgroundTransparency = 1
	buttonArea.Parent                 = screenGui

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection       = Enum.FillDirection.Horizontal
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
	listLayout.Padding             = UDim.new(0, 20)
	listLayout.Parent              = buttonArea

	-- 各ボタン生成 -------------------------------------------
	for _, def in ipairs(BUTTON_DEFS) do
		-- コンテナ（ボタン本体＋数値ラベルをまとめる）
		local container = Instance.new("Frame")
		container.Name                   = def.statName .. "Container"
		container.Size                   = UDim2.new(0, 200, 1, 0)
		container.BackgroundTransparency = 1
		container.Parent                 = buttonArea

		-- トレーニングボタン
		local btn = Instance.new("TextButton")
		btn.Name             = def.statName .. "Button"
		btn.Size             = UDim2.new(1, 0, 0, 170)
		btn.BackgroundColor3 = def.color
		btn.BorderSizePixel  = 0
		btn.Text             = def.label
		btn.TextColor3       = Color3.fromRGB(255, 255, 255)
		btn.Font             = Enum.Font.GothamBold
		btn.TextSize         = 22
		btn.TextWrapped      = true
		btn.AutoButtonColor  = false
		btn.Parent           = container

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 18)
		corner.Parent       = btn

		local stroke = Instance.new("UIStroke")
		stroke.Color     = def.darkColor
		stroke.Thickness = 4
		stroke.Parent    = btn

		-- 現在値ラベル（ボタン直下）
		local valueLabel = Instance.new("TextLabel")
		valueLabel.Name              = def.statName .. "Value"
		valueLabel.Size              = UDim2.new(1, 0, 0, 36)
		valueLabel.Position          = UDim2.new(0, 0, 0, 178)
		valueLabel.BackgroundTransparency = 1
		valueLabel.Text              = def.valuePrefix .. ": 0"
		valueLabel.TextColor3        = Color3.fromRGB(210, 210, 210)
		valueLabel.Font              = Enum.Font.GothamBold
		valueLabel.TextSize          = 22
		valueLabel.Parent            = container

		valueLabels[def.statName] = { label = valueLabel, prefix = def.valuePrefix }

		-- クリック時の処理
		btn.MouseButton1Click:Connect(function()
			playClickAnimation(btn)
			PlayerData.addPower(def.statName, Config.PowerPerClick[def.statName])

			local newStage = PlayerData.getEvolutionStage()
			if newStage > prevStage then
				prevStage = newStage
				showEvolutionNotice(newStage)
			end

			updateDisplay()
		end)

		-- ホバーで色を暗くする
		btn.MouseEnter:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = def.darkColor }):Play()
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = def.color }):Play()
		end)
	end

	-- 進化演出テキスト（画面中央・ZIndex最前面）---------------
	evolutionNotice = Instance.new("TextLabel")
	evolutionNotice.Name                   = "EvolutionNotice"
	evolutionNotice.AnchorPoint            = Vector2.new(0.5, 0.5)
	evolutionNotice.Size                   = UDim2.new(0, 520, 0, 80)
	evolutionNotice.Position               = UDim2.new(0.5, 0, 0.42, 0)
	evolutionNotice.BackgroundColor3       = Color3.fromRGB(30, 20, 60)
	evolutionNotice.BackgroundTransparency = 1
	evolutionNotice.Text                   = ""
	evolutionNotice.TextColor3             = Color3.fromRGB(255, 220, 50)
	evolutionNotice.Font                   = Enum.Font.GothamBold
	evolutionNotice.TextSize               = 36
	evolutionNotice.Visible                = false
	evolutionNotice.ZIndex                 = 10
	evolutionNotice.Parent                 = screenGui

	local noticeCorner = Instance.new("UICorner")
	noticeCorner.CornerRadius = UDim.new(0, 14)
	noticeCorner.Parent       = evolutionNotice

	updateDisplay()
end

return TrainingUI
