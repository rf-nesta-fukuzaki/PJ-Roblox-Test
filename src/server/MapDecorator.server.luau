-- マップビジュアル装飾スクリプト
-- ゲームプレイ用パーツのCanCollide/Position/Sizeは一切変更しない

local Lighting  = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local rng = Random.new(12345)  -- 再現性のある乱数

-- ─────────────────────────────────────────
-- ユーティリティ
-- ─────────────────────────────────────────

local function rand(min, max)
	return rng:NextNumber(min, max)
end

local function randInt(min, max)
	return rng:NextInteger(min, max)
end

local function addPointLight(parent: Instance, color: Color3, range: number, brightness: number?)
	local light = Instance.new("PointLight")
	light.Color      = color
	light.Range      = range
	light.Brightness = brightness or 1
	light.Parent     = parent
end

local function addSpotLight(parent: Instance, color: Color3, range: number, angle: number)
	local light = Instance.new("SpotLight")
	light.Color      = color
	light.Range      = range
	light.Angle      = angle
	light.Face       = Enum.NormalId.Bottom
	light.Brightness = 1
	light.Parent     = parent
end

-- 装飾パーツの識別タグ（GetDescendants時にスキップ）
local DECO_NAMES = {
	GrassDecor = true, FlowerDecor = true, Star = true,
	CloudDecor = true, CloudLayer500 = true, SpaceSphere = true,
}

-- ─────────────────────────────────────────
-- 1. Lighting セットアップ
-- ─────────────────────────────────────────

local function setupLighting()
	Lighting.Technology = Enum.Technology.Future
	Lighting.Brightness = 3
	Lighting.ClockTime  = 14

	-- Atmosphere（なければ作成、あれば上書き）
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
		or Instance.new("Atmosphere", Lighting)
	atmo.Density = 0.3
	atmo.Color   = Color3.fromRGB(200, 220, 255)
	atmo.Decay   = Color3.fromRGB(180, 180, 220)
	atmo.Haze    = 2

	-- BloomEffect
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
		or Instance.new("BloomEffect", Lighting)
	bloom.Intensity  = 0.3
	bloom.Size       = 24
	bloom.Threshold  = 1.1

	-- SunRaysEffect
	local sunrays = Lighting:FindFirstChildOfClass("SunRaysEffect")
		or Instance.new("SunRaysEffect", Lighting)
	sunrays.Intensity = 0.1
	sunrays.Spread    = 0.5
end

-- ─────────────────────────────────────────
-- 2. 各高度帯の足場装飾
-- ─────────────────────────────────────────

-- 低層（Y 10〜100）: 草・花パーツ 3〜5個
local function decorateLow(part: BasePart)
	local topY   = part.Position.Y + part.Size.Y * 0.5
	local count  = randInt(3, 5)
	for i = 1, count do
		local deco = Instance.new("Part")
		deco.Name       = "GrassDecor"
		deco.Anchored   = true
		deco.CanCollide = false
		deco.CastShadow = false
		local sz = rand(0.5, 1.0)
		deco.Size     = Vector3.new(sz, sz * 1.6, sz)
		deco.Position = Vector3.new(
			part.Position.X + rand(-part.Size.X * 0.3, part.Size.X * 0.3),
			topY + sz * 0.8,
			part.Position.Z + rand(-part.Size.Z * 0.3, part.Size.Z * 0.3)
		)
		-- 緑系と黄色系をランダムで
		if randInt(1, 2) == 1 then
			deco.Color = Color3.fromRGB(randInt(50, 100), randInt(150, 200), randInt(40, 70))
		else
			deco.Color = Color3.fromRGB(randInt(220, 255), randInt(200, 230), randInt(30, 70))
		end
		deco.Material = Enum.Material.Grass
		deco.Parent   = part
	end
end

-- 中層（Y 100〜500）: Marble化 + SpotLight
local function decorateMid(part: BasePart)
	if part.Material ~= Enum.Material.Neon then
		part.Material = Enum.Material.Marble
	end
	if not part:FindFirstChildOfClass("SpotLight") then
		addSpotLight(part, Color3.fromRGB(150, 180, 255), 20, 50)
	end
end

-- 高層（Y 500〜2000）: Neon紫 + PointLight
local function decorateHigh(part: BasePart)
	part.Material = Enum.Material.Neon
	part.Color    = Color3.fromRGB(160, 80, 220)
	if not part:FindFirstChildOfClass("PointLight") then
		addPointLight(part, Color3.fromRGB(160, 80, 220), 15)
	end
end

-- 超高層（Y 2000+）: Neon金 + PointLight + 星パーツ 2〜3個
local function decorateUltra(part: BasePart)
	part.Material = Enum.Material.Neon
	part.Color    = Color3.fromRGB(255, 215, 0)
	if not part:FindFirstChildOfClass("PointLight") then
		addPointLight(part, Color3.fromRGB(255, 215, 0), 18, 1.2)
	end

	local starCount = randInt(2, 3)
	for i = 1, starCount do
		local star = Instance.new("Part")
		star.Name       = "Star"
		star.Anchored   = true
		star.CanCollide = false
		star.CastShadow = false
		star.Size       = Vector3.new(1, 1, 1)
		star.Shape      = Enum.PartType.Ball
		star.Material   = Enum.Material.Neon
		star.Color      = Color3.fromRGB(255, 255, 255)
		star.Position   = Vector3.new(
			part.Position.X + rand(-30, 30),
			part.Position.Y + rand(-12, 15),
			part.Position.Z + rand(-30, 30)
		)
		star.Parent = part
	end
end

-- ─────────────────────────────────────────
-- 3. 環境パーツ（雲・宇宙）
-- ─────────────────────────────────────────

local function buildEnvironment(parent: Instance)
	-- 中層の雲: 高度200〜400に8個（Ball形状で柔らかい印象）
	for i = 1, 8 do
		local cloud = Instance.new("Part")
		cloud.Name         = "CloudDecor"
		cloud.Anchored     = true
		cloud.CanCollide   = false
		cloud.CastShadow   = false
		cloud.Shape        = Enum.PartType.Ball
		local w = rand(50, 100)
		cloud.Size         = Vector3.new(w, w * 0.35, w * 0.6)
		cloud.Position     = Vector3.new(
			rand(-150, 150),
			rand(200, 400),
			90 + rand(-80, 80)
		)
		cloud.Color        = Color3.fromRGB(randInt(230, 245), randInt(235, 250), 255)
		cloud.Material     = Enum.Material.SmoothPlastic
		cloud.Transparency = 0.85
		cloud.Parent       = parent
	end

	-- 高度500: 巨大な雲の層（足場の下から見上げると雲を突き抜ける演出）
	local layer = Instance.new("Part")
	layer.Name         = "CloudLayer500"
	layer.Anchored     = true
	layer.CanCollide   = false
	layer.CastShadow   = false
	layer.Size         = Vector3.new(500, 1, 500)
	layer.Position     = Vector3.new(0, 497, 100)
	layer.Color        = Color3.fromRGB(240, 245, 255)
	layer.Material     = Enum.Material.SmoothPlastic
	layer.Transparency = 0.90
	layer.Parent       = parent

	-- 高度3000+: 暗い巨大球体で宇宙空間演出
	local spaceSphere = Instance.new("Part")
	spaceSphere.Name         = "SpaceSphere"
	spaceSphere.Anchored     = true
	spaceSphere.CanCollide   = false
	spaceSphere.CastShadow   = false
	spaceSphere.Shape        = Enum.PartType.Ball
	spaceSphere.Size         = Vector3.new(5000, 5000, 5000)
	spaceSphere.Position     = Vector3.new(0, 3500, 100)
	spaceSphere.Color        = Color3.fromRGB(5, 5, 20)
	spaceSphere.Material     = Enum.Material.SmoothPlastic
	spaceSphere.Transparency = 0.87
	spaceSphere.Parent       = parent
end

-- ─────────────────────────────────────────
-- 4. トレーニングゾーン装飾
-- ─────────────────────────────────────────

local function decorateTrainingZone()
	local tz = Workspace:FindFirstChild("TrainingZone")
	if not tz then return end

	-- 各エリアのBasePart（名前に"Area"を含む）にPointLightを追加
	for _, child in ipairs(tz:GetDescendants()) do
		if child:IsA("BasePart") and child.Name:find("Area") then
			if not child:FindFirstChildOfClass("PointLight") then
				addPointLight(child, child.Color, 14, 1.5)
			end
		end
	end

	-- 床にも薄い環境光
	local floor = tz:FindFirstChild("Floor")
	if floor and floor:IsA("BasePart") then
		if not floor:FindFirstChildOfClass("PointLight") then
			addPointLight(floor, Color3.fromRGB(200, 220, 255), 30, 0.4)
		end
	end

	-- Neon枠線: 床パーツからサイズを推定して配置
	if floor and floor:IsA("BasePart") then
		local cx  = floor.Position.X
		local cz  = floor.Position.Z
		local y   = floor.Position.Y + floor.Size.Y * 0.5 + 0.2
		local hw  = floor.Size.X * 0.5
		local hd  = floor.Size.Z * 0.5
		local nc  = Color3.fromRGB(100, 180, 255)
		local th  = 0.3

		local borderDefs = {
			{ pos = Vector3.new(cx,      y, cz - hd), size = Vector3.new(floor.Size.X, th, th) },
			{ pos = Vector3.new(cx,      y, cz + hd), size = Vector3.new(floor.Size.X, th, th) },
			{ pos = Vector3.new(cx - hw, y, cz),      size = Vector3.new(th, th, floor.Size.Z) },
			{ pos = Vector3.new(cx + hw, y, cz),      size = Vector3.new(th, th, floor.Size.Z) },
		}
		for i, b in ipairs(borderDefs) do
			if not tz:FindFirstChild("NeonBorder" .. i) then
				local border = Instance.new("Part")
				border.Name       = "NeonBorder" .. i
				border.Anchored   = true
				border.CanCollide = false
				border.CastShadow = false
				border.Size       = b.size
				border.Position   = b.pos
				border.Color      = nc
				border.Material   = Enum.Material.Neon
				border.Parent     = tz
			end
		end
	end
end

-- ─────────────────────────────────────────
-- 5. プラットフォーム装飾メイン
-- ─────────────────────────────────────────

local function decoratePlatforms()
	local folder = Workspace:FindFirstChild("Platforms")
	if not folder then
		warn("MapDecorator: Workspace.Platforms が見つかりません。スキップします。")
		return
	end

	-- 二重装飾防止フラグ
	if folder:FindFirstChild("_decorated") then return end
	local flag = Instance.new("BoolValue")
	flag.Name   = "_decorated"
	flag.Parent = folder

	-- GetDescendantsで全BasePart取得（装飾用は除外）
	for _, part in ipairs(folder:GetDescendants()) do
		if not part:IsA("BasePart") then continue end
		if DECO_NAMES[part.Name] then continue end

		local y = part.Position.Y

		if y >= 10 and y < 100 then
			decorateLow(part)
		elseif y >= 100 and y < 500 then
			decorateMid(part)
		elseif y >= 500 and y < 2000 then
			decorateHigh(part)
		elseif y >= 2000 then
			decorateUltra(part)
		end
	end

	-- 環境フォルダに雲・宇宙球体を追加
	local envFolder = Workspace:FindFirstChild("Environment")
	if not envFolder then
		envFolder      = Instance.new("Folder")
		envFolder.Name = "Environment"
		envFolder.Parent = Workspace
	end
	if not envFolder:FindFirstChild("CloudLayer500") then
		buildEnvironment(envFolder)
	end
end

-- ─────────────────────────────────────────
-- エントリーポイント
-- ─────────────────────────────────────────

setupLighting()
decoratePlatforms()
decorateTrainingZone()
