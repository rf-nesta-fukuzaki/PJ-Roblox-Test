-- 一方通行プラットフォーム: 下から上への通過を許可し、上から乗ると通常の床になる

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local PlatformPhaser = {}

local RANGE    = 100   -- 処理対象の水平距離（スタッド）
local INTERVAL = 0.1   -- チェック間隔（秒）

function PlatformPhaser.init()
	local platforms = workspace:WaitForChild("Platforms", 10) :: Folder?
	if not platforms then
		warn("[PlatformPhaser] Workspace.Platforms が見つかりません。スキップします。")
		return
	end

	local elapsed = 0

	RunService.Heartbeat:Connect(function(dt: number)
		elapsed += dt
		if elapsed < INTERVAL then return end
		elapsed = 0

		local char = LocalPlayer.Character
		if not char then return end
		local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then return end

		local playerPos = root.Position

		for _, obj in ipairs(platforms:GetDescendants()) do
			if not obj:IsA("BasePart") then continue end

			-- 水平距離が範囲外はスキップ
			local dx = obj.Position.X - playerPos.X
			local dz = obj.Position.Z - playerPos.Z
			if (dx * dx + dz * dz) > RANGE * RANGE then continue end

			-- プレイヤーがプラットフォームの上面より上にいるなら衝突ON
			local topY = obj.Position.Y + obj.Size.Y / 2
			if playerPos.Y > topY - 1 then
				obj.CanCollide = true
			else
				obj.CanCollide = false
			end
		end
	end)
end

return PlatformPhaser
