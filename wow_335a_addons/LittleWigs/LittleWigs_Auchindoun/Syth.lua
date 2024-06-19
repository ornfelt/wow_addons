------------------------------
--      Are you local?      --
------------------------------

local boss = BB["Darkweaver Syth"]
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)

local db = nil

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function() return {
	cmd = "Syth",

	summon = "Elementals Alert",
	summon_desc = "Warn for Summoned Elementals",
	summon_message = "Elementals Summoned!",
} end )

L:RegisterTranslations("koKR", function() return {
	summon = "정령 알림",
	summon_desc = "정령 소환에 대해 알립니다.",
	summon_message = "정령 소환!",
} end )

L:RegisterTranslations("zhTW", function() return {
	summon = "召喚元素警報",
	summon_desc = "召喚元素生物時發出警報",
	summon_message = "希斯元素已被召喚出來!",
} end )

L:RegisterTranslations("frFR", function() return {
	summon = "Élémentaires",
	summon_desc = "Prévient quand Syth invoque ses élémentaires.",
	summon_message = "Élémentaires invoqués !",
} end )

L:RegisterTranslations("esES", function() return {
	summon = "Alerta de Elementales",
	summon_desc = "Aviso de Invocaci?n de Elementales",
	summon_message = "Elementales Invocados!",
} end )

L:RegisterTranslations("zhCN", function() return {
	summon = "元素警报",
	summon_desc = "当召唤元素时发出警报。",
	summon_message = "元素已被召唤！",
} end )

L:RegisterTranslations("deDE", function() return {
	summon = "Elementare-Warnung",
	summon_desc = "Warnt vor beschworenen Elementaren",
	summon_message = "Elementare beschworen!",
} end )

L:RegisterTranslations("ruRU", function() return {
	summon = "Предупреждение о Элементалях",
	summon_desc = "Предупреждать о призыве Элементалей",
	summon_message = "Призваны Элементали!",
} end )

----------------------------------
--      Module Declaration      --
----------------------------------

local mod = BigWigs:NewModule(boss)
mod.partyContent = true
mod.otherMenu = "Auchindoun"
mod.zonename = BZ["Sethekk Halls"]
mod.enabletrigger = boss 
mod.guid = 18472
mod.toggleoptions = {"summon", "bosskill"}
mod.revision = tonumber(("$Revision: 79829 $"):sub(12, -3))

------------------------------
--      Initialization      --
------------------------------

function mod:OnEnable()
	self:AddCombatListener("SPELL_SUMMON", "Summon", 33538)
	self:AddCombatListener("UNIT_DIED", "BossDeath")

	db = self.db.profile
end

------------------------------
--      Event Handlers      --
------------------------------

function mod:Summon()
	if db.summon then
		self:Message(L["summon_message"], "Attention")
	end
end
