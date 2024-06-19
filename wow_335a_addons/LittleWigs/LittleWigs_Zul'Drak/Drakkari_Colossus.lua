-------------------------------------------------------------------------------
--  Module Declaration

local mod = BigWigs:NewBoss("Drakkari Colossus", "Gundrak")
if not mod then return end
mod.partyContent = true
mod.otherMenu = "Zul'Drak"
mod:RegisterEnableMob(29307)
mod.toggleOptions = {
	54850, -- Emerge
	54878, -- Merge
	"bosskill",
}

-------------------------------------------------------------------------------
--  Localization

local L = mod:NewLocale("enUS", true)
if L then

L["emerge_message"] = "Elemental Emerging"
L["merge_message"] = "Merging with Colossus"

end
L = mod:GetLocale()

-------------------------------------------------------------------------------
--  Initialization

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "Emerge", 54850) -- To Elemental
	self:Log("SPELL_CAST_START", "Merge", 54878) -- To Colossus
	self:Death("Win", 29307)
end

-------------------------------------------------------------------------------
--  Event Handlers

function mod:Emerge(_, spellId)
	self:Message(54850, L["emerge_message"], "Urgent", spellId)
end

function mod:Merge(_, spellId)
	self:Message(54878, L["merge_message"], "Urgent", spellId)
end
