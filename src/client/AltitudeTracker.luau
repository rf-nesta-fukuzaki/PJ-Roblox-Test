-- 高度追跡・表示モジュール

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")

local PlayerData   = require(ReplicatedStorage.Shared.PlayerData)
local MiniHUD      = require(script.Parent.MiniHUD)
local Effects      = require(script.Parent.Effects)
local SoundManager = require(script.Parent.SoundManager)

local LocalPlayer = Players.LocalPlayer

local AltitudeTracker = {}

-- ─────────────────────────────────────────
-- 高度マーカー定義
-- ─────────────────────────────────────────

local MARKERS = {
	{ altitude = 100,  icon = "☁️",  text = "100m突破！"  },
	{ altitude = 500,  icon = "✨",  text = "500m突破！"  },
	{ altitude = 1000, icon = "⭐",  text = "1000m突破！" },
	{ altitude = 2000, icon = "🌟",  text = "2000m突破！" },
	{ altitude = 5000, icon = "🚀",  text = "5000m突破！" },
}

-- ─────────────────────────────────────────
-- 内部状態
-- ─────────────────────────────────────────

local passedMarkers          = {} :: { [number]: boolean }
local recordNoticeVersion    = 0
local milestoneNoticeVersion = 0

-- 着地検出
local wasAirborne = false
local peakY       = 0

local currentAltLabel = nil :: TextLabel?
local bestAltLabel    = nil :: TextLabel?
local recordNotice    = nil :: TextLabel?
local milestoneNotice = nil :: TextLabel?

-- ─────────────────────────────────────────
-- 通知ヘルパー
-- ─────────────────────────────────────────

local function showRecordNotice(altitude: number)
	if not recordNotice then return end
	recordNoticeVersion += 1
	local v = recordNoticeVersion

	recordNotice.Text                   = "🎉 新記録！ " .. altitude .. "m！"
	recordNotice.TextTransparency       = 0
	recordNotice.BackgroundTransparency = 0.15
	recordNotice.Visible                = true

	TweenService:Create(
		recordNotice,
		TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ TextTransparency = 1, BackgroundTransparency = 1 }
	):Play()

	task.delay(2, function()
		if recordNoticeVersion == v then
			recordNotice.Visible = false
		end
	end)
end

local function showMilestoneNotice(icon: string, text: string)
	if not milestoneNotice then return end
	milestoneNoticeVersion += 1
	local v = milestoneNoticeVersion

	milestoneNotice.Text                   = icon .. " " .. text
	milestoneNotice.TextTransparency       = 0
	milestoneNotice.BackgroundTransparency = 0.15
	milestoneNotice.Visible                = true

	TweenService:Create(
		milestoneNotice,
		TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ TextTransparency = 1, BackgroundTransparency = 1 }
	):Play()

	task.delay(1.5, function()
		if milestoneNoticeVersion == v then
			milestoneNotice.Visible = false
		end
	end)
end

-- ─────────────────────────────────────────
-- 公開API
-- ─────────────────────────────────────────

function AltitudeTracker.resetMilestones()
	passedMarkers = {}
	wasAirborne   = false
	peakY         = 0
end

function AltitudeTracker.init()
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	-- ScreenGui ------------------------------------------------
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name         = "AltitudeHUD"
	screenGui.ResetOnSpawn = false
	screenGui.Parent       = playerGui

	-- 右側パネル -----------------------------------------------
	local panel = Instance.new("Frame")
	panel.Name                   = "AltitudePanel"
	panel.AnchorPoint            = Vector2.new(1, 0)
	panel.Size                   = UDim2.new(0, 170, 0, 64)
	panel.Position               = UDim2.new(1, -12, 0, 76)
	panel.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
	panel.BackgroundTransparency = 0.45
	panel.BorderSizePixel        = 0
	panel.Parent                 = screenGui

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 8)
	panelCorner.Parent       = panel

	local panelPad = Instance.new("UIPadding")
	panelPad.PaddingLeft   = UDim.new(0, 10)
	panelPad.PaddingRight  = UDim.new(0, 10)
	panelPad.PaddingTop    = UDim.new(0, 8)
	panelPad.PaddingBottom = UDim.new(0, 8)
	panelPad.Parent        = panel

	local panelList = Instance.new("UIListLayout")
	panelList.FillDirection     = Enum.FillDirection.Vertical
	panelList.VerticalAlignment = Enum.VerticalAlignment.Top
	panelList.Padding           = UDim.new(0, 4)
	panelList.Parent            = panel

	currentAltLabel = Instance.new("TextLabel")
	currentAltLabel.Name                   = "CurrentAlt"
	currentAltLabel.Size                   = UDim2.new(1, 0, 0, 24)
	currentAltLabel.BackgroundTransparency = 1
	currentAltLabel.Text                   = "📍 現在高度: 0m"
	currentAltLabel.TextColor3             = Color3.fromRGB(180, 230, 255)
	currentAltLabel.Font                   = Enum.Font.GothamBold
	currentAltLabel.TextSize               = 14
	currentAltLabel.TextXAlignment         = Enum.TextXAlignment.Left
	currentAltLabel.Parent                 = panel

	bestAltLabel = Instance.new("TextLabel")
	bestAltLabel.Name                   = "BestAlt"
	bestAltLabel.Size                   = UDim2.new(1, 0, 0, 20)
	bestAltLabel.BackgroundTransparency = 1
	bestAltLabel.Text                   = "🏔️ 自己ベスト: 0m"
	bestAltLabel.TextColor3             = Color3.fromRGB(255, 220, 100)
	bestAltLabel.Font                   = Enum.Font.Gotham
	bestAltLabel.TextSize               = 14
	bestAltLabel.TextXAlignment         = Enum.TextXAlignment.Left
	bestAltLabel.Parent                 = panel

	-- 新記録通知（画面中央やや上）-------------------------------
	recordNotice = Instance.new("TextLabel")
	recordNotice.Name                   = "RecordNotice"
	recordNotice.AnchorPoint            = Vector2.new(0.5, 0.5)
	recordNotice.Size                   = UDim2.new(0, 460, 0, 72)
	recordNotice.Position               = UDim2.new(0.5, 0, 0.35, 0)
	recordNotice.BackgroundColor3       = Color3.fromRGB(20, 40, 80)
	recordNotice.BackgroundTransparency = 1
	recordNotice.Text                   = ""
	recordNotice.TextColor3             = Color3.fromRGB(100, 220, 255)
	recordNotice.Font                   = Enum.Font.GothamBold
	recordNotice.TextSize               = 30
	recordNotice.Visible                = false
	recordNotice.ZIndex                 = 10
	recordNotice.Parent                 = screenGui

	local recordCorner = Instance.new("UICorner")
	recordCorner.CornerRadius = UDim.new(0, 14)
	recordCorner.Parent       = recordNotice

	-- マイルストーン通知（画面中央）-----------------------------
	milestoneNotice = Instance.new("TextLabel")
	milestoneNotice.Name                   = "MilestoneNotice"
	milestoneNotice.AnchorPoint            = Vector2.new(0.5, 0.5)
	milestoneNotice.Size                   = UDim2.new(0, 360, 0, 60)
	milestoneNotice.Position               = UDim2.new(0.5, 0, 0.48, 0)
	milestoneNotice.BackgroundColor3       = Color3.fromRGB(20, 50, 20)
	milestoneNotice.BackgroundTransparency = 1
	milestoneNotice.Text                   = ""
	milestoneNotice.TextColor3             = Color3.fromRGB(150, 255, 150)
	milestoneNotice.Font                   = Enum.Font.GothamBold
	milestoneNotice.TextSize               = 24
	milestoneNotice.Visible                = false
	milestoneNotice.ZIndex                 = 10
	milestoneNotice.Parent                 = screenGui

	local milestoneCorner = Instance.new("UICorner")
	milestoneCorner.CornerRadius = UDim.new(0, 12)
	milestoneCorner.Parent       = milestoneNotice

	-- Heartbeatで高度を監視（0.1秒間隔）-----------------------
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt: number)
		elapsed += dt
		if elapsed < 0.1 then return end
		elapsed = 0

		local char = LocalPlayer.Character
		if not char then return end
		local root     = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = char:FindFirstChildOfClass("Humanoid")  :: Humanoid?
		if not root or not humanoid then return end

		local rawY     = root.Position.Y
		local altitude = math.floor(math.max(0, rawY))

		-- 高度表示（高さに応じてテキストサイズ 14→22 に変化）
		currentAltLabel.TextSize = math.clamp(14 + rawY * 0.003, 14, 22)
		currentAltLabel.Text     = "📍 現在高度: " .. altitude .. "m"

		local d = PlayerData.getData()
		bestAltLabel.Text = "🏔️ 自己ベスト: " .. (d.MaxAltitude :: number) .. "m"

		-- 自己ベスト更新（地面より上のみ）
		if rawY > 0 and PlayerData.updateMaxAltitude(altitude) then
			showRecordNotice(altitude)
			Effects.newRecordFlash()
			SoundManager.playNewRecord()
			MiniHUD.update()
		end

		-- 高度マーカー通過チェック
		for _, marker in ipairs(MARKERS) do
			if not passedMarkers[marker.altitude] and altitude >= marker.altitude then
				passedMarkers[marker.altitude] = true
				showMilestoneNotice(marker.icon, marker.text)
			end
		end

		-- 着地検出: 空中→着地、かつ落下距離 >= 50 スタッド
		local airborne = humanoid.FloorMaterial == Enum.Material.Air
		if airborne then
			peakY = math.max(peakY, rawY)
		else
			if wasAirborne then
				local fallDist = peakY - rawY
				if fallDist >= 50 then
					Effects.landingDust(root.Position)
					SoundManager.playLanding()
				end
				peakY = rawY
			end
		end
		wasAirborne = airborne
	end)
end

return AltitudeTracker
