-- ランダムイベントシステム（コインシャワー / パワーブースト / ラッキースター）

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local PlayerData   = require(ReplicatedStorage.Shared.PlayerData)
local MiniHUD      = require(script.Parent.MiniHUD)
local SoundManager = require(script.Parent.SoundManager)
local Effects      = require(script.Parent.Effects)

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local RandomEvents = {}

-- ─────────────────────────────────────────
-- 内部参照
-- ─────────────────────────────────────────

local eventsGui = nil :: ScreenGui?

local function getGui(): ScreenGui
	if eventsGui and eventsGui.Parent then return eventsGui end
	local sg = Instance.new("ScreenGui")
	sg.Name           = "RandomEventsGui"
	sg.ResetOnSpawn   = false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent         = PlayerGui
	eventsGui         = sg
	return sg
end

-- ─────────────────────────────────────────
-- 通知バナー（画面上部中央にポップダウン→表示→フェードアウト）
-- ─────────────────────────────────────────

local function showEventBanner(text: string)
	local sg = getGui()

	local banner = Instance.new("Frame")
	banner.AnchorPoint            = Vector2.new(0.5, 0)
	banner.Size                   = UDim2.new(0, 480, 0, 52)
	banner.Position               = UDim2.new(0.5, 0, 0, -60)
	banner.BackgroundColor3       = Color3.fromRGB(20, 20, 50)
	banner.BackgroundTransparency = 0.2
	banner.BorderSizePixel        = 0
	banner.ZIndex                 = 60
	banner.Parent                 = sg

	local bannerCorner = Instance.new("UICorner")
	bannerCorner.CornerRadius = UDim.new(0, 12)
	bannerCorner.Parent       = banner

	local bannerStroke = Instance.new("UIStroke")
	bannerStroke.Color     = Color3.fromRGB(255, 215, 0)
	bannerStroke.Thickness = 1.5
	bannerStroke.Parent    = banner

	local lbl = Instance.new("TextLabel")
	lbl.Size                   = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text                   = text
	lbl.TextColor3             = Color3.fromRGB(255, 255, 255)
	lbl.Font                   = Enum.Font.GothamBold
	lbl.TextSize               = 20
	lbl.TextTransparency       = 0
	lbl.ZIndex                 = 61
	lbl.Parent                 = banner

	-- スライドイン
	TweenService:Create(
		banner,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, 0, 0, 80) }
	):Play()

	-- 1.5秒表示後フェードアウト
	task.delay(1.5, function()
		TweenService:Create(banner, TweenInfo.new(0.4, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(lbl,   TweenInfo.new(0.4, Enum.EasingStyle.Quad), { TextTransparency = 1 }):Play()
		task.delay(0.4, function()
			if banner.Parent then banner:Destroy() end
		end)
	end)
end

-- ─────────────────────────────────────────
-- イベントA: コインシャワー
-- ─────────────────────────────────────────

local function eventCoinShower()
	showEventBanner("💰 コインシャワー！クリックで拾おう！")
	SoundManager.playCombo()

	local sg         = getGui()
	local vpSize     = workspace.CurrentCamera.ViewportSize
	local coinCount  = math.random(5, 8)
	local coins      = {}
	local active     = true

	task.delay(5, function()
		active = false
		for _, c in ipairs(coins) do
			if c.Parent then c:Destroy() end
		end
	end)

	for _ = 1, coinCount do
		local coinX = math.random(60, math.floor(vpSize.X) - 60)

		local coin = Instance.new("TextButton")
		coin.AnchorPoint            = Vector2.new(0.5, 0.5)
		coin.Size                   = UDim2.new(0, 44, 0, 44)
		coin.Position               = UDim2.new(0, coinX, 0, -40)
		coin.BackgroundTransparency = 1
		coin.Text                   = "💰"
		coin.TextSize               = 32
		coin.Font                   = Enum.Font.GothamBold
		coin.ZIndex                 = 55
		coin.Parent                 = sg
		table.insert(coins, coin)

		-- 画面上から下に落下
		local targetY = math.random(100, math.floor(vpSize.Y) - 100)
		TweenService:Create(
			coin,
			TweenInfo.new(math.random(8, 14) / 10, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.new(0, coinX, 0, targetY) }
		):Play()

		local collected = false
		coin.MouseButton1Click:Connect(function()
			if collected or not active then return end
			collected = true
			local reward = math.random(1, 3)
			PlayerData.addPower("Coins", reward)
			MiniHUD.update()
			Effects.showNotification("💰 +" .. reward .. " コイン！", 0.8)
			TweenService:Create(coin, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
			task.delay(0.2, function() if coin.Parent then coin:Destroy() end end)
		end)

		task.delay(math.random(0, 8) / 10, function() end)  -- stagger
	end
end

-- ─────────────────────────────────────────
-- イベントB: パワーブースト
-- ─────────────────────────────────────────

local BOOST_DURATION = 10

local function eventPowerBoost()
	showEventBanner("⚡ 10秒間クリック力2倍！")
	SoundManager.playCombo()

	PlayerData.setBoostMultiplier(2)

	-- カウントダウン通知
	task.spawn(function()
		for t = BOOST_DURATION, 1, -1 do
			if t <= 3 then
				Effects.showNotification("⚡ ブースト残り " .. t .. "秒！", 0.9)
			end
			task.wait(1)
		end
		PlayerData.setBoostMultiplier(1)
		Effects.showNotification("⚡ ブースト終了", 1.0)
	end)
end

-- ─────────────────────────────────────────
-- イベントC: ラッキースター
-- ─────────────────────────────────────────

local LUCKY_POWER = 500

local function eventLuckyStar()
	showEventBanner("⭐ ラッキースター！タップしてボーナス獲得！")
	SoundManager.playCombo()

	local sg     = getGui()
	local vpSize = workspace.CurrentCamera.ViewportSize

	local star = Instance.new("TextButton")
	star.AnchorPoint            = Vector2.new(0.5, 0.5)
	star.Size                   = UDim2.new(0, 80, 0, 80)
	star.Position               = UDim2.new(0.5, 0, 0.5, 0)
	star.BackgroundTransparency = 1
	star.Text                   = "⭐"
	star.TextSize               = 60
	star.Font                   = Enum.Font.GothamBold
	star.ZIndex                 = 55
	star.Parent                 = sg

	-- ゆっくり回転（UIRotation不可なので UIScale パルスで代替）
	local sc = Instance.new("UIScale")
	sc.Scale  = 1
	sc.Parent = star

	local spinning = true
	task.spawn(function()
		local angle = 0
		while spinning and star.Parent do
			angle = (angle + 2) % 360
			local pulse = 1 + 0.08 * math.sin(math.rad(angle * 3))
			sc.Scale = pulse
			task.wait(0.03)
		end
	end)

	-- 5秒後に消える
	local tapped = false
	task.delay(5, function()
		spinning = false
		if not tapped and star.Parent then
			TweenService:Create(star, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
			task.delay(0.3, function() if star.Parent then star:Destroy() end end)
		end
	end)

	star.MouseButton1Click:Connect(function()
		if tapped then return end
		tapped  = true
		spinning = false

		PlayerData.addPower("PowerGauge", LUCKY_POWER)
		MiniHUD.update()
		Effects.showNotification("⭐ パワーゲージ +" .. LUCKY_POWER .. "！", 1.5)
		Effects.evolutionFlash(3)

		TweenService:Create(sc, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.8 }):Play()
		task.delay(0.15, function()
			TweenService:Create(star, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
			task.delay(0.3, function() if star.Parent then star:Destroy() end end)
		end)
	end)
end

-- ─────────────────────────────────────────
-- イベントスケジューラ
-- ─────────────────────────────────────────

local EVENT_FUNCS = {
	eventCoinShower,
	eventPowerBoost,
	eventLuckyStar,
}

local function scheduleNext()
	local wait = math.random(15, 45)
	task.delay(wait, function()
		local fn = EVENT_FUNCS[math.random(1, #EVENT_FUNCS)]
		pcall(fn)
		scheduleNext()
	end)
end

-- ─────────────────────────────────────────
-- 公開API
-- ─────────────────────────────────────────

function RandomEvents.init()
	scheduleNext()
end

return RandomEvents
