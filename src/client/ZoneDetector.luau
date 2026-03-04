-- 複数ゾーンを管理し、対応UIを表示/非表示にする

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local Config    = require(ReplicatedStorage.Shared.Config)
local RebirthUI = require(script.Parent.RebirthUI)
local ShopUI    = require(script.Parent.ShopUI)

local LocalPlayer = Players.LocalPlayer

local ZoneDetector = {}

local INTERVAL = 0.2

-- ─────────────────────────────────────────
-- ゾーン定義（TrainingZoneはボタン常時表示化により削除）
-- ─────────────────────────────────────────

local ZONES = {
	{
		bounds  = Config.RebirthZoneBounds,
		onEnter = function() RebirthUI.show() end,
		onLeave = function() RebirthUI.hide() end,
	},
	{
		bounds  = Config.ShopZoneBounds,
		onEnter = function() ShopUI.show() end,
		onLeave = function() ShopUI.hide() end,
	},
}

-- ─────────────────────────────────────────
-- ヘルパー
-- ─────────────────────────────────────────

local function isInBounds(pos: Vector3, b): boolean
	return pos.X >= b.MinX and pos.X <= b.MaxX
		and pos.Z >= b.MinZ and pos.Z <= b.MaxZ
		and pos.Y >= b.MinY and pos.Y <= b.MaxY
end

-- ─────────────────────────────────────────
-- 公開API
-- ─────────────────────────────────────────

function ZoneDetector.init()
	local inZone = {}
	for i = 1, #ZONES do
		inZone[i] = false
	end

	RebirthUI.hide()
	ShopUI.hide()

	local elapsed = 0

	RunService.Heartbeat:Connect(function(dt: number)
		elapsed += dt
		if elapsed < INTERVAL then return end
		elapsed = 0

		local char = LocalPlayer.Character
		if not char then return end
		local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then return end

		local pos = root.Position
		for i, zone in ipairs(ZONES) do
			local nowIn = isInBounds(pos, zone.bounds)
			if nowIn ~= inZone[i] then
				inZone[i] = nowIn
				if nowIn then
					zone.onEnter()
				else
					zone.onLeave()
				end
			end
		end
	end)
end

return ZoneDetector
