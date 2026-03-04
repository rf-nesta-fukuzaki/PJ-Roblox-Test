-- ショップUI（シューズ・トレイル購入）

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local PlayerData   = require(ReplicatedStorage.Shared.PlayerData)
local Config       = require(ReplicatedStorage.Shared.Config)
local MiniHUD      = require(script.Parent.MiniHUD)
local TrainingUI   = require(script.Parent.TrainingUI)
local SoundManager = require(script.Parent.SoundManager)
local Effects      = require(script.Parent.Effects)

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local ShopUI = {}

-- ─────────────────────────────────────────
-- 内部参照
-- ─────────────────────────────────────────
local screenGui   = nil :: ScreenGui?
local mainPanel   = nil :: Frame?
local coinsLabel  = nil :: TextLabel?
local scrollFrame = nil :: ScrollingFrame?
local listLayout  = nil :: UIListLayout?

local currentTab = "shoes"  -- "shoes" | "trails"
local tabBtns    = {} :: { [string]: TextButton }

-- ─────────────────────────────────────────
-- カラー定数（仕様通り）
-- ─────────────────────────────────────────
local TAB_ACTIVE   = Color3.fromRGB(52, 152, 219)
local TAB_INACTIVE = Color3.fromRGB(50, 50, 70)

local BTN_BUY      = Color3.fromRGB(30,  200,  60)   -- 購入可能（鮮緑）
local BTN_NOFUND   = Color3.fromRGB(220,  50,  50)   -- コイン不足（鮮赤）
local BTN_EQUIP    = Color3.fromRGB(50,  130, 230)   -- 装備可能（鮮青）
local BTN_EQUIPPED = Color3.fromRGB(140,  50, 200)   -- 装備中（紫）

-- シューズカラーマッピング（足元パーティクル用）
local SHOE_COLORS: { [string]: Color3 } = {
	starter   = Color3.fromRGB(100, 160, 220),
	runner    = Color3.fromRGB(100, 220, 100),
	springs   = Color3.fromRGB(255, 210, 50),
	rocket    = Color3.fromRGB(255, 100, 50),
	legendary = Color3.fromRGB(255, 215, 0),
	galaxy    = Color3.fromRGB(150, 80, 255),
}

-- アイコンマッピング（idから絵文字）
local ICON_MAP: { [string]: string } = {
	starter   = "👟",
	runner    = "🏃",
	springs   = "🦘",
	rocket    = "🚀",
	legendary = "👑",
	galaxy    = "🌌",
	none      = "✖",
	fire      = "🔥",
	ice       = "❄",
	star      = "⭐",
	rainbow   = "🌈",
}

local function getItemIcon(id: string): string
	return ICON_MAP[id] or "📦"
end

-- ─────────────────────────────────────────
-- 購入可能ボタンのパルスアニメ（2秒ループ）
-- ─────────────────────────────────────────

local function startBuyPulse(btn: TextButton)
	local sc = Instance.new("UIScale")
	sc.Scale  = 1
	sc.Parent = btn

	local running = true
	-- ボタンが削除されたら停止
	btn.AncestryChanged:Connect(function()
		if not btn.Parent then running = false end
	end)

	task.spawn(function()
		while running and btn.Parent do
			TweenService:Create(sc, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { Scale = 1.05 }):Play()
			task.wait(0.5)
			TweenService:Create(sc, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { Scale = 1.0 }):Play()
			task.wait(1.0)
		end
	end)
end

-- ─────────────────────────────────────────
-- コイン不足テキスト表示（0.8秒）
-- ─────────────────────────────────────────

local function showShortageText(frame: Frame, shortage: number)
	-- 既存テキストがあれば削除
	local existing = frame:FindFirstChild("ShortageLabel")
	if existing then existing:Destroy() end

	local lbl = Instance.new("TextLabel")
	lbl.Name                   = "ShortageLabel"
	lbl.AnchorPoint            = Vector2.new(0.5, 1)
	lbl.Size                   = UDim2.new(1, -10, 0, 26)
	lbl.Position               = UDim2.new(0.5, 0, 1, -6)
	lbl.BackgroundTransparency = 1
	lbl.Text                   = "あと " .. shortage .. " コイン！"
	lbl.TextColor3             = Color3.fromRGB(255, 100, 100)
	lbl.Font                   = Enum.Font.GothamBold
	lbl.TextSize               = 14
	lbl.TextTransparency       = 0
	lbl.ZIndex                 = 13
	lbl.Parent                 = frame

	task.delay(0.8, function()
		if lbl.Parent then
			TweenService:Create(lbl, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
			task.delay(0.3, function() if lbl.Parent then lbl:Destroy() end end)
		end
	end)
end

-- ─────────────────────────────────────────
-- アイテム一覧の再構築
-- ─────────────────────────────────────────

local function rebuildItems()
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	local d        = PlayerData.getData()
	local coins    = d.Coins :: number
	local isShoes  = currentTab == "shoes"
	local order    = if isShoes then Config.ShoesOrder else Config.TrailsOrder
	local items    = if isShoes then Config.Shoes      else Config.Trails
	local equipped = if isShoes then d.EquippedShoes   else d.EquippedTrail

	local ITEM_H = 130

	for i, id in ipairs(order) do
		local item = items[id]
		if not item then continue end

		local owned   = if isShoes then PlayerData.hasShoes(id) else PlayerData.hasTrail(id)
		local isEquip = (equipped == id)
		local canBuy  = not owned and coins >= item.cost

		-- アイテムフレーム
		local frame = Instance.new("Frame")
		frame.Name                   = "Item_" .. id
		frame.Size                   = UDim2.new(1, -12, 0, ITEM_H)
		frame.BackgroundColor3       = Color3.fromRGB(25, 25, 45)
		frame.BackgroundTransparency = 0.2
		frame.BorderSizePixel        = 0
		frame.LayoutOrder            = i
		frame.Parent                 = scrollFrame

		local fCorner = Instance.new("UICorner")
		fCorner.CornerRadius = UDim.new(0, 10)
		fCorner.Parent       = frame

		-- アイコンフレーム（左端中央）
		local iconFrame = Instance.new("Frame")
		iconFrame.Name                   = "IconFrame"
		iconFrame.Size                   = UDim2.new(0, 56, 0, 56)
		iconFrame.Position               = UDim2.new(0, 10, 0.5, -28)
		iconFrame.BackgroundColor3       = Color3.fromRGB(40, 40, 70)
		iconFrame.BackgroundTransparency = 0
		iconFrame.BorderSizePixel        = 0
		iconFrame.Parent                 = frame

		local iconCorner = Instance.new("UICorner")
		iconCorner.CornerRadius = UDim.new(0, 12)
		iconCorner.Parent       = iconFrame

		local iconLbl = Instance.new("TextLabel")
		iconLbl.Size                   = UDim2.new(1, 0, 1, 0)
		iconLbl.BackgroundTransparency = 1
		iconLbl.Text                   = getItemIcon(id)
		iconLbl.TextSize               = 28
		iconLbl.Font                   = Enum.Font.GothamBold
		iconLbl.Parent                 = iconFrame

		-- アイテム名
		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size                   = UDim2.new(1, -200, 0, 24)
		nameLbl.Position               = UDim2.new(0, 76, 0, 10)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Text                   = item.name
		nameLbl.TextColor3             = Color3.fromRGB(255, 255, 255)
		nameLbl.Font                   = Enum.Font.GothamBold
		nameLbl.TextSize               = 16
		nameLbl.TextXAlignment         = Enum.TextXAlignment.Left
		nameLbl.Parent                 = frame

		-- 価格（右上）
		local priceLbl = Instance.new("TextLabel")
		priceLbl.Size                   = UDim2.new(0, 100, 0, 24)
		priceLbl.Position               = UDim2.new(1, -112, 0, 10)
		priceLbl.BackgroundTransparency = 1
		priceLbl.Text                   = if item.cost == 0 then "無料" else "💰 " .. item.cost
		priceLbl.TextColor3             = Color3.fromRGB(255, 215, 0)
		priceLbl.Font                   = Enum.Font.GothamBold
		priceLbl.TextSize               = 14
		priceLbl.TextXAlignment         = Enum.TextXAlignment.Right
		priceLbl.Parent                 = frame

		-- 説明（2行目）
		local descLbl = Instance.new("TextLabel")
		descLbl.Size                   = UDim2.new(1, -80, 0, 18)
		descLbl.Position               = UDim2.new(0, 76, 0, 36)
		descLbl.BackgroundTransparency = 1
		descLbl.Text                   = item.description
		descLbl.TextColor3             = Color3.fromRGB(180, 180, 180)
		descLbl.Font                   = Enum.Font.Gotham
		descLbl.TextSize               = 12
		descLbl.TextXAlignment         = Enum.TextXAlignment.Left
		descLbl.Parent                 = frame

		-- ボーナス表示（シューズのみ）
		if isShoes and item.clickBonus then
			local parts = {}
			if item.clickBonus > 0 then
				table.insert(parts, "クリック +" .. item.clickBonus)
			end
			if item.runBonus and item.runBonus > 0 then
				table.insert(parts, "走行 +" .. item.runBonus)
			end
			if #parts > 0 then
				local bonusLbl = Instance.new("TextLabel")
				bonusLbl.Size                   = UDim2.new(1, -80, 0, 16)
				bonusLbl.Position               = UDim2.new(0, 76, 0, 56)
				bonusLbl.BackgroundTransparency = 1
				bonusLbl.Text                   = "✦ " .. table.concat(parts, "  /  ")
				bonusLbl.TextColor3             = Color3.fromRGB(100, 220, 150)
				bonusLbl.Font                   = Enum.Font.Gotham
				bonusLbl.TextSize               = 11
				bonusLbl.TextXAlignment         = Enum.TextXAlignment.Left
				bonusLbl.Parent                 = frame
			end
		end

		-- プレビューテキスト（シューズのみ）
		if isShoes and item.clickBonus then
			local d2         = PlayerData.getData()
			local baseClick  = Config.Click.BasePerClick
			local rbBonus    = (d2.RebirthCount :: number) * Config.Rebirth.ClickBonusPerRebirth
			local previewPow = baseClick + (item.clickBonus or 0) + rbBonus
			local previewLbl = Instance.new("TextLabel")
			previewLbl.Size                   = UDim2.new(1, -80, 0, 16)
			previewLbl.Position               = UDim2.new(0, 76, 0, 74)
			previewLbl.BackgroundTransparency = 1
			previewLbl.Text                   = "装備すると: クリック +" .. math.floor(previewPow) .. "/tap になります"
			previewLbl.TextColor3             = Color3.fromRGB(160, 220, 255)
			previewLbl.Font                   = Enum.Font.Gotham
			previewLbl.TextSize               = 11
			previewLbl.TextXAlignment         = Enum.TextXAlignment.Left
			previewLbl.Parent                 = frame
		end

		-- ボタン（右下）
		local btn = Instance.new("TextButton")
		btn.Size            = UDim2.new(0, 110, 0, 34)
		btn.Position        = UDim2.new(1, -122, 1, -44)
		btn.BorderSizePixel = 0
		btn.Font            = Enum.Font.GothamBold
		btn.TextSize        = 14
		btn.TextColor3      = Color3.fromRGB(255, 255, 255)
		btn.Parent          = frame

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 8)
		btnCorner.Parent       = btn

		if isEquip then
			btn.Text             = "✓ 装備中"
			btn.BackgroundColor3 = BTN_EQUIPPED
			btn.Active           = false
		elseif owned then
			btn.Text             = "装備する"
			btn.BackgroundColor3 = BTN_EQUIP
			btn.Active           = true
		elseif canBuy then
			btn.Text             = "🛒 購入！"
			btn.BackgroundColor3 = BTN_BUY
			btn.Active           = true
			startBuyPulse(btn)
		else
			btn.Text             = "💰不足"
			btn.BackgroundColor3 = BTN_NOFUND
			btn.Active           = true  -- シェイク・テキスト表示のため
		end

		local capturedId    = id
		local capturedOwned = owned
		local capturedEquip = isEquip
		btn.MouseButton1Click:Connect(function()
			if not btn.Active then return end

			local d2 = PlayerData.getData()

			-- コイン不足の場合
			if not capturedOwned and not capturedEquip and d2.Coins < item.cost then
				Effects.shakeFrame(frame, 0.3)
				local shortage = item.cost - math.floor(d2.Coins)
				showShortageText(frame, shortage)
				return
			end

			local success = false
			if isShoes then
				if capturedOwned then
					success = PlayerData.equipShoes(capturedId)
				else
					success = PlayerData.buyShoes(capturedId)
					if success then PlayerData.equipShoes(capturedId) end
				end
			else
				if capturedOwned then
					success = PlayerData.equipTrail(capturedId)
				else
					success = PlayerData.buyTrail(capturedId)
					if success then PlayerData.equipTrail(capturedId) end
				end
			end

			if success then
				SoundManager.playPurchase()
				coinsLabel.Text = "💰 " .. math.floor(PlayerData.getData().Coins)

				-- シューズ装備エフェクト
				if isShoes then
					local shoeColor = SHOE_COLORS[capturedId] or Color3.fromRGB(100, 180, 255)
					local shoeData  = Config.Shoes[capturedId]
					local shoeName  = if shoeData then shoeData.name else capturedId
					local newPower  = PlayerData.getEffectiveClickPower()

					Effects.shoeEquipParticle(shoeColor)
					TrainingUI.bounceShoeLabel()
					Effects.showNotification(
						"👟 " .. shoeName .. " 装備！クリック力 → +" .. math.floor(newPower) .. "/tap",
						2
					)
				end

				rebuildItems()
				MiniHUD.update()
			end
		end)
	end

	-- CanvasSizeを自動更新
	task.defer(function()
		if listLayout then
			scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 8)
		end
	end)
end

-- ─────────────────────────────────────────
-- タブ切り替え
-- ─────────────────────────────────────────

local function switchTab(tab: string)
	currentTab = tab
	for id, tbtn in pairs(tabBtns) do
		tbtn.BackgroundColor3 = if id == tab then TAB_ACTIVE else TAB_INACTIVE
	end
	rebuildItems()
end

-- ─────────────────────────────────────────
-- 公開API（スライドアニメーション付き）
-- ─────────────────────────────────────────

local PANEL_CENTER  = UDim2.new(0.5, 0, 0.5, 0)
local PANEL_OFFSIDE = UDim2.new(1.5, 0, 0.5, 0)

function ShopUI.show()
	if not mainPanel then return end
	coinsLabel.Text    = "💰 " .. math.floor(PlayerData.getData().Coins)
	switchTab(currentTab)
	mainPanel.Position = PANEL_OFFSIDE
	mainPanel.Visible  = true
	TweenService:Create(
		mainPanel,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = PANEL_CENTER }
	):Play()
end

function ShopUI.hide()
	if not mainPanel then return end
	TweenService:Create(
		mainPanel,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Position = PANEL_OFFSIDE }
	):Play()
	task.delay(0.2, function()
		if mainPanel then mainPanel.Visible = false end
	end)
end

-- ─────────────────────────────────────────
-- UI構築
-- ─────────────────────────────────────────

function ShopUI.init()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name         = "ShopUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent       = PlayerGui

	-- メインパネル（初期非表示・右外）
	local panel = Instance.new("Frame")
	panel.Name                   = "MainPanel"
	panel.AnchorPoint            = Vector2.new(0.5, 0.5)
	panel.Size                   = UDim2.new(0, 600, 0, 500)
	panel.Position               = PANEL_OFFSIDE
	panel.BackgroundColor3       = Color3.fromRGB(15, 15, 30)
	panel.BackgroundTransparency = 0.12
	panel.BorderSizePixel        = 0
	panel.Visible                = false
	panel.ZIndex                 = 10
	panel.Parent                 = screenGui
	mainPanel = panel

	local pCorner = Instance.new("UICorner")
	pCorner.CornerRadius = UDim.new(0, 20)
	pCorner.Parent       = panel

	local pStroke = Instance.new("UIStroke")
	pStroke.Color     = Color3.fromRGB(80, 130, 200)
	pStroke.Thickness = 2
	pStroke.Parent    = panel

	-- タイトル
	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size                   = UDim2.new(1, -40, 0, 50)
	titleLbl.Position               = UDim2.new(0, 20, 0, 12)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text                   = "🛒 ショップ"
	titleLbl.TextColor3             = Color3.fromRGB(255, 255, 255)
	titleLbl.Font                   = Enum.Font.GothamBold
	titleLbl.TextSize               = 28
	titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
	titleLbl.ZIndex                 = 11
	titleLbl.Parent                 = panel

	-- コイン表示
	local coinsLbl = Instance.new("TextLabel")
	coinsLbl.Size                   = UDim2.new(0, 140, 0, 34)
	coinsLbl.Position               = UDim2.new(1, -160, 0, 20)
	coinsLbl.BackgroundTransparency = 1
	coinsLbl.Text                   = "💰 0"
	coinsLbl.TextColor3             = Color3.fromRGB(255, 215, 0)
	coinsLbl.Font                   = Enum.Font.GothamBold
	coinsLbl.TextSize               = 22
	coinsLbl.TextXAlignment         = Enum.TextXAlignment.Right
	coinsLbl.ZIndex                 = 11
	coinsLbl.Parent                 = panel
	coinsLabel = coinsLbl

	-- タブフレーム
	local tabFrame = Instance.new("Frame")
	tabFrame.Size                   = UDim2.new(1, -40, 0, 44)
	tabFrame.Position               = UDim2.new(0, 20, 0, 66)
	tabFrame.BackgroundTransparency = 1
	tabFrame.ZIndex                 = 11
	tabFrame.Parent                 = panel

	local tabList = Instance.new("UIListLayout")
	tabList.FillDirection       = Enum.FillDirection.Horizontal
	tabList.HorizontalAlignment = Enum.HorizontalAlignment.Left
	tabList.VerticalAlignment   = Enum.VerticalAlignment.Center
	tabList.Padding             = UDim.new(0, 10)
	tabList.Parent              = tabFrame

	local TAB_DEFS = {
		{ id = "shoes",  label = "👟 シューズ" },
		{ id = "trails", label = "✨ トレイル" },
	}

	for _, td in ipairs(TAB_DEFS) do
		local tbtn = Instance.new("TextButton")
		tbtn.Size             = UDim2.new(0, 130, 0, 40)
		tbtn.BackgroundColor3 = if td.id == "shoes" then TAB_ACTIVE else TAB_INACTIVE
		tbtn.BorderSizePixel  = 0
		tbtn.Text             = td.label
		tbtn.TextColor3       = Color3.fromRGB(255, 255, 255)
		tbtn.Font             = Enum.Font.GothamBold
		tbtn.TextSize         = 16
		tbtn.ZIndex           = 12
		tbtn.Parent           = tabFrame

		local tbtnCorner = Instance.new("UICorner")
		tbtnCorner.CornerRadius = UDim.new(0, 10)
		tbtnCorner.Parent       = tbtn

		local capturedId = td.id
		tbtn.MouseButton1Click:Connect(function()
			switchTab(capturedId)
		end)

		tabBtns[td.id] = tbtn
	end

	-- ScrollingFrame（アイテム一覧）
	local sf = Instance.new("ScrollingFrame")
	sf.Name                   = "ItemList"
	sf.Size                   = UDim2.new(1, -40, 1, -130)
	sf.Position               = UDim2.new(0, 20, 0, 118)
	sf.BackgroundTransparency = 1
	sf.BorderSizePixel        = 0
	sf.ScrollBarThickness     = 6
	sf.ScrollBarImageColor3   = Color3.fromRGB(100, 100, 120)
	sf.CanvasSize             = UDim2.new(0, 0, 0, 0)
	sf.ZIndex                 = 11
	sf.Parent                 = panel
	scrollFrame = sf

	local ll = Instance.new("UIListLayout")
	ll.FillDirection     = Enum.FillDirection.Vertical
	ll.VerticalAlignment = Enum.VerticalAlignment.Top
	ll.Padding           = UDim.new(0, 8)
	ll.SortOrder         = Enum.SortOrder.LayoutOrder
	ll.Parent            = sf
	listLayout = ll

	local sfPad = Instance.new("UIPadding")
	sfPad.PaddingTop    = UDim.new(0, 4)
	sfPad.PaddingBottom = UDim.new(0, 4)
	sfPad.PaddingLeft   = UDim.new(0, 4)
	sfPad.Parent        = sf

	ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		sf.CanvasSize = UDim2.new(0, 0, 0, ll.AbsoluteContentSize.Y + 8)
	end)
end

return ShopUI
