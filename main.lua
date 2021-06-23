local Esau = RegisterMod("Friendly Esau in empty rooms", 1)
local game = Game()

-- :P
local enableDebugInfo = false

local settings = {
	modCompilcatedness = true, -- Just charm Esau(false) or enable all the logic i made(true)
	
	ghostFormImmuneToEsau = true,
	esauJacobLivesBehaviour = 0,
	esauGhostFormBehaviour = 0, -- UNFFRIENDLY(0), FRIENDLY(1), HELPFUL(2)
	-- Would anybody even want an option where Esau will be hostile to Jacob and harmless towards creeps?
	-- aka. DARKSIDE(3) lmao
	-- haha ima actually add it
	esauDamagePerFrame = 3, -- still pretty hefty
	esauFireDamagePerFrame = 10, -- From the wiki
	esauFireDamageDuration = 33 -- half a second i think
}

function enableMcm()
	-- local mcm = require("mcmSupport").enable(settings)
	
	--
	local config = settings
	--
	
	local modName = "Empty room Esau"
	ModConfigMenu.UpdateCategory(modName, {
		Info = {
			"Tweak additional functionality of this mod."
		}
	})
	
	-- warning
	ModConfigMenu.AddTitle(modName, "Settings", "Note that Esau will still dash")
	ModConfigMenu.AddTitle(modName, "Settings", "at Jacob if he spawns in an")
	ModConfigMenu.AddTitle(modName, "Settings", "empty room!")
	ModConfigMenu.AddTitle(modName, "Settings", "------------------------")
	ModConfigMenu.AddSpace(modName, "Settings")
	
	-- Simple mode
	function splMode()
		return not config.modCompilcatedness
	end
	
	ModConfigMenu.AddSetting(modName, "Settings", {
		Type = ModConfigMenu.OptionType.BOOLEAN,
		CurrentSetting = function()
			return config.modCompilcatedness
		end,
		Default = config.modCompilcatedness,
		Display = function()
			local should = config.modCompilcatedness
			return "Mode: " .. (should and "Custom AI (buggy)" or "Charmed")
		end,
		OnChange = function(current)
			config.modCompilcatedness = current
		end,
		Info = function()
			if(config.modCompilcatedness) then
				return "Esau will have custom behaviour, which is the whole point of this mod"
			else
				return "Esau will be charmed"
			end
		end
	})
	
	-- Jacob immunity

	ModConfigMenu.AddSetting(modName, "Settings", {
		Type = ModConfigMenu.OptionType.BOOLEAN,
		CurrentSetting = function()
			return config.ghostFormImmuneToEsau
		end,
		Default = config.ghostFormImmuneToEsau,
		Display = function()
			local isImmune = config.ghostFormImmuneToEsau
			return "Ghost form immune to Esau: " .. (isImmune and "Yes" or "No")
		end,
		OnChange = function(current)
			config.ghostFormImmuneToEsau = current
		end,
		Info = function()
			local yesno = config.ghostFormImmuneToEsau and "" or "not"
			return "Esau will " .. yesno .. " deal damage to Jacob in ghost form"
		end
	})
	
	ModConfigMenu.AddSpace(modName, "Settings")
	
	-- Esau modes
	ModConfigMenu.AddTitle(modName, "Settings",
		function()
			if splMode() then
				return "Following options have no"
			else
				return "In a hostile room:"
			end
		end
	)
	-- shenanigans
	ModConfigMenu.AddTitle(modName, "Settings",
		function()
			if splMode() then
				return " effect in 'Charmed' mode:"
			end
			return " "
		end
	)
	ModConfigMenu.AddSpace(modName, "Settings")
	
	local modeArray = {[0] = "Unfriendly", "Friendly", "Helpful", "On the Dark side"}
	local modeDescArray = 
	{
		-- eat that, lua
		[0] = "Esau behaves normally",
		"Esau will not attack Jacob",
		"Esau will not attack Jacob and deal damage to enemies",
		"Esau will attack Jacob and deal no contact damage to enemies"
	}
	-- Alive
	ModConfigMenu.AddTitle(modName, "Settings", "While Jacob is alive,")
	ModConfigMenu.AddSetting(modName, "Settings", {
		Type = ModConfigMenu.OptionType.NUMBER,
		CurrentSetting = function()
			return config.esauJacobLivesBehaviour
		end,
		Minimum = 0,
		Maximum = 3,
		Default = config.esauJacobLivesBehaviour,
		Display = function()
			return "Esau will be: " .. modeArray[config.esauJacobLivesBehaviour]
		end,
		OnChange = function(current)
			if splMode() then
				return
			end
			config.esauJacobLivesBehaviour = current
		end,
		Info = function()
			return modeDescArray[config.esauJacobLivesBehaviour]
		end
	})
	-- Ghost
	ModConfigMenu.AddTitle(modName, "Settings", "While Jacob is a ghost,")
	ModConfigMenu.AddSetting(modName, "Settings", {
		Type = ModConfigMenu.OptionType.NUMBER,
		CurrentSetting = function()
			return config.esauGhostFormBehaviour
		end,
		Minimum = 0,
		Maximum = 3,
		Default = config.esauGhostFormBehaviour,
		Display = function()
			return "Esau will be: " .. modeArray[config.esauGhostFormBehaviour]
		end,
		OnChange = function(current)
			if splMode() then
					return
			end
			config.esauGhostFormBehaviour = current
		end,
		Info = function()
			return modeDescArray[config.esauGhostFormBehaviour]
		end
	})
end

if ModConfigMenu then
	enableMcm()
end

--debugAcc = "idle"
--debugDist = "idle"

local allowMove = false
local spawnRoomSeed = 0/0 --NaN
local isHarmless = nil

function Esau:isEverythingOver()
	return Isaac.GetPlayer():GetPlayerType() == PlayerType.PLAYER_JACOB2_B
end

function Esau:getCurrentEsauMode()
	return Esau:isEverythingOver() and settings.esauGhostFormBehaviour or settings.esauJacobLivesBehaviour
end

function Esau:shouldBeFriendly()
	local mode = Esau:getCurrentEsauMode()
	local isInFriendlyMode = mode == 1 or mode == 2
	
	return isInFriendlyMode or game:GetRoom():IsClear()
end

function Esau:friendlyBehaviour(entity)
	local player = Isaac.GetPlayer(0)
	local sprite = entity:GetSprite()
	
	entity.State = NpcState.STATE_IDLE
	sprite:Play("Idle", false)
	
	local dir = player.Position - entity.Position
	local dirNorm = dir:Normalized()
	
	local endpoint = player.Position + player.Velocity
	local endpointDir = endpoint - entity.Position
	
	local dist = dir:Length()
	local endpointDist = endpointDir:Length()
	
	local xShift = endpointDist
	local acceleration = (xShift ^ 0.5) / 40
	local closeAcceleration = 1 / 18
	
	-- double the distance if helpful
	local tooClose = endpointDist < 75 * (Esau:getCurrentEsauMode() == 2 and 2 or 1)
	local near = endpointDist < 45
	
	entity:AddVelocity(endpointDir:Resized(tooClose and (near and 0 or closeAcceleration) or acceleration))
	entity.Velocity = entity.Velocity:Normalized():Resized(math.min(6, entity.Velocity:Length()))
	
	if(tooClose) then
		entity.Friction = 0.9
	else
		entity.Friction = 1
	end
	
	debugAcc = tostring(entity.Position)
	
	entity.GridCollisionClass = GridCollisionClass.COLLISION_NONE
	
	--entity:AddEntityFlags(EntityFlag.FLAG_FRIENDLY)
end

function Esau:onUpdate(entity)
	if Esau:shouldBeFriendly() then
		entity:AddEntityFlags(EntityFlag.FLAG_FRIENDLY)
		if(allowMove) then
			-- disable custom ai
			if(settings.modCompilcatedness) then
				Esau:friendlyBehaviour(entity)
				return true
			end
		end
		isHarmless = "Yes"
	else
		entity:ClearEntityFlags(EntityFlag.FLAG_FRIENDLY)
		isHarmless = "No"
	end
	
	-- ghost immunity
	if settings.ghostFormImmuneToEsau and Esau:isEverythingOver() then
		entity:AddEntityFlags(EntityFlag.FLAG_FRIENDLY)
		isHarmless = "Lost"
	end
	
	-- isHarmless = entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)
end

function Esau:onInit(entity)
	-- always friendly on init
	entity:AddEntityFlags(EntityFlag.FLAG_FRIENDLY)
	
	allowMove = not game:GetRoom():IsClear()
	
	isHarmless = nil
	
	local spawnRoom = game:GetRoom()
	spawnRoomSeed = spawnRoom:GetDecorationSeed() + spawnRoom:GetSpawnSeed()
end

function Esau:onTakeDamage(entity)
	-- if game:GetRoom():IsClear() then
		return false
	-- end
end

function Esau:onEnterRoom()
	local room = game:GetRoom()
	local seed = room:GetDecorationSeed() + room:GetSpawnSeed()
	if spawnRoomSeed ~= seed then
		allowMove = true
	end
end

function Esau:onEnemyTouch(esau, entity)
	if(settings.modCompilcatedness) then
		return nil
	end
	
	local isEnemy = entity:IsEnemy()
	local mode = Esau:getCurrentEsauMode()
	if isEnemy then
		if mode == 2 then
			print("touching enemy good")
			entity:TakeDamage(settings.esauDamagePerFrame, 0, EntityRef(esau), 0)
			entity:AddBurn(EntityRef(esau), settings.esauFireDamageDuration, settings.esauFireDamagePerFrame)
		elseif mode == 3 then
			print("touching enemy evil")
			return true
		end
	else
		print("touching player")
	end
end

Esau:AddCallback(ModCallbacks.MC_POST_NPC_INIT, Esau.onInit, EntityType.ENTITY_DARK_ESAU)
Esau:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, Esau.onUpdate, EntityType.ENTITY_DARK_ESAU)
Esau:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, Esau.onTakeDamage, EntityType.ENTITY_DARK_ESAU)
Esau:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, Esau.onEnterRoom)

Esau:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, Esau.onEnemyTouch, EntityType.ENTITY_DARK_ESAU)

if enableDebugInfo then
	function Esau:debugText()
		Isaac.RenderText("Harmless: " .. tostring(isHarmless), 100, 100, 255, 0, 0, 255)
		Isaac.RenderText("Charmed: " .. tostring(not settings.modCompilcatedness), 100, 110, 255, 0, 0, 255)
	end
	Esau:AddCallback(ModCallbacks.MC_POST_RENDER, Esau.debugText, EntityType.ENTITY_DARK_ESAU)
end
