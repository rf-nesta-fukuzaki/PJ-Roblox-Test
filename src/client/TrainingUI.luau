-- トレーニング画面のUI生成・管理

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local PlayerData = require(ReplicatedStorage.Shared.PlayerData)
local Config     = require(ReplicatedStorage.Shared.Config)
local Format     = require(ReplicatedStorage.Shared.Format)

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local TrainingUI = {}

-- ─────────────────────────────────────────
-- 内部参照
-- ─────────────────────────────────────────
local screenGui        = nil :: ScreenGui?
local totalPowerLabel  = nil :: TextLabel?
local stageLabel       = nil :: TextLabel?
local evolutionNotice  = nil :: TextLabel?

local statusBarLabels = {} :: { [string]: TextLabel }
local noticeVersion   = 0
local gaugeGold       = false
local gaugePulseScale = nil :: UIScale?

-- ─────────────────────────────────────────
-- PowerGaugeパルスアニメ
-- ─────────────────────────────────────────

local function startGaugePulse()
	local lbl = statusBarLabels.gauge
	if not lbl then return end
	if not gaugePulseScale then
		local sc  = Instance.new("UIScale")
		sc.Scale  = 1
		sc.Parent = lbl
		gaugePulseScale = sc
	end
	local sc = gaugePulseScale
	task.spawn(function()
		while gaugeGold and statusBarLabels.gauge do
			TweenService:Create(sc, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { Scale = 1.1 }):Play()
			task.wait(0.5)
			TweenService:Create(sc, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { Scale = 1.0 }):Play()
			task.wait(0.5)
		end
		if sc then sc.Scale = 1 end
	end)
end

-- ─────────────────────────────────────────
-- 公開API
-- ─────────────────────────────────────────

function TrainingUI.updateDisplay()
	local d  = PlayerData.getData()
	local cp = PlayerData.getEffectiveClickPower()

	if totalPowerLabel then
		totalPowerLabel.Text = "ジャンプ力: " .. Format.commaNumber(d.JumpPower)
			.. " / パワー: " .. Format.commaNumber(d.PowerGauge)
	end
	if stageLabel then
		stageLabel.Text = "Stage " .. PlayerData.getEvolutionStage()
	end

	-- ステータスバーの各項目
	local shoes     = Config.Shoes[d.EquippedShoes]
	local shoesName = if shoes then shoes.name else "なし"

	if statusBarLabels.shoes then
		statusBarLabels.shoes.Text = "👟" .. shoesName
	end
	if statusBarLabels.click then
		statusBarLabels.click.Text = "💪+" .. math.floor(cp) .. "/tap"
	end
	if statusBarLabels.gauge then
		local gauge    = d.PowerGauge
		local isGold   = gauge >= Config.Rebirth.MinPowerGauge
		statusBarLabels.gauge.Text      = "⚡" .. Format.commaNumber(gauge)
		statusBarLabels.gauge.TextColor3 = if isGold
			then Color3.fromRGB(255, 215, 0)
			else Color3.fromRGB(150, 220, 255)
		if isGold and not gaugeGold then
			gaugeGold = true
			startGaugePulse()
		elseif not isGold then
			gaugeGold = false
		end
	end
	if statusBarLabels.coins then
		statusBarLabels.coins.Text = "💰" .. Format.commaNumber(d.Coins)
	end
end

-- シューズ名部分のバウンスアニメ（ShopUI から呼ぶ）
function TrainingUI.bounceShoeLabel()
	local lbl = statusBarLabels.shoes
	if not lbl then return end
	local sc = lbl:FindFirstChildOfClass("UIScale")
	if not sc then
		sc        = Instance.new("UIScale")
		sc.Scale  = 1
		sc.Parent = lbl
	end
	TweenService:Create(sc, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.5 }):Play()
	task.delay(0.1, function()
		TweenService:Create(sc, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { Scale = 1.0 }):Play()
	end)
end

function TrainingUI.showEvolutionNotice(stage: number)
	if not evolutionNotice then return end

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
	-- ScreenGui
	local sg = Instance.new("ScreenGui")
	sg.Name         = "TrainingUI"
	sg.ResetOnSpawn = false
	sg.Parent       = PlayerGui
	screenGui = sg

	-- 上部ステータスバー
	local topBar = Instance.new("Frame")
	topBar.Name                   = "TopBar"
	topBar.Size                   = UDim2.new(1, 0, 0, 64)
	topBar.BackgroundColor3       = Color3.fromRGB(15, 15, 25)
	topBar.BackgroundTransparency = 0.15
	topBar.BorderSizePixel        = 0
	topBar.Parent                 = sg

	totalPowerLabel = Instance.new("TextLabel")
	totalPowerLabel.Size                   = UDim2.new(0.65, -16, 1, 0)
	totalPowerLabel.Position               = UDim2.new(0, 16, 0, 0)
	totalPowerLabel.BackgroundTransparency = 1
	totalPowerLabel.Text                   = "ジャンプ力: 0 / パワー: 0"
	totalPowerLabel.TextColor3             = Color3.fromRGB(255, 255, 255)
	totalPowerLabel.Font                   = Enum.Font.GothamBold
	totalPowerLabel.TextSize               = 20
	totalPowerLabel.TextXAlignment         = Enum.TextXAlignment.Left
	totalPowerLabel.Parent                 = topBar

	stageLabel = Instance.new("TextLabel")
	stageLabel.Size                   = UDim2.new(0.35, -16, 1, 0)
	stageLabel.Position               = UDim2.new(0.65, 0, 0, 0)
	stageLabel.BackgroundTransparency = 1
	stageLabel.Text                   = "Stage 0"
	stageLabel.TextColor3             = Color3.fromRGB(255, 220, 50)
	stageLabel.Font                   = Enum.Font.GothamBold
	stageLabel.TextSize               = 22
	stageLabel.TextXAlignment         = Enum.TextXAlignment.Right
	stageLabel.Parent                 = topBar

	-- 下部ステータスバー（画面下部中央）
	local bottomBar = Instance.new("Frame")
	bottomBar.Name                   = "StatusBar"
	bottomBar.AnchorPoint            = Vector2.new(0.5, 1)
	bottomBar.Size                   = UDim2.new(0, 520, 0, 50)
	bottomBar.Position               = UDim2.new(0.5, 0, 1, -8)
	bottomBar.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
	bottomBar.BackgroundTransparency = 0.3
	bottomBar.BorderSizePixel        = 0
	bottomBar.Parent                 = sg

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 12)
	barCorner.Parent       = bottomBar

	local barList = Instance.new("UIListLayout")
	barList.FillDirection       = Enum.FillDirection.Horizontal
	barList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	barList.VerticalAlignment   = Enum.VerticalAlignment.Center
	barList.Padding             = UDim.new(0, 4)
	barList.Parent              = bottomBar

	local barPad = Instance.new("UIPadding")
	barPad.PaddingLeft  = UDim.new(0, 12)
	barPad.PaddingRight = UDim.new(0, 12)
	barPad.Parent       = bottomBar

	-- アイテム定義と区切り
	local barDefs = {
		{ key = "shoes", text = "👟スターターシューズ", color = Color3.fromRGB(180, 220, 255), w = 155 },
		{ sep = true },
		{ key = "click", text = "💪+5/tap",             color = Color3.fromRGB(120, 255, 160), w = 90  },
		{ sep = true },
		{ key = "gauge", text = "⚡0",                  color = Color3.fromRGB(150, 220, 255), w = 110 },
		{ sep = true },
		{ key = "coins", text = "💰0",                  color = Color3.fromRGB(255, 215, 0),   w = 90  },
	}

	for _, def in ipairs(barDefs) do
		if def.sep then
			local sep = Instance.new("TextLabel")
			sep.BackgroundTransparency = 1
			sep.Text       = "|"
			sep.TextColor3 = Color3.fromRGB(80, 80, 80)
			sep.Font       = Enum.Font.Gotham
			sep.TextSize   = 16
			sep.Size       = UDim2.new(0, 10, 1, 0)
			sep.Parent     = bottomBar
		else
			local lbl = Instance.new("TextLabel")
			lbl.BackgroundTransparency = 1
			lbl.Text                   = def.text
			lbl.TextColor3             = def.color
			lbl.Font                   = Enum.Font.GothamBold
			lbl.TextSize               = 15
			lbl.TextXAlignment         = Enum.TextXAlignment.Center
			lbl.TextTruncate           = Enum.TextTruncate.AtEnd
			lbl.Size                   = UDim2.new(0, def.w, 1, 0)
			lbl.Parent                 = bottomBar
			statusBarLabels[def.key]   = lbl
		end
	end

	-- 進化演出テキスト（画面中央・ZIndex最前面）
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
	evolutionNotice.Parent                 = sg

	local noticeCorner = Instance.new("UICorner")
	noticeCorner.CornerRadius = UDim.new(0, 14)
	noticeCorner.Parent       = evolutionNotice

	TrainingUI.updateDisplay()
end

return TrainingUI
