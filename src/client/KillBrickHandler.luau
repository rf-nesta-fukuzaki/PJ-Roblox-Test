-- KillBrick（Y=-50付近の安全ネット）に触れたらリスポーンさせる

local Players  = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local KillBrickHandler = {}

function KillBrickHandler.init()
	local killBrick = Workspace:WaitForChild("KillBrick") :: BasePart

	killBrick.Touched:Connect(function(hit: BasePart)
		local char = LocalPlayer.Character
		if not char then return end
		-- hit がLocalPlayerのキャラクターに属するパーツかチェック
		if not char:IsAncestorOf(hit) then return end
		local humanoid = char:FindFirstChildOfClass("Humanoid") :: Humanoid?
		if humanoid then
			humanoid.Health = 0
		end
	end)
end

return KillBrickHandler
