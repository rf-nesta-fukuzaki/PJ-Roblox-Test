-- ゲーム全体の初期化を集約するモジュール

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local GameFlow = {}

function GameFlow.init()
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	-- ─────────────────────────────────────────
	-- 全モジュールの初期化（依存関係に沿った順序）
	-- ─────────────────────────────────────────
	local Effects            = require(script.Parent.Effects)
	local SoundManager       = require(script.Parent.SoundManager)
	local MiniHUD            = require(script.Parent.MiniHUD)
	local TrainingUI         = require(script.Parent.TrainingUI)
	local MovementController = require(script.Parent.MovementController)
	local DistanceTracker    = require(script.Parent.DistanceTracker)
	local RebirthUI          = require(script.Parent.RebirthUI)
	local ShopUI             = require(script.Parent.ShopUI)
	local ZoneDetector       = require(script.Parent.ZoneDetector)
	local AltitudeTracker    = require(script.Parent.AltitudeTracker)
	local KillBrickHandler   = require(script.Parent.KillBrickHandler)

	Effects.initFallPlatformListener()
	SoundManager.init()
	MiniHUD.init()
	TrainingUI.init()
	MovementController.init()
	DistanceTracker.init()
	RebirthUI.init()
	ShopUI.init()
	ZoneDetector.init()
	AltitudeTracker.init()
	KillBrickHandler.init()

	-- ─────────────────────────────────────────
	-- ウェルカムメッセージ（初回スポーン時に3秒表示）
	-- ─────────────────────────────────────────
	local sg = Instance.new("ScreenGui")
	sg.Name         = "WelcomeScreen"
	sg.ResetOnSpawn = false
	sg.Parent       = playerGui

	local bg = Instance.new("Frame")
	bg.Name                   = "WelcomeBg"
	bg.AnchorPoint            = Vector2.new(0.5, 0.5)
	bg.Size                   = UDim2.new(0, 560, 0, 150)
	bg.Position               = UDim2.new(0.5, 0, 0.40, 0)
	bg.BackgroundColor3       = Color3.fromRGB(10, 10, 20)
	bg.BackgroundTransparency = 0.15
	bg.BorderSizePixel        = 0
	bg.ZIndex                 = 20
	bg.Parent                 = sg

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 20)
	bgCorner.Parent       = bg

	local bgList = Instance.new("UIListLayout")
	bgList.FillDirection       = Enum.FillDirection.Vertical
	bgList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	bgList.VerticalAlignment   = Enum.VerticalAlignment.Center
	bgList.Padding             = UDim.new(0, 10)
	bgList.Parent              = bg

	local bgPad = Instance.new("UIPadding")
	bgPad.PaddingLeft   = UDim.new(0, 20)
	bgPad.PaddingRight  = UDim.new(0, 20)
	bgPad.PaddingTop    = UDim.new(0, 16)
	bgPad.PaddingBottom = UDim.new(0, 16)
	bgPad.Parent        = bg

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name                   = "Title"
	titleLabel.Size                   = UDim2.new(1, 0, 0, 50)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text                   = "🌟 Dash to the Stars 🌟"
	titleLabel.TextColor3             = Color3.fromRGB(255, 215, 0)
	titleLabel.Font                   = Enum.Font.GothamBold
	titleLabel.TextSize               = 34
	titleLabel.ZIndex                 = 21
	titleLabel.Parent                 = bg

	local subLabel = Instance.new("TextLabel")
	subLabel.Name                   = "Sub"
	subLabel.Size                   = UDim2.new(1, 0, 0, 26)
	subLabel.BackgroundTransparency = 1
	subLabel.Text                   = "トレーニングで鍛えて、空の足場を目指そう！"
	subLabel.TextColor3             = Color3.fromRGB(220, 220, 220)
	subLabel.Font                   = Enum.Font.Gotham
	subLabel.TextSize               = 18
	subLabel.ZIndex                 = 21
	subLabel.Parent                 = bg

	-- 3秒後にフェードアウト → 1秒後に削除
	task.delay(3, function()
		local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(bg,         tweenInfo, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(titleLabel, tweenInfo, { TextTransparency = 1 }):Play()
		TweenService:Create(subLabel,   tweenInfo, { TextTransparency = 1 }):Play()
		task.delay(1, function()
			sg:Destroy()
		end)
	end)
end

return GameFlow
