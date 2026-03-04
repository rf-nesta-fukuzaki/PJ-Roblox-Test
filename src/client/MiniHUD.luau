-- ミニHUD: 画面左上に常時表示するステータス情報

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerData = require(ReplicatedStorage.Shared.PlayerData)
local Config     = require(ReplicatedStorage.Shared.Config)

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local MiniHUD = {}

local initialized = false

local ROW_DEFS = {
	{ key = "JumpPower",    icon = "💪",  label = "ジャンプ力", suffix = ""   },
	{ key = "Speed",        icon = "🏃",  label = "スピード",   suffix = ""   },
	{ key = "PowerGauge",   icon = "⚡",  label = "パワー",     suffix = ""   },
	{ key = "Coins",        icon = "💰",  label = "コイン",     suffix = ""   },
	{ key = "RebirthCount", icon = "🔄",  label = "リバース",   suffix = "回" },
	{ key = "EquippedShoes",icon = "👟",  label = "装備",       suffix = ""   },
	{ key = "MaxAltitude",  icon = "🏔️", label = "最高高度",   suffix = "m"  },
	{ key = "Stage",        icon = "⭐",  label = "Stage",      suffix = ""   },
}

local rowLabels = {} :: { [string]: TextLabel }
local hudFrame  = nil :: Frame?

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

		if row.key == "Stage" then
			lbl.Text = row.icon .. " " .. row.label .. ": " .. stage

		elseif row.key == "RebirthCount" then
			local count  = d.RebirthCount :: number
			local nextN  = count + 1
			local cb     = nextN * Config.Rebirth.ClickBonusPerRebirth
			lbl.Text = row.icon .. " " .. row.label .. ": " .. count .. row.suffix
				.. "  (次: +" .. cb .. ")"

		elseif row.key == "EquippedShoes" then
			local shoes = Config.Shoes[d.EquippedShoes]
			local name  = if shoes then shoes.name else "なし"
			lbl.Text = row.icon .. " " .. row.label .. ": " .. name

		else
			lbl.Text = row.icon .. " " .. row.label .. ": "
				.. math.floor(d[row.key] :: number) .. row.suffix
		end
	end
end

function MiniHUD.init()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name         = "MiniHUD"
	screenGui.ResetOnSpawn = false
	screenGui.Parent       = PlayerGui

	-- 背景フレーム（高さはUIListLayoutが自動調整）
	local frame = Instance.new("Frame")
	frame.Name                   = "HUDFrame"
	frame.Size                   = UDim2.new(0, 230, 0, 16)
	frame.Position               = UDim2.new(0, 12, 0, 76)
	frame.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
	frame.BackgroundTransparency = 0.45
	frame.BorderSizePixel        = 0
	frame.Parent                 = screenGui
	hudFrame = frame

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

		-- Coinsは金色・やや大きめ
		if row.key == "Coins" then
			lbl.TextColor3 = Color3.fromRGB(255, 215, 0)
			lbl.TextSize   = 17
			lbl.Font       = Enum.Font.GothamBold
		end

		-- EquippedShoesは少し小さめ
		if row.key == "EquippedShoes" then
			lbl.TextColor3 = Color3.fromRGB(180, 220, 255)
			lbl.TextSize   = 13
		end

		rowLabels[row.key] = lbl
	end

	initialized = true
	MiniHUD.update()
end

return MiniHUD
