------------------------------
--      Are you local?      --
------------------------------

local boss = BB["Shirrak the Dead Watcher"]
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function() return {
	cmd = "Shirrak",

	focus = "Focus Fire",
	focus_desc = "Warn which play is being Focus Fired.",
	focus_message = "%s has Focus Fire",
} end )

L:RegisterTranslations("zhCN", function() return {
	focus = "集中火力",
	focus_desc = "当受到集中火力,警告躲开人群",
	focus_message = "集中活力>%s< 躲开",
} end )

L:RegisterTranslations("zhTW", function() return {
	focus = "專注之火",
	focus_desc = "當玩家受到專注之火時發出警報",
	focus_message = "專注之火: >%s<",
} end )

L:RegisterTranslations("koKR", function() return {
	focus = "집중의 불꽃",
	focus_desc = "집중의 불꽃 대상자를 알립니다.",
	focus_message = "%s 집중의 불꽃",
} end )

L:RegisterTranslations("frFR", function() return {
	focus = "Focalisation du feu",
	focus_desc = "Prévient sur quel joueur la Focalisation du feu est incantée.",
	focus_message = "Focalisation du feu sur %s !",
} end )

L:RegisterTranslations("ruRU", function() return {
	focus = "Фокусировка огня",
	focus_desc = "Предупреждает на каком игроке Фокусировка огня.",
	focus_message = "На %s Фокусировка огня",
} end )

----------------------------------
--      Module Declaration      --
----------------------------------

local mod = BigWigs:NewModule(boss)
mod.partyContent = true
mod.otherMenu = "Auchindoun"
mod.zonename = BZ["Auchenai Crypts"]
mod.enabletrigger = boss 
mod.guid = 18371
mod.toggleoptions = {"focus", "bosskill"}
mod.revision = tonumber(("$Revision: 79829 $"):sub(12, -3))

------------------------------
--      Initialization      --
------------------------------

function mod:OnEnable()
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
	self:AddCombatListener("UNIT_DIED", "BossDeath")
end

------------------------------
--      Event Handlers      --
------------------------------

function mod:CHAT_MSG_RAID_BOSS_EMOTE(_, _, _, _, player)
	if self.db.profile.focus then
		self:IfMessage(L["focus_message"]:format(player), "Attention", 32300)
	end
end
