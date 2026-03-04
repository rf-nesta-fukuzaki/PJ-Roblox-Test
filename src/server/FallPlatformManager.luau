-- 落下検出と一時足場生成を管理するサーバーモジュール

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)

local FallPlatformManager = {}

-- ─────────────────────────────────────────
-- 定数
-- ─────────────────────────────────────────
local CHECK_INTERVAL   = 0.5   -- 落下判定の間隔（秒）
local MAX_PLATFORMS    = 50    -- サーバー全体の同時上限
local TELEPORT_XZ_LIMIT = 50  -- これ以上のX-Z移動はテレポートとして無視

-- ─────────────────────────────────────────
-- 状態
-- ─────────────────────────────────────────

-- platforms: { platform: Part, createdAt: number }[]（古い順）
local platforms = {}

-- prevPositions[player] = { pos: Vector3, peakY: number, peakX: number, peakZ: number }
local prevPositions = {}

local fallPlatformEvent = nil :: RemoteEvent?

-- ─────────────────────────────────────────
-- ヘルパー
-- ─────────────────────────────────────────

local function randomPastelColor(): Color3
	return Color3.fromHSV(math.random(), 0.45, 0.95)
end

local function removeOldestPlatform()
	local entry = table.remove(platforms, 1)
	if entry and entry.platform and entry.platform.Parent then
		entry.platform:Destroy()
	end
end

local function removePlatformEntry(part: Part)
	for i, entry in ipairs(platforms) do
		if entry.platform == part then
			table.remove(platforms, i)
			return
		end
	end
end

local function spawnPlatform(player: Player, spawnPos: Vector3)
	-- 地面付近は生成しない
	if spawnPos.Y < 5 then return end

	-- 上限チェック
	if #platforms >= MAX_PLATFORMS then
		removeOldestPlatform()
	end

	local color = randomPastelColor()

	local part = Instance.new("Part")
	part.Name         = "FallPlatform"
	part.Size         = Config.FallPlatform.PlatformSize
	part.CFrame       = CFrame.new(spawnPos)
	part.Anchored     = true
	part.CanCollide   = true
	part.Material     = Enum.Material.Neon
	part.Color        = color
	part.Transparency = 0.3
	part.CastShadow   = false
	part.Parent       = workspace

	-- プレイヤー名表示
	local bb = Instance.new("BillboardGui")
	bb.Size        = UDim2.new(0, 130, 0, 28)
	bb.StudsOffset = Vector3.new(0, 1.5, 0)
	bb.AlwaysOnTop = false
	bb.Parent      = part

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size                   = UDim2.new(1, 0, 1, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text                   = player.Name .. "の足場"
	nameLbl.TextColor3             = Color3.fromRGB(255, 255, 255)
	nameLbl.Font                   = Enum.Font.GothamBold
	nameLbl.TextSize               = 14
	nameLbl.TextStrokeTransparency = 0.5
	nameLbl.Parent                 = bb

	table.insert(platforms, { platform = part, createdAt = tick() })

	-- Duration秒後にフェードアウト → Destroy
	task.delay(Config.FallPlatform.Duration, function()
		if not part or not part.Parent then return end
		TweenService:Create(
			part,
			TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Transparency = 1 }
		):Play()
		task.delay(1.5, function()
			if part and part.Parent then
				part:Destroy()
			end
			removePlatformEntry(part)
		end)
	end)

	-- 全クライアントに通知
	if fallPlatformEvent then
		fallPlatformEvent:FireAllClients(player, spawnPos)
	end
end

local function resetPlayerData(player: Player)
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end
	local pos = hrp.Position
	prevPositions[player] = { pos = pos, peakY = pos.Y, peakX = pos.X, peakZ = pos.Z }
end

-- ─────────────────────────────────────────
-- 公開API
-- ─────────────────────────────────────────

function FallPlatformManager.init()
	-- RemoteEvent作成
	local re = Instance.new("RemoteEvent")
	re.Name   = "FallPlatformCreated"
	re.Parent = ReplicatedStorage
	fallPlatformEvent = re

	-- プレイヤー管理
	for _, player in ipairs(Players:GetPlayers()) do
		resetPlayerData(player)
		player.CharacterAdded:Connect(function()
			task.wait()  -- キャラクター生成を待つ
			resetPlayerData(player)
		end)
	end

	Players.PlayerAdded:Connect(function(player)
		prevPositions[player] = nil
		player.CharacterAdded:Connect(function()
			task.wait()
			resetPlayerData(player)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		prevPositions[player] = nil
	end)

	-- 毎フレーム: peakY追跡 + 0.5秒ごとに落下判定
	local elapsed = 0

	RunService.Heartbeat:Connect(function(dt: number)
		-- 毎フレーム: peakY・peakX・peakZ を更新
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			if not char then continue end
			local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not hrp then continue end

			local prev = prevPositions[player]
			if not prev then continue end

			local y = hrp.Position.Y
			if y > prev.peakY then
				prev.peakY = y
				prev.peakX = hrp.Position.X
				prev.peakZ = hrp.Position.Z
			end
		end

		-- 0.5秒ごと: 落下判定
		elapsed += dt
		if elapsed < CHECK_INTERVAL then return end
		elapsed = 0

		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			if not char then continue end
			local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not hrp then continue end

			local currentPos = hrp.Position
			local prev = prevPositions[player]

			if not prev then
				prevPositions[player] = {
					pos = currentPos,
					peakY = currentPos.Y,
					peakX = currentPos.X,
					peakZ = currentPos.Z,
				}
				continue
			end

			-- テレポート除外（X-Z成分が大きすぎる）
			local dx = currentPos.X - prev.pos.X
			local dz = currentPos.Z - prev.pos.Z
			if math.sqrt(dx * dx + dz * dz) > TELEPORT_XZ_LIMIT then
				prevPositions[player] = {
					pos = currentPos,
					peakY = currentPos.Y,
					peakX = currentPos.X,
					peakZ = currentPos.Z,
				}
				continue
			end

			-- 落下判定: peakYからの降下量がMinFallHeight以上
			local fallDist = prev.peakY - currentPos.Y

			if fallDist >= Config.FallPlatform.MinFallHeight then
				-- X-Zは落下検出時のプレイヤー位置、Yはpeak - offset
				local spawnPos = Vector3.new(
					currentPos.X,
					prev.peakY - Config.FallPlatform.SpawnOffsetY,
					currentPos.Z
				)
				spawnPlatform(player, spawnPos)

				-- peakをリセット（連続生成防止）
				prevPositions[player] = {
					pos = currentPos,
					peakY = currentPos.Y,
					peakX = currentPos.X,
					peakZ = currentPos.Z,
				}
			else
				prev.pos = currentPos
			end
		end
	end)
end

return FallPlatformManager
