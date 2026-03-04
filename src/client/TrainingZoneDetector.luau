-- トレーニングゾーン在/不在を検知してUIボタンを出し入れする

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local Config     = require(ReplicatedStorage.Shared.Config)
local TrainingUI = require(script.Parent.TrainingUI)

local LocalPlayer = Players.LocalPlayer

local TrainingZoneDetector = {}

local INTERVAL = 0.2  -- チェック間隔（秒）

local function isInZone(pos: Vector3): boolean
	local b = Config.TrainingZoneBounds
	return pos.X >= b.MinX and pos.X <= b.MaxX
		and pos.Z >= b.MinZ and pos.Z <= b.MaxZ
		and pos.Y >= b.MinY and pos.Y <= b.MaxY
end

function TrainingZoneDetector.init()
	TrainingUI.setButtonsVisible(false)

	local elapsed = 0
	local inZone  = false

	RunService.Heartbeat:Connect(function(dt: number)
		elapsed += dt
		if elapsed < INTERVAL then return end
		elapsed = 0

		local char = LocalPlayer.Character
		if not char then return end
		local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then return end

		local nowInZone = isInZone(root.Position)
		if nowInZone ~= inZone then
			inZone = nowInZone
			TrainingUI.setButtonsVisible(inZone)
		end
	end)
end

return TrainingZoneDetector
