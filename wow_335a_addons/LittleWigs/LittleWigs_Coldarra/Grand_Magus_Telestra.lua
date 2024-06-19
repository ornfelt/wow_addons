-------------------------------------------------------------------------------
--  Module Declaration

local mod = BigWigs:NewBoss("Grand Magus Telestra", "The Nexus")
if not mod then return end
mod.partyContent = true
mod.otherMenu = "Coldarra"
mod:RegisterEnableMob(26731)
mod.toggleOptions = {"split", "bosskill"}

-------------------------------------------------------------------------------
--  Locals

local split1announced = nil
local split2announced = nil
local difficulty

-------------------------------------------------------------------------------
--  Localization

local L = mod:NewLocale("enUS", true)
if L then

L["split"] = "Split"
L["split_desc"] = "Warn when Grand Magus Telestra is about to split."
L["split_soon_message"] = "Spliting Soon"

end
L = mod:GetLocale()

-------------------------------------------------------------------------------
--  Initialization

function mod:OnBossEnable()
	self:Death("Win", 26731)
	
	if bit.band(self.db.profile.split, BigWigs.C.MESSAGE) == BigWigs.C.MESSAGE then
		self:RegisterEvent("UNIT_HEALTH")
	end

	difficulty = GetInstanceDifficulty()
end

function mod:OnEngage()
	split1announced = nil
	split2announced = nil
end

-------------------------------------------------------------------------------
--  Event Handlers

function mod:UNIT_HEALTH(event, msg)
	local guid = tonumber(UnitGUID(msg):sub(-12, -7), 16)
	if guid ~= 26731 then return end
	local currentHealth = UnitHealth(msg)
	local maxHealth = UnitHealthMax(msg)
	local health = (currentHealth/maxHealth)*100
	if health > 51 and health <= 55 and not split1announced then
		self:Message("split", L["split_soon_message"], "Attention")
		split1announced = true
	elseif difficulty == 2 and not split2announced and health > 11 and health <= 15 then
		self:Message("split", L["split_soon_message"], "Attention")
		split2announced = true
	elseif (split1announced or split2announced) and health > 60 then
		split1announced = false
		split2announced = false
	end
end
