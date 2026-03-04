-- ミニHUD: 画面左上に常時表示するステータス情報

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local PlayerData = require(ReplicatedStorage.Shared.PlayerData)
local Config     = require(ReplicatedStorage.Shared.Config)

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local MiniHUD = {}

local initialized = false

local ROW_DEFS = {
	{ key = "JumpPower",    icon = "💪",   label = "ジャンプ力", suffix = ""   },
	{ key = "Speed",        icon = "🏃",   label = "スピード",   suffix = ""   },
	{ key = "PowerGauge",   icon = "⚡",   label = "パワー",     suffix = ""   },
	{ key = "Coins",        icon = "💰",   label = "コイン",     suffix = ""   },
	{ key = "RebirthCount", icon = "🔄",   label = "リバース",   suffix = "回" },
	{ key = "EquippedShoes",icon = "👟",   label = "装備",       suffix = ""   },
	{ key = "MaxAltitude",  icon = "🏔️", label = "最高高度",   suffix = "m"  },
	{ key = "Stage",        icon = "⭐",   label = "Stage",      suffix = ""   },
}

local rowLabels = {} :: { [string]: TextLabel }
local hudFrame  = nil :: Frame?

-- ─────────────────────────────────────────
-- ポップアニメーション
-- ─────────────────────────────────────────

local function popLabel(lbl: TextLabel)
	local sc = lbl:FindFirstChildOfClass("UIScale")
	if not sc then
		sc        = Instance.new("UIScale")
		sc.Scale  = 1
		sc.Parent = lbl
	end
	TweenService:Create(sc, TweenInfo.new(0.07, Enum.EasingStyle.Quad), { Scale = 1.2 }):Play()
	task.delay(0.07, function()
		TweenService:Create(sc, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { Scale = 1.0 }):Play()
	end)
end

-- ─────────────────────────────────────────
-- 公開API
-- ─────────────────────────────────────────

function MiniHUD.update()
	if not initialized then return end
	local d     = PlayerData.getData()
	local stage = PlayerData.getEvolutionStage()

	for _, row in ipairs(ROW_DEFS) do
		local lbl = rowLabels[row.key]
		if not lbl then continue end

		local newText

		if row.key == "Stage" then
			newText = row.icon .. " " .. row.label .. ": " .. stage

		elseif row.key == "RebirthCount" then
			local count = d.RebirthCount :: number
			local nextN = count + 1
			local cb    = nextN * Config.Rebirth.ClickBonusPerRebirth
			newText = row.icon .. " " .. row.label .. ": " .. count .. row.suffix
				.. "  (次: +" .. cb .. ")"

		elseif row.key == "EquippedShoes" then
			local shoes = Config.Shoes[d.EquippedShoes]
			local name  = if shoes then shoes.name else "なし"
			newText = row.icon .. " " .. row.label .. ": " .. name

		else
			newText = row.icon .. " " .. row.label .. ": "
				.. math.floor(d[row.key] :: number) .. row.suffix
		end

		if newText ~= lbl.Text then
			lbl.Text = newText
			popLabel(lbl)
		end
	end
end

function MiniHUD.init()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name         = "MiniHUD"
	screenGui.ResetOnSpawn = false
	screenGui.Parent       = PlayerGui

	-- 背景フレーム（グラジエント付き）
	local frame = Instance.new("Frame")
	frame.Name                   = "HUDFrame"
	frame.Size                   = UDim2.new(0, 230, 0, 16)
	frame.Position               = UDim2.new(0, 12, 0, 76)
	frame.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
	frame.BackgroundTransparency = 0.3
	frame.BorderSizePixel        = 0
	frame.Parent                 = screenGui
	hudFrame = frame

	-- グラジエント背景
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(8, 12, 30)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 22, 50)),
	})
	grad.Rotation = 135
	grad.Parent   = frame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent       = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft   = UDim.new(0, 10)
	padding.PaddingRight  = UDim.new(0, 10)
	padding.PaddingTop    = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.Parent        = frame

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection     = Enum.FillDirection.Vertical
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	listLayout.Padding           = UDim.new(0, 2)
	listLayout.Parent            = frame

	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		frame.Size = UDim2.new(0, 230, 0, listLayout.AbsoluteContentSize.Y + 16)
	end)

	for _, row in ipairs(ROW_DEFS) do
		local lbl = Instance.new("TextLabel")
		lbl.Name                   = row.key .. "Label"
		lbl.Size                   = UDim2.new(1, 0, 0, 20)
		lbl.BackgroundTransparency = 1
		lbl.Text                   = row.icon .. " " .. row.label .. ": 0" .. row.suffix
		lbl.TextColor3             = Color3.fromRGB(230, 230, 230)
		lbl.Font                   = Enum.Font.Gotham
		lbl.TextSize               = 15
		lbl.TextXAlignment         = Enum.TextXAlignment.Left
		lbl.Parent                 = frame

		if row.key == "Coins" then
			lbl.TextColor3 = Color3.fromRGB(255, 215, 0)
			lbl.TextSize   = 17
			lbl.Font       = Enum.Font.GothamBold
		end

		if row.key == "EquippedShoes" then
			lbl.TextColor3 = Color3.fromRGB(180, 220, 255)
			lbl.TextSize   = 13
		end

		rowLabels[row.key] = lbl
	end

	-- リセットボタン（最下部）
	local resetBtn = Instance.new("TextButton")
	resetBtn.Size             = UDim2.new(1, 0, 0, 26)
	resetBtn.BackgroundColor3 = Color3.fromRGB(70, 20, 20)
	resetBtn.BorderSizePixel  = 0
	resetBtn.Text             = "🔄 リセット"
	resetBtn.TextColor3       = Color3.fromRGB(200, 140, 140)
	resetBtn.Font             = Enum.Font.Gotham
	resetBtn.TextSize         = 13
	resetBtn.AutoButtonColor  = false
	resetBtn.Parent           = frame

	local resetCorner = Instance.new("UICorner")
	resetCorner.CornerRadius = UDim.new(0, 6)
	resetCorner.Parent       = resetBtn

	resetBtn.MouseButton1Click:Connect(function()
		PlayerData.reset()
		-- 循環参照を避けるためlazy require
		local AltitudeTracker = require(script.Parent.AltitudeTracker)
		AltitudeTracker.resetMilestones()
		MiniHUD.update()
	end)

	resetBtn.MouseEnter:Connect(function()
		TweenService:Create(resetBtn, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(110, 30, 30) }):Play()
	end)
	resetBtn.MouseLeave:Connect(function()
		TweenService:Create(resetBtn, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(70, 20, 20) }):Play()
	end)

	initialized = true
	MiniHUD.update()
end

return MiniHUD
