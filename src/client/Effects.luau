-- ビジュアルエフェクト管理モジュール

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local Debris            = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local Effects = {}

-- ─────────────────────────────────────────
-- 新記録フラッシュ用UI（遅延作成）
-- ─────────────────────────────────────────

local flashFrame = nil :: Frame?

local function getFlashFrame(): Frame
	if flashFrame and flashFrame.Parent then return flashFrame end

	local playerGui = LocalPlayer.PlayerGui

	local sg = Instance.new("ScreenGui")
	sg.Name           = "EffectsGui"
	sg.ResetOnSpawn   = false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent         = playerGui

	local f = Instance.new("Frame")
	f.Name                   = "FlashFrame"
	f.Size                   = UDim2.new(1, 0, 1, 0)
	f.BackgroundColor3       = Color3.fromRGB(255, 215, 0)
	f.BackgroundTransparency = 1
	f.BorderSizePixel        = 0
	f.ZIndex                 = 20
	f.Visible                = false
	f.Parent                 = sg

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

-- (a) クリック時の光粒子バースト（色はボタン定義から）
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
	emitter.Color          = ColorSequence.new(color, Color3.fromRGB(255, 255, 255))
	emitter.Size           = NumberSequence.new({
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

-- (b) ダッシュトレイル（Speed stat > 100 のときに有効化）
function Effects.dashTrail(character: Model, enabled: boolean)
	if enabled then
		-- すでにアタッチ済みなら何もしない
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
			ColorSequenceKeypoint.new(0, Color3.fromRGB( 80, 255, 120)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB( 80, 255, 120)),
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
		-- Destroy は既に破棄済みの場合もエラーにならない
		pcall(function() cached.trail:Destroy() end)
		pcall(function() cached.a0:Destroy()    end)
		pcall(function() cached.a1:Destroy()    end)
		trailCache[character] = nil
	end
end

-- (c) 新記録の金色フラッシュ（0.3秒でフェードアウト）
function Effects.newRecordFlash()
	local f = getFlashFrame()
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

-- (d) 進化時の光爆発（パーティクル多め + PointLight）
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
	emitter.Color          = ColorSequence.new({
		ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 220,  50)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 140,   0)),
		ColorSequenceKeypoint.new(1,   Color3.fromRGB(255, 255, 255)),
	})
	emitter.Size           = NumberSequence.new({
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

-- (e) 高所着地の土煙（落下距離 >= 50 スタッドで呼ぶ）
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
	emitter.Color        = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 150, 100)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 180, 140)),
	})
	emitter.Size         = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime     = NumberRange.new(0.4, 0.8)
	emitter.Speed        = NumberRange.new(3, 8)
	emitter.SpreadAngle  = Vector2.new(70, 70)
	emitter.Rate         = 0
	emitter.RotSpeed     = NumberRange.new(-180, 180)
	emitter.Rotation     = NumberRange.new(0, 360)
	emitter.Parent       = part

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

	local playerGui = LocalPlayer.PlayerGui

	local sg = Instance.new("ScreenGui")
	sg.Name         = "NotificationGui"
	sg.ResetOnSpawn = false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent       = playerGui

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

	lbl.Text              = text
	lbl.TextTransparency  = 0
	bg.BackgroundTransparency = 0.3
	bg.Visible = true

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
-- (f) 足場生成パーティクル
-- ─────────────────────────────────────────

function Effects.fallPlatformSpawn(position: Vector3)
	local part = Instance.new("Part")
	part.Size         = Vector3.new(0.1, 0.1, 0.1)
	part.Position     = position + Vector3.new(0, 1, 0)
	part.Anchored     = true
	part.CanCollide   = false
	part.Transparency = 1
	part.CastShadow   = false
	part.Parent       = workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0,   Color3.fromRGB(100, 200, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 255, 200)),
		ColorSequenceKeypoint.new(1,   Color3.fromRGB(255, 255, 255)),
	})
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.45),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Lifetime       = NumberRange.new(0.5, 1.2)
	emitter.Speed          = NumberRange.new(6, 18)
	emitter.SpreadAngle    = Vector2.new(80, 80)
	emitter.Rate           = 0
	emitter.LightEmission  = 0.9
	emitter.LightInfluence = 0.1
	emitter.Parent         = part

	emitter:Emit(24)
	Debris:AddItem(part, 1.5)
end

-- ─────────────────────────────────────────
-- (g) FallPlatformCreated RemoteEvent 受信
-- ─────────────────────────────────────────

function Effects.initFallPlatformListener()
	local re = ReplicatedStorage:WaitForChild("FallPlatformCreated") :: RemoteEvent

	re.OnClientEvent:Connect(function(player: Player, position: Vector3)
		Effects.fallPlatformSpawn(position)

		if player == LocalPlayer then
			Effects.showNotification("💫 あなたの足場が出現！ みんなの踏み台に！", 1.5)
		else
			-- 近く（200スタッド以内）のみ通知
			local char = LocalPlayer.Character
			local notify = true
			if char then
				local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
				if root and (root.Position - position).Magnitude > 200 then
					notify = false
				end
			end
			if notify then
				Effects.showNotification("✨ " .. player.Name .. "の足場が出現！", 1.0)
			end
		end
	end)
end

return Effects
