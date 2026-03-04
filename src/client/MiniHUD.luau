-- ミニHUD: 画面左上に常時表示するステータス情報

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerData = require(ReplicatedStorage.Shared.PlayerData)

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local MiniHUD = {}

local initialized = false

local ROW_DEFS = {
	{ key = "JumpPower",   icon = "💪",  label = "ジャンプ力" },
	{ key = "Speed",       icon = "🏃",  label = "スピード"   },
	{ key = "MaxAltitude", icon = "🏔️", label = "最高高度"   },
	{ key = "Stage",       icon = "⭐",  label = "Stage"      },
}

local rowLabels = {} :: { [string]: TextLabel }

-- ─────────────────────────────────────────
-- 公開API
-- ─────────────────────────────────────────

function MiniHUD.update()
	if not initialized then return end
	local d     = PlayerData.getData()
	local stage = PlayerData.getEvolutionStage()
	for _, row in ipairs(ROW_DEFS) do
		local value: number | string = if row.key == "Stage"
			then stage
			else (d[row.key] :: number)
		local suffix = if row.key == "MaxAltitude" then "m" else ""
		rowLabels[row.key].Text = row.icon .. " " .. row.label .. ": " .. value .. suffix
	end
end

function MiniHUD.init()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name         = "MiniHUD"
	screenGui.ResetOnSpawn = false
	screenGui.Parent       = PlayerGui

	-- 背景フレーム（半透明の黒）
	-- 行数4 × 行高20 + ギャップ2 × 3 + 上下パディング16 = 102px
	local frame = Instance.new("Frame")
	frame.Name                   = "HUDFrame"
	frame.Size                   = UDim2.new(0, 190, 0, 102)
	frame.Position               = UDim2.new(0, 12, 0, 76)
	frame.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
	frame.BackgroundTransparency = 0.45
	frame.BorderSizePixel        = 0
	frame.Parent                 = screenGui

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

	for _, row in ipairs(ROW_DEFS) do
		local lbl = Instance.new("TextLabel")
		lbl.Name                   = row.key .. "Label"
		lbl.Size                   = UDim2.new(1, 0, 0, 20)
		lbl.BackgroundTransparency = 1
		lbl.Text                   = row.icon .. " " .. row.label .. ": 0"
		lbl.TextColor3             = Color3.fromRGB(230, 230, 230)
		lbl.Font                   = Enum.Font.Gotham
		lbl.TextSize               = 15
		lbl.TextXAlignment         = Enum.TextXAlignment.Left
		lbl.Parent                 = frame

		rowLabels[row.key] = lbl
	end

	initialized = true
	MiniHUD.update()
end

return MiniHUD
