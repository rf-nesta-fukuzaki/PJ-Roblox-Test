-- 走行距離トラッカー: 水平移動距離でSpeedとPowerGaugeを上げる

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local PlayerData         = require(ReplicatedStorage.Shared.PlayerData)
local MiniHUD            = require(script.Parent.MiniHUD)
local MovementController = require(script.Parent.MovementController)

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local DistanceTracker = {}

-- ─────────────────────────────────────────
-- 定数
-- ─────────────────────────────────────────
local MIN_HORIZONTAL   = 0.5   -- カウントする最小水平移動距離（スタッド）
local TELEPORT_LIMIT   = 50    -- これ以上の移動はテレポートとして無視
local UPDATE_INTERVAL  = 0.2   -- PlayerData/UI更新のスロットリング間隔（秒）

-- ─────────────────────────────────────────
-- 状態
-- ─────────────────────────────────────────
local prevPosition      = nil :: Vector3?
local accumulatedDist   = 0
local lastUpdateTime    = 0
local movingNow         = false

-- UI参照
local distanceLabel = nil :: TextLabel?
local meterScale    = nil :: UIScale?

-- ─────────────────────────────────────────
-- UI構築
-- ─────────────────────────────────────────
local function buildUI()
	local sg = Instance.new("ScreenGui")
	sg.Name         = "DistanceMeter"
	sg.ResetOnSpawn = false
	sg.Parent       = PlayerGui

	local bg = Instance.new("Frame")
	bg.Name                   = "MeterBg"
	bg.AnchorPoint            = Vector2.new(0.5, 1)
	bg.Size                   = UDim2.new(0, 390, 0, 44)
	bg.Position               = UDim2.new(0.5, 0, 1, -8)
	bg.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
	bg.BackgroundTransparency = 0.45
	bg.BorderSizePixel        = 0
	bg.Parent                 = sg

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent       = bg

	local uiScale = Instance.new("UIScale")
	uiScale.Scale  = 1
	uiScale.Parent = bg
	meterScale = uiScale

	local lbl = Instance.new("TextLabel")
	lbl.Name                   = "MeterLabel"
	lbl.Size                   = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text                   = "🏃 走行距離: 0m | スピード: +0"
	lbl.TextColor3             = Color3.fromRGB(100, 220, 100)
	lbl.Font                   = Enum.Font.GothamBold
	lbl.TextSize               = 18
	lbl.Parent                 = bg

	distanceLabel = lbl
end

-- ─────────────────────────────────────────
-- ヘルパー
-- ─────────────────────────────────────────
local function refreshLabel()
	if not distanceLabel then return end
	local d = PlayerData.getData()
	distanceLabel.Text = "🏃 走行距離: " .. math.floor(d.TotalDistance) .. "m | スピード: +" .. math.floor(d.Speed)
end

local function setMovingAnim(moving: boolean)
	if moving == movingNow then return end
	movingNow = moving
	if not meterScale then return end
	TweenService:Create(
		meterScale,
		TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Scale = if moving then 1.08 else 1.0 }
	):Play()
end

-- ─────────────────────────────────────────
-- キャラクター監視
-- ─────────────────────────────────────────
local heartbeatConn = nil :: RBXScriptConnection?

local function setupCharacter(character: Model)
	local hrp = character:WaitForChild("HumanoidRootPart") :: BasePart
	prevPosition = hrp.Position

	if heartbeatConn then
		heartbeatConn:Disconnect()
		heartbeatConn = nil
	end

	heartbeatConn = RunService.Heartbeat:Connect(function()
		if not hrp or not hrp.Parent then return end

		local pos = hrp.Position
		if not prevPosition then
			prevPosition = pos
			return
		end

		local delta = pos - prevPosition
		prevPosition = pos

		-- テレポート判定
		if delta.Magnitude > TELEPORT_LIMIT then return end

		-- 水平移動距離のみカウント
		local horizontal = math.sqrt(delta.X * delta.X + delta.Z * delta.Z)

		if horizontal < MIN_HORIZONTAL then
			setMovingAnim(false)
			return
		end

		setMovingAnim(true)
		accumulatedDist += horizontal

		-- スロットリング
		local now = tick()
		if now - lastUpdateTime >= UPDATE_INTERVAL then
			lastUpdateTime = now
			PlayerData.addDistance(accumulatedDist)
			accumulatedDist = 0
			refreshLabel()
			MiniHUD.update()
			MovementController.update()
		end
	end)
end

-- ─────────────────────────────────────────
-- 公開API
-- ─────────────────────────────────────────
function DistanceTracker.init()
	buildUI()

	if LocalPlayer.Character then
		setupCharacter(LocalPlayer.Character)
	end

	LocalPlayer.CharacterAdded:Connect(function(character)
		prevPosition    = nil
		accumulatedDist = 0
		setupCharacter(character)
	end)
end

return DistanceTracker
