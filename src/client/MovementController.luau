-- キャラクターのWalkSpeed/JumpPowerをPlayerDataに基づいて更新する

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerData = require(ReplicatedStorage.Shared.PlayerData)
local Config     = require(ReplicatedStorage.Shared.Config)
local Effects    = require(script.Parent.Effects)

local LocalPlayer = Players.LocalPlayer

local MovementController = {}

-- 現在のキャラクター／Humanoid参照（リスポーン時に差し替え）
local character: Model?   = nil
local humanoid: Humanoid? = nil
local trailActive         = false

-- ─────────────────────────────────────────
-- 内部ヘルパー
-- ─────────────────────────────────────────

local function applyStats()
	if not humanoid or not character then return end
	local d = PlayerData.getData()

	humanoid.WalkSpeed = math.min(
		Config.Speed.Base + (d.Speed :: number) * Config.Speed.Multiplier,
		Config.Speed.Max
	)
	humanoid.JumpPower = math.min(
		Config.Jump.Base + (d.JumpPower :: number) * Config.Jump.Multiplier,
		Config.Jump.Max
	)

	-- Speed stat > 100 のときダッシュトレイルを有効化
	local shouldTrail = (d.Speed :: number) > 100
	if shouldTrail ~= trailActive then
		trailActive = shouldTrail
		Effects.dashTrail(character, shouldTrail)
	end
end

local function onCharacterAdded(newCharacter: Model)
	-- 旧キャラクターのトレイルをキャッシュから除去
	if character then
		Effects.dashTrail(character, false)
	end

	character    = newCharacter
	trailActive  = false
	humanoid     = newCharacter:WaitForChild("Humanoid") :: Humanoid
	applyStats()
end

-- ─────────────────────────────────────────
-- 公開API
-- ─────────────────────────────────────────

function MovementController.update()
	applyStats()
end

function MovementController.init()
	local char = LocalPlayer.Character
	if char then
		onCharacterAdded(char)
	end

	LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
end

return MovementController
