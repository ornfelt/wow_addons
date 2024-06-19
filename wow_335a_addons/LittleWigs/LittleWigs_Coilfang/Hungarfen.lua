------------------------------
--      Are you local?      --
------------------------------

local boss = BB["Hungarfen"]
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)

local sporesannounced = nil
local db = nil

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function() return {
	cmd = "Hungarfen",

	shroom = "Underbog Mushroom",
	shroom_desc = "Warn when an Underbog Mushroom spawns",
	shroom_message = "Underbog Mushroom spawning!",

	spores = "Foul Spores",
	spores_desc = "Warn for when Hungarfen roots himself casts Foul Spores",
	spores_message = "Foul Spores Soon!",
} end )

L:RegisterTranslations("frFR", function() return {
	shroom = "Champignon de Basse-tourbière",
	shroom_desc = "Prévient quand un Champignon de Basse-tourbière apparaît.",
	shroom_message = "Apparition d'un Champignon de Basse-tourbière !",

	spores = "Spores nauséabondes",
	spores_desc = "Prévient quand Hungarfen se sarmente et incante ses Spores nauséabondes.",
	spores_message = "Spores nauséabondes imminentes !",
} end )

L:RegisterTranslations("koKR", function() return {
	shroom = "지하수렁 버섯",
	shroom_desc = "지하수렁 버섯 생성에 대해 알립니다.",
	shroom_message = "지하수렁 버섯 생성!",

	spores = "더러운 곰팡이",
	spores_desc = "헝가르펜의 자신의 뿌리감기 후 더러운 곰팡이 시전에 대해 알립니다.",
	spores_message = "잠시 후 더러운 곰팡이!",
} end )

L:RegisterTranslations("zhCN", function() return {
	shroom = "幽暗沼泽蘑菇",
	shroom_desc = "当施放幽暗沼泽蘑菇时发出警报。",
	shroom_message = "幽暗沼泽蘑菇幼体！躲避！",

	spores = "邪恶孢子",
	spores_desc = "当施放邪恶孢子时发出警报。",
	spores_message = "邪恶孢子！躲避！",
} end )

L:RegisterTranslations("zhTW", function() return {
	shroom = "幽暗沼澤蘑菇",
	shroom_desc = "當施放幽暗沼澤蘑菇時發出警報",
	shroom_message = "幽暗沼澤蘑菇幼體! 躲避!",

	spores = "邪惡孢子",
	spores_desc = "當施放邪惡孢子時發出警報",
	spores_message = "邪惡孢子! 躲避!",
} end )

L:RegisterTranslations("ruRU", function() return {
	shroom = "Гриб Нижетопи",
	shroom_desc = "Предупреждать о появлении грибов Нижетопи",
	shroom_message = "Появились грибы Нижетопи!",

	spores = "Гнилые споры",
	spores_desc = "Предупреждать когда Голоднец окутывает себя в корни и произносить заклинание Гнилых спор",
	spores_message = "Скоро Гнилые споры!",
} end )
----------------------------------
--      Module Declaration      --
----------------------------------

local mod = BigWigs:NewModule(boss)
mod.partyContent = true
mod.otherMenu = "Coilfang Reservoir"
mod.zonename = BZ["The Underbog"]
mod.enabletrigger = boss
mod.guid = 17770
mod.toggleoptions = {"shroom", "spores", "bosskill"}
mod.revision = tonumber(("$Revision: 79696 $"):sub(12, -3))

------------------------------
--      Initialization      --
------------------------------

function mod:OnEnable()
	self:RegisterEvent("UNIT_HEALTH")
	self:AddCombatListener("SPELL_CAST_SUCCESS", "Shroom", 31693)
	self:AddCombatListener("UNIT_DIED", "BossDeath")

	sporesannounced = nil
	db = self.db.profile
end

------------------------------
--      Event Handlers      --
------------------------------
--
function mod:Shroom()
	if db.shroom then
		self:Message(L["shroom_message"], "Important", nil, nil, nil, 31693)
	end
end

function mod:UNIT_HEALTH(arg1)
	if not db.spores then
		self:UnregisterEvent("UNIT_HEALTH")
		return
	end
	if UnitName(arg1) == boss then
		local health = UnitHealth(arg1)
		if health > 18 and health <= 24 and not sporesannounced then
			sporesannounced = true
			self:Message(L["spores_message"], "Urgent", nil, nil, nil, 31673)
		elseif health > 28 and sporesannounced then
			sporesannounced = nil
		end
	end
end
