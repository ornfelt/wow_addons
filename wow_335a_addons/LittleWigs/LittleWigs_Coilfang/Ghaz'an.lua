------------------------------
--      Are you local?      --
------------------------------

local boss = BB["Ghaz'an"]
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)

local db = nil

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function() return {
	cmd = "Ghaz'an",
} end )

----------------------------------
--      Module Declaration      --
----------------------------------

local mod = BigWigs:NewModule(boss)
mod.partyContent = true
mod.otherMenu = "Coilfang Reservoir"
mod.zonename = BZ["The Underbog"]
mod.enabletrigger = boss
mod.guid = 18105
mod.toggleoptions = {"bosskill"}
mod.revision = tonumber(("$Revision: 76984 $"):sub(12, -3))

------------------------------
--      Initialization      --
------------------------------

function mod:OnEnable()
	self:AddCombatListener("UNIT_DIED", "BossDeath")

	db = self.db.profile
end

------------------------------
--      Event Handlers      --
------------------------------
