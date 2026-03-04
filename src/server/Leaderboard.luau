-- Roblox標準リーダーボード管理

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Leaderboard = {}

function Leaderboard.init()
	-- RemoteEvent作成（クライアントから値を受け取る）
	local re = Instance.new("RemoteEvent")
	re.Name   = "UpdateLeaderboard"
	re.Parent = ReplicatedStorage

	local function setupLeaderstats(player: Player)
		local leaderstats = Instance.new("Folder")
		leaderstats.Name   = "leaderstats"
		leaderstats.Parent = player

		local altValue = Instance.new("IntValue")
		altValue.Name   = "最高高度"
		altValue.Value  = 0
		altValue.Parent = leaderstats

		local rebValue = Instance.new("IntValue")
		rebValue.Name   = "リバース"
		rebValue.Value  = 0
		rebValue.Parent = leaderstats
	end

	for _, player in ipairs(Players:GetPlayers()) do
		setupLeaderstats(player)
	end
	Players.PlayerAdded:Connect(setupLeaderstats)

	re.OnServerEvent:Connect(function(player: Player, maxAltitude: number, rebirthCount: number)
		local leaderstats = player:FindFirstChild("leaderstats")
		if not leaderstats then return end

		local altValue = leaderstats:FindFirstChild("最高高度") :: IntValue?
		local rebValue = leaderstats:FindFirstChild("リバース")  :: IntValue?

		if altValue then
			altValue.Value = math.max(altValue.Value, math.floor(maxAltitude))
		end
		if rebValue then
			rebValue.Value = math.floor(rebirthCount)
		end
	end)
end

return Leaderboard
