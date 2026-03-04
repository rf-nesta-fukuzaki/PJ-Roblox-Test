local Workspace = game:GetService("Workspace")

local function createPart(name, size, pos, color, parent, material, transparency)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = pos
	part.Color = color
	part.Anchored = true
	if material then part.Material = material end
	if transparency then part.Transparency = transparency end
	part.Parent = parent
	return part
end

local function createWedge(name, size, pos, color, parent)
	local wedge = Instance.new("WedgePart")
	wedge.Name = name
	wedge.Size = size
	wedge.Position = pos
	wedge.Color = color
	wedge.Anchored = true
	wedge.Parent = parent
	return wedge
end

local function createSign(text, size, pos, parent)
	local sign = Instance.new("Part")
	sign.Name = "Sign"
	sign.Size = size
	sign.Position = pos
	sign.Anchored = true
	sign.CanCollide = false
	sign.Parent = parent

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.Parent = sign

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = text
	textLabel.TextScaled = true
	textLabel.TextColor3 = Color3.new(0, 0, 0)
	textLabel.Parent = surfaceGui

	return sign
end

local function buildMap()
	-- 1. スポーンエリア整備
	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate.Color = Color3.fromRGB(170, 210, 240)
	end

	local spawnLocation = Workspace:FindFirstChild("SpawnLocation")
	if not spawnLocation then
		spawnLocation = Instance.new("SpawnLocation")
		spawnLocation.Name = "SpawnLocation"
		spawnLocation.Size = Vector3.new(12, 1, 12)
		spawnLocation.Position = Vector3.new(0, 1, 0)
		spawnLocation.Anchored = true
		spawnLocation.Parent = Workspace
	end

	-- 2. トレーニングゾーン
	local trainingZone = Workspace:FindFirstChild("TrainingZone")
	if not trainingZone then
		trainingZone = Instance.new("Model")
		trainingZone.Name = "TrainingZone"
		trainingZone.Parent = Workspace

		-- 床プラットフォーム（大）
		createPart("Floor", Vector3.new(60, 1, 40), Vector3.new(0, 0.5, 40), Color3.fromRGB(40, 40, 60), trainingZone, Enum.Material.SmoothPlastic)

		-- 脚力エリア（左側）
		createPart("LegPowerArea", Vector3.new(16, 0.5, 16), Vector3.new(-18, 1, 40), Color3.fromRGB(52, 152, 219), trainingZone)
		createSign("🦵 脚力", Vector3.new(10, 6, 0.5), Vector3.new(-18, 5, 32), trainingZone)

		-- ジャンプエリア（中央）
		createPart("JumpArea", Vector3.new(16, 0.5, 16), Vector3.new(0, 1, 40), Color3.fromRGB(39, 174, 96), trainingZone)
		createSign("⬆️ ジャンプ", Vector3.new(10, 6, 0.5), Vector3.new(0, 5, 32), trainingZone)

		-- 飛行エリア（右側）
		createPart("FlightArea", Vector3.new(16, 0.5, 16), Vector3.new(18, 1, 40), Color3.fromRGB(142, 68, 173), trainingZone)
		createSign("🪽 飛行", Vector3.new(10, 6, 0.5), Vector3.new(18, 5, 32), trainingZone)
	end

	-- 3. 発射台
	local launchPad = Workspace:FindFirstChild("LaunchPad")
	if not launchPad then
		launchPad = Instance.new("Model")
		launchPad.Name = "LaunchPad"
		launchPad.Parent = Workspace

		-- ランプ本体
		local ramp = createWedge("Ramp", Vector3.new(20, 20, 40), Vector3.new(0, 10, 90), Color3.fromRGB(255, 170, 0), launchPad)
		
		-- ジャンプパッド（ランプ頂上）
		createPart("JumpPad", Vector3.new(20, 1, 10), Vector3.new(0, 21, 105), Color3.fromRGB(255, 255, 0), launchPad)

		-- 矢印看板
		createSign("🚀 発射台 →", Vector3.new(12, 8, 0.5), Vector3.new(0, 10, 68), launchPad)
	end

	-- 4. 高度マーカー
	local altitudeMarkers = Workspace:FindFirstChild("AltitudeMarkers")
	if not altitudeMarkers then
		altitudeMarkers = Instance.new("Model")
		altitudeMarkers.Name = "AltitudeMarkers"
		altitudeMarkers.Parent = Workspace

		-- 高度100
		local m100 = createPart("Marker100", Vector3.new(30, 1, 30), Vector3.new(0, 100, 105), Color3.fromRGB(100, 200, 100), altitudeMarkers, nil, 0.7)
		m100.CanCollide = false
		
		-- 高度500
		local m500 = createPart("Marker500", Vector3.new(30, 1, 30), Vector3.new(0, 500, 105), Color3.fromRGB(100, 100, 200), altitudeMarkers, nil, 0.7)
		m500.CanCollide = false

		-- 高度1000
		local m1000 = createPart("Marker1000", Vector3.new(30, 1, 30), Vector3.new(0, 1000, 105), Color3.fromRGB(255, 215, 0), altitudeMarkers, nil, 0.6)
		m1000.CanCollide = false
		createSign("🌙 月まであと少し！", Vector3.new(20, 8, 0.5), Vector3.new(0, 1010, 105), altitudeMarkers)

		-- 高度5000
		local m5000 = createPart("Marker5000", Vector3.new(30, 1, 30), Vector3.new(0, 5000, 105), Color3.fromRGB(255, 100, 100), altitudeMarkers, nil, 0.6)
		m5000.CanCollide = false
		createSign("🔴 火星が見えてきた！", Vector3.new(20, 8, 0.5), Vector3.new(0, 5010, 105), altitudeMarkers)
	end
end

buildMap()
