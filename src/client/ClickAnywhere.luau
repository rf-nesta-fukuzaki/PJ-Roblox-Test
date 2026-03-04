-- 画面どこでもクリック/タップでトレーニング

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")

local PlayerData         = require(ReplicatedStorage.Shared.PlayerData)
local Config             = require(ReplicatedStorage.Shared.Config)
local MiniHUD            = require(script.Parent.MiniHUD)
local MovementController = require(script.Parent.MovementController)
local TrainingUI         = require(script.Parent.TrainingUI)
local Effects            = require(script.Parent.Effects)
local SoundManager       = require(script.Parent.SoundManager)

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local ClickAnywhere = {}

-- ─────────────────────────────────────────
-- 内部参照
-- ─────────────────────────────────────────

local clickGui             = nil :: ScreenGui?
local prevEvolutionStage   = 0

-- ─────────────────────────────────────────
-- コンボ追跡
-- ─────────────────────────────────────────

local clickTimes      = {}
local COMBO_WINDOW    = 1.0
local COMBO_THRESHOLD = 5

local function recordCombo(): number
	local now    = tick()
	local cutoff = now - COMBO_WINDOW
	table.insert(clickTimes, now)
	while clickTimes[1] and clickTimes[1] < cutoff do
		table.remove(clickTimes, 1)
	end
	return #clickTimes
end

-- ─────────────────────────────────────────
-- 絵文字アイコン
-- ─────────────────────────────────────────

local EMOJIS = { "⭐", "💎", "🔥", "⚡", "🌸" }

-- ─────────────────────────────────────────
-- パンチアニメーション
-- ─────────────────────────────────────────

local PUNCH_ANIM_ID = "rbxassetid://507770239"

local function playPunchAnimation()
	local char = LocalPlayer.Character
	if not char then return end
	local humanoid = char:FindFirstChildOfClass("Humanoid") :: Humanoid?
	if not humanoid then return end
	local animator = humanoid:FindFirstChildOfClass("Animator") :: Animator?
	if not animator then return end

	local anim = Instance.new("Animation")
	anim.AnimationId = PUNCH_ANIM_ID
	local track = animator:LoadAnimation(anim)
	-- Speed=2.0, Weight=0.5 で再生
	track:Play(0.05, 0.5, 2.0)
	task.delay(0.3, function()
		track:Stop(0.05)
		anim:Destroy()
	end)
end

local function getGui(): ScreenGui
	if clickGui and clickGui.Parent then return clickGui end
	local sg = Instance.new("ScreenGui")
	sg.Name           = "ClickAnywhereGui"
	sg.ResetOnSpawn   = false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent         = PlayerGui
	clickGui          = sg
	return sg
end

-- クリック位置に絵文字＋ダメージ数値を浮かせる
local function spawnClickFx(screenX: number, screenY: number, emoji: string, power: number)
	local sg = getGui()

	-- 絵文字ラベル
	local emojiLbl = Instance.new("TextLabel")
	emojiLbl.AnchorPoint            = Vector2.new(0.5, 0.5)
	emojiLbl.Size                   = UDim2.new(0, 30, 0, 30)
	emojiLbl.Position               = UDim2.new(0, screenX, 0, screenY)
	emojiLbl.BackgroundTransparency = 1
	emojiLbl.Text                   = emoji
	emojiLbl.TextSize               = 22
	emojiLbl.Font                   = Enum.Font.GothamBold
	emojiLbl.TextTransparency       = 0
	emojiLbl.ZIndex                 = 30
	emojiLbl.Parent                 = sg

	TweenService:Create(
		emojiLbl,
		TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0, screenX, 0, screenY - 40), TextTransparency = 1 }
	):Play()
	task.delay(0.4, function() emojiLbl:Destroy() end)

	-- ダメージ数値ラベル
	local numLbl = Instance.new("TextLabel")
	numLbl.AnchorPoint            = Vector2.new(0.5, 0.5)
	numLbl.Size                   = UDim2.new(0, 80, 0, 26)
	numLbl.Position               = UDim2.new(0, screenX + 28, 0, screenY - 8)
	numLbl.BackgroundTransparency = 1
	numLbl.Text                   = "+" .. math.floor(power)
	numLbl.TextColor3             = Color3.fromRGB(100, 220, 255)
	numLbl.Font                   = Enum.Font.GothamBold
	numLbl.TextSize               = 20
	numLbl.TextTransparency       = 0
	numLbl.ZIndex                 = 30
	numLbl.Parent                 = sg

	TweenService:Create(
		numLbl,
		TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0, screenX + 28, 0, screenY - 50), TextTransparency = 1 }
	):Play()
	task.delay(0.4, function() numLbl:Destroy() end)
end

-- 画面端クリック時のシューズアイコン表示
local function spawnEdgeFx(screenX: number, screenY: number, power: number)
	local sg   = getGui()
	local d    = PlayerData.getData()
	local shoes = Config.Shoes[d.EquippedShoes]
	-- シューズ名の先頭絵文字を取得（例: "🏃 ランナーシューズ" → "🏃"）
	local icon = "👟"
	if shoes and shoes.name then
		local first = shoes.name:match("^([%z\1-\127\194-\244][\128-\191]*)")
		if first then icon = first end
	end

	local lbl = Instance.new("TextLabel")
	lbl.AnchorPoint            = Vector2.new(0.5, 1)
	lbl.Size                   = UDim2.new(0, 160, 0, 38)
	lbl.Position               = UDim2.new(0, screenX, 0, screenY - 12)
	lbl.BackgroundTransparency = 1
	lbl.Text                   = icon .. " +" .. math.floor(power)
	lbl.TextColor3             = Color3.fromRGB(255, 215, 50)
	lbl.Font                   = Enum.Font.GothamBold
	lbl.TextSize               = 28
	lbl.TextTransparency       = 0
	lbl.ZIndex                 = 30
	lbl.Parent                 = sg

	task.delay(0.6, function()
		TweenService:Create(lbl, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { TextTransparency = 1 }):Play()
		task.delay(0.3, function() lbl:Destroy() end)
	end)
end

-- ─────────────────────────────────────────
-- 公開API
-- ─────────────────────────────────────────

function ClickAnywhere.init()
	prevEvolutionStage = PlayerData.getEvolutionStage()

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		-- GUIボタンがクリックを処理した場合はスキップ
		if gameProcessed then return end

		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		-- コンボ記録（アニメーション判定にも使用）
		local comboCount = recordCombo()

		local clickPower = PlayerData.getEffectiveClickPower()
		PlayerData.addPower("JumpPower", clickPower)
		PlayerData.addPower("PowerGauge", clickPower * 0.5)

		SoundManager.playClick()

		local screenX = input.Position.X
		local screenY = input.Position.Y

		-- 絵文字＋数値スポーンアニメ
		local emoji = EMOJIS[math.random(1, #EMOJIS)]
		spawnClickFx(screenX, screenY, emoji, clickPower)

		-- 画面端（左右15%以内）でシューズアイコン表示
		local vpSize  = workspace.CurrentCamera.ViewportSize
		if screenX < vpSize.X * 0.15 or screenX > vpSize.X * 0.85 then
			spawnEdgeFx(screenX, screenY, clickPower)
		end

		-- パーティクルバースト
		Effects.clickBurst(Color3.fromRGB(52, 152, 219))

		-- パンチアニメーション（5クリック/秒以上はパフォーマンスのためスキップ）
		if comboCount < 5 then
			task.spawn(playPunchAnimation)
		end

		-- コンボチェック
		if comboCount >= COMBO_THRESHOLD then
			if comboCount >= 20 then
				Effects.showNotification("💥 ULTRA COMBO!!", 1.0)
			elseif comboCount >= 10 then
				Effects.showNotification("🔥 SUPER COMBO!", 1.0)
			else
				Effects.comboText(comboCount)
			end
			SoundManager.playCombo()
		end

		-- 進化チェック
		local newStage = PlayerData.getEvolutionStage()
		if newStage > prevEvolutionStage then
			prevEvolutionStage = newStage
			TrainingUI.showEvolutionNotice(newStage)
			Effects.evolutionFlash(newStage)
			local char = LocalPlayer.Character
			if char then
				Effects.evolutionBurst(char)
			end
			SoundManager.playEvolution()
		end

		TrainingUI.updateDisplay()
		MiniHUD.update()
		MovementController.update()
	end)
end

return ClickAnywhere
