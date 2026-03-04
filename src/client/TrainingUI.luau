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
-- ボタン定義
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

local noticeVersion = 0

-- ─────────────────────────────────────────
-- コンボ追跡
-- ─────────────────────────────────────────
local clickTimes      = {}
local COMBO_WINDOW    = 1.0
local COMBO_THRESHOLD = 5

local function recordClickCombo(): number
	local now    = tick()
	local cutoff = now - COMBO_WINDOW
	table.insert(clickTimes, now)
	while clickTimes[1] and clickTimes[1] < cutoff do
		table.remove(clickTimes, 1)
	end
	return #clickTimes
end

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

	-- フローティングジャンプボタン（右下固定・常時表示）----------
	local def = BUTTON_DEF

	local container = Instance.new("Frame")
	container.Name                   = "FloatingButtonContainer"
	container.AnchorPoint            = Vector2.new(1, 1)
	container.Size                   = UDim2.new(0, 180, 0, 218)
	container.Position               = UDim2.new(1, -20, 1, -20)
	container.BackgroundTransparency = 1
	container.Parent                 = screenGui

	local btn = Instance.new("TextButton")
	btn.Name             = def.statName .. "Button"
	btn.Size             = UDim2.new(1, 0, 0, 160)
	btn.BackgroundColor3 = def.color
	btn.BorderSizePixel  = 0
	btn.Text             = "💪 ジャンプ力\nトレーニング\n(+3/click)"
	btn.TextColor3       = Color3.fromRGB(255, 255, 255)
	btn.Font             = Enum.Font.GothamBold
	btn.TextSize         = 20
	btn.TextWrapped      = true
	btn.AutoButtonColor  = false
	btn.Parent           = container
	jumpBtn = btn

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 20)
	corner.Parent       = btn

	local stroke = Instance.new("UIStroke")
	stroke.Color     = def.darkColor
	stroke.Thickness = 4
	stroke.Parent    = btn

	-- 現在値ラベル
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name                   = def.statName .. "Value"
	valueLabel.Size                   = UDim2.new(1, 0, 0, 28)
	valueLabel.Position               = UDim2.new(0, 0, 0, 168)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text                   = def.valuePrefix .. ": 0"
	valueLabel.TextColor3             = Color3.fromRGB(210, 210, 210)
	valueLabel.Font                   = Enum.Font.GothamBold
	valueLabel.TextSize               = 18
	valueLabel.Parent                 = container
	jumpValueLabel = valueLabel

	-- 装備シューズ表示ラベル
	local shoesLbl = Instance.new("TextLabel")
	shoesLbl.Name                   = "ShoesLabel"
	shoesLbl.Size                   = UDim2.new(1, 0, 0, 18)
	shoesLbl.Position               = UDim2.new(0, 0, 0, 198)
	shoesLbl.BackgroundTransparency = 1
	shoesLbl.Text                   = "👟 装備: スターターシューズ"
	shoesLbl.TextColor3             = Color3.fromRGB(160, 210, 255)
	shoesLbl.Font                   = Enum.Font.Gotham
	shoesLbl.TextSize               = 13
	shoesLbl.Parent                 = container
	shoesLabel = shoesLbl

	-- クリック処理
	btn.MouseButton1Click:Connect(function()
		playClickAnimation(btn)
		popValueLabel()
		Effects.clickBurst(def.color)
		SoundManager.playClick()

		local clickPower = PlayerData.getEffectiveClickPower()
		PlayerData.addPower("JumpPower", clickPower)
		PlayerData.addPower("PowerGauge", clickPower * 0.5)
		showDamageNumber(clickPower)

		-- コンボチェック
		local comboCount = recordClickCombo()
		if comboCount >= COMBO_THRESHOLD then
			Effects.comboText(comboCount)
			SoundManager.playCombo()
		end

		-- 進化チェック
		local newStage = PlayerData.getEvolutionStage()
		if newStage > prevStage then
			prevStage = newStage
			showEvolutionNotice(newStage)
			Effects.evolutionFlash(newStage)
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

-- リセット後にprevStageをリセットする（外部から呼ぶ用）
function TrainingUI.onReset()
	-- prevStage はローカルスコープだが updateDisplay で再計算されるので問題なし
end

return TrainingUI
