-- ビジュアルエフェクト管理モジュール

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris       = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer

local Effects = {}

-- ─────────────────────────────────────────
-- 共有ScreenGui（遅延作成）
-- ─────────────────────────────────────────

local effectsGui = nil :: ScreenGui?
local flashFrame = nil :: Frame?

local function getEffectsGui(): ScreenGui
	if effectsGui and effectsGui.Parent then return effectsGui end

	local sg = Instance.new("ScreenGui")
	sg.Name           = "EffectsGui"
	sg.ResetOnSpawn   = false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent         = LocalPlayer.PlayerGui
	effectsGui = sg
	return sg
end

local function getFlashFrame(): Frame
	if flashFrame and flashFrame.Parent then return flashFrame end

	local f = Instance.new("Frame")
	f.Name                   = "FlashFrame"
	f.Size                   = UDim2.new(1, 0, 1, 0)
	f.BackgroundColor3       = Color3.fromRGB(255, 215, 0)
	f.BackgroundTransparency = 1
	f.BorderSizePixel        = 0
	f.ZIndex                 = 20
	f.Visible                = false
	f.Parent                 = getEffectsGui()
	flashFrame = f
	return f
end

-- ─────────────────────────────────────────
-- ダッシュトレイル管理
-- ─────────────────────────────────────────

type TrailData = { trail: Trail, a0: Attachment, a1: Attachment }
local trailCache = {} :: { [Model]: TrailData }

-- ─────────────────────────────────────────
-- 公開API
-- ─────────────────────────────────────────

-- (a) クリック時の光粒子バースト
function Effects.clickBurst(color: Color3)
	local char = LocalPlayer.Character
	if not char then return end
	local head = char:FindFirstChild("Head") :: BasePart?
	if not head then return end

	local part = Instance.new("Part")
	part.Size         = Vector3.new(0.1, 0.1, 0.1)
	part.Position     = head.Position + Vector3.new(0, 1.5, 0)
	part.Anchored     = true
	part.CanCollide   = false
	part.Transparency = 1
	part.CastShadow   = false
	part.Parent       = workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(color, Color3.fromRGB(255, 255, 255))
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Lifetime       = NumberRange.new(0.3, 0.6)
	emitter.Speed          = NumberRange.new(6, 12)
	emitter.SpreadAngle    = Vector2.new(60, 60)
	emitter.Rate           = 0
	emitter.LightEmission  = 0.8
	emitter.LightInfluence = 0.2
	emitter.Parent         = part

	emitter:Emit(10)
	Debris:AddItem(part, 1)
end

-- (b) ダッシュトレイル
function Effects.dashTrail(character: Model, enabled: boolean)
	if enabled then
		local cached = trailCache[character]
		if cached and cached.trail.Parent then return end

		local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then return end

		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(0,  1, 0)
		a0.Parent   = root

		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, -1, 0)
		a1.Parent   = root

		local trail = Instance.new("Trail")
		trail.Attachment0   = a0
		trail.Attachment1   = a1
		trail.Lifetime      = 0.4
		trail.MinLength     = 0
		trail.FaceCamera    = true
		trail.LightEmission = 0.5
		trail.Color         = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 255, 120)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 255, 120)),
		})
		trail.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(1, 1.0),
		})
		trail.Parent = root

		trailCache[character] = { trail = trail, a0 = a0, a1 = a1 }
	else
		local cached = trailCache[character]
		if not cached then return end
		pcall(function() cached.trail:Destroy() end)
		pcall(function() cached.a0:Destroy()    end)
		pcall(function() cached.a1:Destroy()    end)
		trailCache[character] = nil
	end
end

-- (c) 新記録の金色フラッシュ
function Effects.newRecordFlash()
	local f = getFlashFrame()
	f.BackgroundColor3       = Color3.fromRGB(255, 215, 0)
	f.BackgroundTransparency = 0.45
	f.Visible = true

	TweenService:Create(
		f,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 }
	):Play()

	task.delay(0.5, function()
		f.Visible = false
	end)
end

-- (d) 進化時の光爆発
function Effects.evolutionBurst(character: Model)
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end

	local part = Instance.new("Part")
	part.Size         = Vector3.new(0.1, 0.1, 0.1)
	part.CFrame       = root.CFrame
	part.Anchored     = true
	part.CanCollide   = false
	part.Transparency = 1
	part.CastShadow   = false
	part.Parent       = workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 220,  50)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 140,   0)),
		ColorSequenceKeypoint.new(1,   Color3.fromRGB(255, 255, 255)),
	})
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0,   0.5),
		NumberSequenceKeypoint.new(0.5, 0.3),
		NumberSequenceKeypoint.new(1,   0),
	})
	emitter.Lifetime       = NumberRange.new(0.5, 1.0)
	emitter.Speed          = NumberRange.new(10, 25)
	emitter.SpreadAngle    = Vector2.new(180, 180)
	emitter.Rate           = 0
	emitter.LightEmission  = 1
	emitter.LightInfluence = 0
	emitter.Parent         = part

	emitter:Emit(40)

	local light = Instance.new("PointLight")
	light.Brightness = 5
	light.Range      = 20
	light.Color      = Color3.fromRGB(255, 220, 50)
	light.Parent     = part

	TweenService:Create(
		light,
		TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Brightness = 0 }
	):Play()

	Debris:AddItem(part, 1.5)
end

-- (e) 高所着地の土煙
function Effects.landingDust(position: Vector3)
	local part = Instance.new("Part")
	part.Size         = Vector3.new(0.1, 0.1, 0.1)
	part.Position     = position
	part.Anchored     = true
	part.CanCollide   = false
	part.Transparency = 1
	part.CastShadow   = false
	part.Parent       = workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 150, 100)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 180, 140)),
	})
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime    = NumberRange.new(0.4, 0.8)
	emitter.Speed       = NumberRange.new(3, 8)
	emitter.SpreadAngle = Vector2.new(70, 70)
	emitter.Rate        = 0
	emitter.RotSpeed    = NumberRange.new(-180, 180)
	emitter.Rotation    = NumberRange.new(0, 360)
	emitter.Parent      = part

	emitter:Emit(16)
	Debris:AddItem(part, 1)
end

-- ─────────────────────────────────────────
-- 通知UI（共通）
-- ─────────────────────────────────────────

local notifBg      = nil :: Frame?
local notifLabel   = nil :: TextLabel?
local notifVersion = 0

local function getNotifUI(): (Frame, TextLabel)
	if notifBg and notifBg.Parent then
		return notifBg, notifLabel :: TextLabel
	end

	local sg = Instance.new("ScreenGui")
	sg.Name           = "NotificationGui"
	sg.ResetOnSpawn   = false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent         = LocalPlayer.PlayerGui

	local bg = Instance.new("Frame")
	bg.AnchorPoint            = Vector2.new(0.5, 0)
	bg.Size                   = UDim2.new(0, 500, 0, 46)
	bg.Position               = UDim2.new(0.5, 0, 0, 80)
	bg.BackgroundColor3       = Color3.fromRGB(20, 20, 40)
	bg.BackgroundTransparency = 0.3
	bg.BorderSizePixel        = 0
	bg.Visible                = false
	bg.ZIndex                 = 50
	bg.Parent                 = sg
	notifBg = bg

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 12)
	bgCorner.Parent       = bg

	local lbl = Instance.new("TextLabel")
	lbl.Size                   = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text                   = ""
	lbl.TextColor3             = Color3.fromRGB(255, 255, 255)
	lbl.Font                   = Enum.Font.GothamBold
	lbl.TextSize               = 18
	lbl.ZIndex                 = 51
	lbl.Parent                 = bg
	notifLabel = lbl

	return bg, lbl
end

function Effects.showNotification(text: string, duration: number)
	local bg, lbl = getNotifUI()

	notifVersion += 1
	local myVersion = notifVersion

	lbl.Text                  = text
	lbl.TextTransparency      = 0
	bg.BackgroundTransparency = 0.3
	bg.Visible                = true

	task.delay(duration, function()
		if notifVersion ~= myVersion then return end
		TweenService:Create(bg,  TweenInfo.new(0.4, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(lbl, TweenInfo.new(0.4, Enum.EasingStyle.Quad), { TextTransparency = 1 }):Play()
		task.delay(0.4, function()
			if notifVersion ~= myVersion then return end
			bg.Visible = false
		end)
	end)
end

-- ─────────────────────────────────────────
-- (f) コンボテキスト演出
-- ─────────────────────────────────────────

function Effects.comboText(comboCount: number)
	local sg = getEffectsGui()

	local lbl = Instance.new("TextLabel")
	lbl.AnchorPoint            = Vector2.new(0.5, 0.5)
	lbl.Size                   = UDim2.new(0, 220, 0, 54)
	lbl.Position               = UDim2.new(0.5, 0, 0.3, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text                   = "🔥 COMBO x" .. comboCount .. "!"
	lbl.TextColor3             = Color3.fromRGB(255, 110, 50)
	lbl.Font                   = Enum.Font.GothamBold
	lbl.TextSize               = 30
	lbl.TextTransparency       = 0
	lbl.ZIndex                 = 30
	lbl.Parent                 = sg

	local sc = Instance.new("UIScale")
	sc.Scale  = 0.5
	sc.Parent = lbl

	TweenService:Create(sc, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.15 }):Play()
	task.delay(0.12, function()
		TweenService:Create(sc, TweenInfo.new(0.08, Enum.EasingStyle.Quad), { Scale = 1.0 }):Play()
	end)

	task.delay(0.35, function()
		TweenService:Create(
			lbl,
			TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Position = UDim2.new(0.5, 0, 0.22, 0), TextTransparency = 1 }
		):Play()
		task.delay(0.45, function() lbl:Destroy() end)
	end)
end

-- ─────────────────────────────────────────
-- (g) リバース紙吹雪
-- ─────────────────────────────────────────

function Effects.rebirthConfetti()
	local char = LocalPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end

	local COLORS = {
		Color3.fromRGB(255,  80,  80),
		Color3.fromRGB(255, 200,  50),
		Color3.fromRGB( 50, 255, 100),
		Color3.fromRGB( 80, 150, 255),
		Color3.fromRGB(200,  50, 255),
	}

	for i = 1, 3 do
		local offset = Vector3.new(math.random(-3, 3), math.random(0, 3), math.random(-3, 3))

		local part = Instance.new("Part")
		part.Size         = Vector3.new(0.1, 0.1, 0.1)
		part.CFrame       = root.CFrame + offset
		part.Anchored     = true
		part.CanCollide   = false
		part.Transparency = 1
		part.CastShadow   = false
		part.Parent       = workspace

		local emitter = Instance.new("ParticleEmitter")
		emitter.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0,    COLORS[1]),
			ColorSequenceKeypoint.new(0.25, COLORS[2]),
			ColorSequenceKeypoint.new(0.5,  COLORS[3]),
			ColorSequenceKeypoint.new(0.75, COLORS[4]),
			ColorSequenceKeypoint.new(1,    COLORS[5]),
		})
		emitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.35),
			NumberSequenceKeypoint.new(1, 0),
		})
		emitter.Lifetime       = NumberRange.new(0.8, 1.6)
		emitter.Speed          = NumberRange.new(8, 22)
		emitter.SpreadAngle    = Vector2.new(180, 180)
		emitter.Rate           = 0
		emitter.LightEmission  = 0.8
		emitter.Rotation       = NumberRange.new(0, 360)
		emitter.RotSpeed       = NumberRange.new(-360, 360)
		emitter.Parent         = part

		emitter:Emit(28)
		Debris:AddItem(part, 2)
	end
end

-- ─────────────────────────────────────────
-- (h) フレームシェイク
-- ─────────────────────────────────────────

function Effects.shakeFrame(frame: Frame, duration: number)
	local originalPos = frame.Position
	local endTime     = tick() + duration
	local intensity   = 5

	local function step()
		if tick() >= endTime then
			frame.Position = originalPos
			return
		end
		local ox = math.random(-intensity, intensity)
		local oy = math.random(-intensity, intensity)
		frame.Position = UDim2.new(
			originalPos.X.Scale,  originalPos.X.Offset + ox,
			originalPos.Y.Scale, originalPos.Y.Offset + oy
		)
		task.delay(0.04, step)
	end
	step()
end

-- ─────────────────────────────────────────
-- (i) 進化フラッシュ（ステージ別カラー）
-- ─────────────────────────────────────────

local STAGE_FLASH_COLORS = {
	Color3.fromRGB( 80, 150, 255),  -- Stage 1: 青
	Color3.fromRGB( 80, 220, 100),  -- Stage 2: 緑
	Color3.fromRGB(255, 220,  50),  -- Stage 3: 黄
	Color3.fromRGB(255, 140,  30),  -- Stage 4: オレンジ
	Color3.fromRGB(255,  80, 200),  -- Stage 5: ピンク
}

function Effects.evolutionFlash(stage: number)
	local f = getFlashFrame()
	f.BackgroundColor3       = STAGE_FLASH_COLORS[stage] or Color3.fromRGB(255, 220, 50)
	f.BackgroundTransparency = 0.35
	f.Visible                = true

	TweenService:Create(
		f,
		TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 }
	):Play()

	task.delay(0.6, function()
		f.Visible = false
	end)
end

-- ─────────────────────────────────────────
-- (j) シューズ装備時の足元パーティクル
-- ─────────────────────────────────────────

function Effects.shoeEquipParticle(color: Color3)
	local char = LocalPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end

	local part = Instance.new("Part")
	part.Size         = Vector3.new(0.1, 0.1, 0.1)
	part.CFrame       = root.CFrame + Vector3.new(0, -2.5, 0)
	part.Anchored     = true
	part.CanCollide   = false
	part.Transparency = 1
	part.CastShadow   = false
	part.Parent       = workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, color),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
	})
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Lifetime       = NumberRange.new(0.3, 0.5)
	emitter.Speed          = NumberRange.new(3, 8)
	emitter.SpreadAngle    = Vector2.new(70, 70)
	emitter.Rate           = 0
	emitter.LightEmission  = 0.8
	emitter.LightInfluence = 0.2
	emitter.Parent         = part

	emitter:Emit(24)
	Debris:AddItem(part, 1)
end

return Effects
