-- トレーニング画面のUI生成・管理

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local PlayerData         = require(ReplicatedStorage.Shared.PlayerData)
local Config             = require(ReplicatedStorage.Shared.Config)
local MiniHUD            = require(script.Parent.MiniHUD)
local MovementController = require(script.Parent.MovementController)
local AltitudeTracker    = require(script.Parent.AltitudeTracker)
local Effects            = require(script.Parent.Effects)
local SoundManager       = require(script.Parent.SoundManager)

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local TrainingUI = {}

-- ─────────────────────────────────────────
-- ボタン定義（ジャンプ力のみ）
-- ─────────────────────────────────────────
local BUTTON_DEF = {
	statName    = "JumpPower",
	valuePrefix = "ジャンプ力",
	color       = Color3.fromRGB(52, 152, 219),
	darkColor   = Color3.fromRGB(31,  97, 141),
}

-- ─────────────────────────────────────────
-- 内部参照
-- ─────────────────────────────────────────
local jumpBtn         = nil :: TextButton?
local jumpValueLabel  = nil :: TextLabel?
local shoesLabel      = nil :: TextLabel?
local totalPowerLabel = nil :: TextLabel?
local stageLabel      = nil :: TextLabel?
local evolutionNotice = nil :: TextLabel?
local trainingScreenGui = nil :: ScreenGui?

local buttonArea = nil :: Frame?
local resetBtn   = nil :: TextButton?

local noticeVersion = 0

-- ─────────────────────────────────────────
-- ヘルパー関数
-- ─────────────────────────────────────────

local function updateDisplay()
	local d = PlayerData.getData()

	totalPowerLabel.Text = "総合パワー: " .. math.floor(d.JumpPower) .. " / パワー: " .. math.floor(d.PowerGauge)
	stageLabel.Text      = "進化段階: Stage " .. PlayerData.getEvolutionStage()

	local cp = PlayerData.getEffectiveClickPower()
	if jumpBtn then
		jumpBtn.Text = "💪 ジャンプ力\nトレーニング\n(+" .. cp .. "/click)"
	end
	if jumpValueLabel then
		jumpValueLabel.Text = BUTTON_DEF.valuePrefix .. ": " .. math.floor(d.JumpPower)
	end
	if shoesLabel then
		local shoes = Config.Shoes[d.EquippedShoes]
		local name  = if shoes then shoes.name else "なし"
		shoesLabel.Text = "👟 装備: " .. name
	end

	MiniHUD.update()
	MovementController.update()
end

local function playClickAnimation(button: TextButton)
	local uiScale = button:FindFirstChildOfClass("UIScale")
	if not uiScale then
		uiScale        = Instance.new("UIScale")
		uiScale.Scale  = 1
		uiScale.Parent = button
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

-- 現在値のポップアニメーション
local function popValueLabel()
	if not jumpValueLabel then return end
	local sc = jumpValueLabel:FindFirstChildOfClass("UIScale")
	if not sc then
		sc        = Instance.new("UIScale")
		sc.Scale  = 1
		sc.Parent = jumpValueLabel
	end
	TweenService:Create(sc, TweenInfo.new(0.05, Enum.EasingStyle.Quad), { Scale = 1.35 }):Play()
	task.delay(0.05, function()
		TweenService:Create(sc, TweenInfo.new(0.15, Enum.EasingStyle.Quad), { Scale = 1.0 }):Play()
	end)
end

-- ダメージ数字演出（「+N」がボタン上部から浮き上がりフェードアウト）
local function showDamageNumber(clickPower: number)
	local sg = trainingScreenGui
	if not sg or not jumpBtn then return end

	local absPos  = jumpBtn.AbsolutePosition
	local absSize = jumpBtn.AbsoluteSize
	local startX  = absPos.X + absSize.X / 2 + math.random(-30, 30)
	local startY  = absPos.Y + 20

	local lbl = Instance.new("TextLabel")
	lbl.AnchorPoint            = Vector2.new(0.5, 1)
	lbl.Size                   = UDim2.new(0, 80, 0, 28)
	lbl.Position               = UDim2.new(0, startX, 0, startY)
	lbl.BackgroundTransparency = 1
	lbl.Text                   = "+" .. clickPower
	lbl.TextColor3             = Color3.fromRGB(100, 220, 255)
	lbl.Font                   = Enum.Font.GothamBold
	lbl.TextSize               = 24
	lbl.TextTransparency       = 0
	lbl.ZIndex                 = 30
	lbl.Parent                 = sg

	TweenService:Create(
		lbl,
		TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0, startX, 0, startY - 60), TextTransparency = 1 }
	):Play()

	task.delay(0.7, function() lbl:Destroy() end)
end

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
-- 公開API
-- ─────────────────────────────────────────

function TrainingUI.setButtonsVisible(visible: boolean)
	if buttonArea then buttonArea.Visible = visible end
	if resetBtn   then resetBtn.Visible   = visible end
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
	trainingScreenGui = screenGui

	-- 上部ステータスバー ----------------------------------------
	local topBar = Instance.new("Frame")
	topBar.Name                   = "TopBar"
	topBar.Size                   = UDim2.new(1, 0, 0, 64)
	topBar.BackgroundColor3       = Color3.fromRGB(15, 15, 25)
	topBar.BackgroundTransparency = 0.15
	topBar.BorderSizePixel        = 0
	topBar.Parent                 = screenGui

	totalPowerLabel = Instance.new("TextLabel")
	totalPowerLabel.Size                   = UDim2.new(0.6, -16, 1, 0)
	totalPowerLabel.Position               = UDim2.new(0, 16, 0, 0)
	totalPowerLabel.BackgroundTransparency = 1
	totalPowerLabel.Text                   = "総合パワー: 0 / パワー: 0"
	totalPowerLabel.TextColor3             = Color3.fromRGB(255, 255, 255)
	totalPowerLabel.Font                   = Enum.Font.GothamBold
	totalPowerLabel.TextSize               = 22
	totalPowerLabel.TextXAlignment         = Enum.TextXAlignment.Left
	totalPowerLabel.Parent                 = topBar

	stageLabel = Instance.new("TextLabel")
	stageLabel.Size                   = UDim2.new(0.4, -16, 1, 0)
	stageLabel.Position               = UDim2.new(0.6, 0, 0, 0)
	stageLabel.BackgroundTransparency = 1
	stageLabel.Text                   = "進化段階: Stage 0"
	stageLabel.TextColor3             = Color3.fromRGB(255, 220, 50)
	stageLabel.Font                   = Enum.Font.GothamBold
	stageLabel.TextSize               = 22
	stageLabel.TextXAlignment         = Enum.TextXAlignment.Right
	stageLabel.Parent                 = topBar

	-- ボタンエリア（画面下部中央・初期非表示）------------------
	buttonArea = Instance.new("Frame")
	buttonArea.Name                   = "ButtonArea"
	buttonArea.AnchorPoint            = Vector2.new(0.5, 1)
	buttonArea.Size                   = UDim2.new(0, 260, 0, 264)
	buttonArea.Position               = UDim2.new(0.5, 0, 1, -72)
	buttonArea.BackgroundTransparency = 1
	buttonArea.Visible                = false
	buttonArea.Parent                 = screenGui

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection       = Enum.FillDirection.Horizontal
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.VerticalAlignment   = Enum.VerticalAlignment.Top
	listLayout.Padding             = UDim.new(0, 20)
	listLayout.Parent              = buttonArea

	-- ジャンプ力ボタン生成 -------------------------------------------
	local def = BUTTON_DEF

	local container = Instance.new("Frame")
	container.Name                   = def.statName .. "Container"
	container.Size                   = UDim2.new(0, 240, 0, 260)
	container.BackgroundTransparency = 1
	container.Parent                 = buttonArea

	local btn = Instance.new("TextButton")
	btn.Name             = def.statName .. "Button"
	btn.Size             = UDim2.new(1, 0, 0, 180)
	btn.BackgroundColor3 = def.color
	btn.BorderSizePixel  = 0
	btn.Text             = "💪 ジャンプ力\nトレーニング\n(+3/click)"
	btn.TextColor3       = Color3.fromRGB(255, 255, 255)
	btn.Font             = Enum.Font.GothamBold
	btn.TextSize         = 22
	btn.TextWrapped      = true
	btn.AutoButtonColor  = false
	btn.Parent           = container
	jumpBtn = btn

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 18)
	corner.Parent       = btn

	local stroke = Instance.new("UIStroke")
	stroke.Color     = def.darkColor
	stroke.Thickness = 4
	stroke.Parent    = btn

	-- 現在値ラベル
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name                   = def.statName .. "Value"
	valueLabel.Size                   = UDim2.new(1, 0, 0, 34)
	valueLabel.Position               = UDim2.new(0, 0, 0, 188)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text                   = def.valuePrefix .. ": 0"
	valueLabel.TextColor3             = Color3.fromRGB(210, 210, 210)
	valueLabel.Font                   = Enum.Font.GothamBold
	valueLabel.TextSize               = 22
	valueLabel.Parent                 = container
	jumpValueLabel = valueLabel

	-- 装備シューズ表示ラベル
	local shoesLbl = Instance.new("TextLabel")
	shoesLbl.Name                   = "ShoesLabel"
	shoesLbl.Size                   = UDim2.new(1, 0, 0, 22)
	shoesLbl.Position               = UDim2.new(0, 0, 0, 228)
	shoesLbl.BackgroundTransparency = 1
	shoesLbl.Text                   = "👟 装備: スターターシューズ"
	shoesLbl.TextColor3             = Color3.fromRGB(160, 210, 255)
	shoesLbl.Font                   = Enum.Font.Gotham
	shoesLbl.TextSize               = 14
	shoesLbl.Parent                 = container
	shoesLabel = shoesLbl

	btn.MouseButton1Click:Connect(function()
		playClickAnimation(btn)
		popValueLabel()
		Effects.clickBurst(def.color)
		SoundManager.playClick()

		local clickPower = PlayerData.getEffectiveClickPower()
		PlayerData.addPower("JumpPower", clickPower)
		PlayerData.addPower("PowerGauge", clickPower * 0.5)
		showDamageNumber(clickPower)

		local newStage = PlayerData.getEvolutionStage()
		if newStage > prevStage then
			prevStage = newStage
			showEvolutionNotice(newStage)
			local char = LocalPlayer.Character
			if char then
				Effects.evolutionBurst(char)
			end
			SoundManager.playEvolution()
		end

		updateDisplay()
	end)

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = def.darkColor }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = def.color }):Play()
	end)

	-- リセットボタン（ButtonAreaの直下・中央・初期非表示）------
	resetBtn = Instance.new("TextButton")
	resetBtn.Name             = "ResetButton"
	resetBtn.AnchorPoint      = Vector2.new(0.5, 0)
	resetBtn.Size             = UDim2.new(0, 100, 0, 36)
	resetBtn.Position         = UDim2.new(0.5, 0, 1, -64)
	resetBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	resetBtn.BorderSizePixel  = 0
	resetBtn.Text             = "🔄 リセット"
	resetBtn.TextColor3       = Color3.fromRGB(200, 200, 200)
	resetBtn.Font             = Enum.Font.GothamBold
	resetBtn.TextSize         = 14
	resetBtn.AutoButtonColor  = false
	resetBtn.Visible          = false
	resetBtn.ZIndex           = 5
	resetBtn.Parent           = screenGui

	local resetCorner = Instance.new("UICorner")
	resetCorner.CornerRadius = UDim.new(0, 8)
	resetCorner.Parent       = resetBtn

	resetBtn.MouseButton1Click:Connect(function()
		PlayerData.reset()
		AltitudeTracker.resetMilestones()
		prevStage = 0
		updateDisplay()
	end)
	resetBtn.MouseEnter:Connect(function()
		TweenService:Create(resetBtn, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(55, 55, 55) }):Play()
	end)
	resetBtn.MouseLeave:Connect(function()
		TweenService:Create(resetBtn, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(80, 80, 80) }):Play()
	end)

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
