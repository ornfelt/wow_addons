-- lua50: native
setfenv(1, SkadaEnv)
-- Compat.lua - Skada on the 1.12 client (interface 11200): the TBC port's Compat.lua for 1.12.
--
-- Loaded after Classic/Env.lua (the Lua 5.1 library, CreateFrame, GetSpellInfo, GUIDs ...). As in the
-- TBC port it fills in the 3.x API the rest of the code expects, but every value goes into SkadaEnv
-- (SkadaShim) instead of the globals: other vanilla addons tell the client version apart by globals
-- such as GetActiveTalentGroup, so Skada must not add any.

local ADDON_NAME = "Skada"
local private = {}

-- the addon's name and private table, as 3.x passes them to each file through "..."
function SkadaAddonArgs(name, ns)
	if ns then return name, ns end
	return ADDON_NAME, private
end

local G = getfenv(0)
local type, pairs = type, pairs

-------------------------------------------------------------------------------
-- game API

-- one talent group, no glyphs, no dual spec
SkadaShim("GetActiveTalentGroup", function() return 1 end)
SkadaShim("GetNumTalentGroups", function() return 1 end)
SkadaShim("GetNumGlyphSockets", function() return 0 end)
SkadaShim("GetGlyphSocketInfo", function() end)
SkadaShim("TALENT_ACTIVATION_SPELLS", {})
SkadaShim("GetUnspentTalentPoints", function(inspect)
	if inspect then return 0 end
	return (UnitCharacterPoints("player")) or 0
end)

-- no LFG roles, vehicles or zone map ids in 1.12
SkadaShim("UnitGroupRolesAssigned", function() return "NONE" end)
SkadaShim("UnitHasVehicleUI", function() return false end)
SkadaShim("GetCurrentMapAreaID", function() return 0 end)

-- one power type per unit (UnitMana): another type reads as 0
local UnitPowerType, UnitMana, UnitManaMax = UnitPowerType, UnitMana, UnitManaMax
SkadaShim("UnitPower", function(unit, powerType)
	if powerType and powerType ~= UnitPowerType(unit) then return 0 end
	return UnitMana(unit)
end)
SkadaShim("UnitPowerMax", function(unit, powerType)
	if powerType and powerType ~= UnitPowerType(unit) then return 0 end
	return UnitManaMax(unit)
end)

SkadaShim("GetDungeonDifficulty", function() return 1 end)
SkadaShim("GetRaidDifficulty", function() return 1 end)

-- raid sizes of the classic raids; the smallest that holds the raid
local RAID_SIZES = {10, 20, 40}
local PARTY_SIZE = 5

-- name, type, difficulty, difficulty name, max players, dynamic difficulty, is dynamic
SkadaShim("GetInstanceInfo", function()
	local _, instanceType = IsInInstance()
	instanceType = instanceType or "none"
	local maxPlayers
	if instanceType == "party" then
		maxPlayers = PARTY_SIZE
	elseif instanceType == "raid" then
		local members = GetNumRaidMembers()
		for i = 1, table.getn(RAID_SIZES) do
			maxPlayers = RAID_SIZES[i]
			if members <= maxPlayers then break end
		end
	end
	return GetRealZoneText(), instanceType, 1, nil, maxPlayers, 0, false
end)

-- no Interface Options in 1.12: Skada's options open in their own window
SkadaShim("InterfaceOptions_AddCategory", function() end)
SkadaShim("InterfaceOptionsFrame_OpenToCategory", function()
	LibStub("AceConfigDialog-3.0"):Open(ADDON_NAME)
end)

SkadaShim("ChatEdit_GetActiveWindow", function()
	local editBox = G.ChatFrameEditBox
	if editBox and editBox:IsShown() then return editBox end
end)
SkadaShim("ChatEdit_InsertLink", function(text)
	local editBox = ChatEdit_GetActiveWindow()
	if editBox then
		editBox:Insert(text)
		return true
	end
end)

-------------------------------------------------------------------------------
-- tables and constants

SkadaShim("CLASS_SORT_ORDER", {"WARRIOR", "PALADIN", "PRIEST", "SHAMAN", "DRUID", "ROGUE", "MAGE", "WARLOCK", "HUNTER"})

do
	-- the client's own names where its strings have them, else English
	local names = {
		WARRIOR = "Warrior", PALADIN = "Paladin", PRIEST = "Priest", SHAMAN = "Shaman", DRUID = "Druid",
		ROGUE = "Rogue", MAGE = "Mage", WARLOCK = "Warlock", HUNTER = "Hunter"
	}
	for class in pairs(names) do
		local localized = G[class]
		if type(localized) == "string" and localized ~= "" then
			names[class] = localized
		end
	end
	SkadaShim("LOCALIZED_CLASS_NAMES_MALE", names)
	SkadaShim("LOCALIZED_CLASS_NAMES_FEMALE", names)
end

-- class icons (Interface\Glues\CharacterCreate\UI-CharacterCreate-Classes)
SkadaShim("CLASS_ICON_TCOORDS", {
	WARRIOR = {0, 0.25, 0, 0.25}, MAGE = {0.25, 0.49609375, 0, 0.25}, ROGUE = {0.49609375, 0.7421875, 0, 0.25},
	DRUID = {0.7421875, 0.98828125, 0, 0.25}, HUNTER = {0, 0.25, 0.25, 0.5}, SHAMAN = {0.25, 0.49609375, 0.25, 0.5},
	PRIEST = {0.49609375, 0.7421875, 0.25, 0.5}, WARLOCK = {0.7421875, 0.98828125, 0.25, 0.5}, PALADIN = {0, 0.25, 0.5, 0.75}
})

SkadaShim("YELLOW_FONT_COLOR", {r = 1, g = 1, b = 0})
SkadaShim("ORANGE_FONT_COLOR", {r = 1, g = 0.5, b = 0.25})
SkadaShim("GREEN_FONT_COLOR", {r = 0.1, g = 1, b = 0.1})
SkadaShim("RED_FONT_COLOR", {r = 1, g = 0.1, b = 0.1})

-- the spell schools' names (1.12 calls them SPELL_SCHOOLn_CAP)
local SCHOOLS = {"PHYSICAL", "HOLY", "FIRE", "NATURE", "FROST", "SHADOW", "ARCANE"}
for i = 1, table.getn(SCHOOLS) do
	SkadaShim("STRING_SCHOOL_" .. SCHOOLS[i], G["SPELL_SCHOOL" .. (i - 1) .. "_CAP"] or SCHOOLS[i])
end
SkadaShim("STRING_SCHOOL_UNKNOWN", G.UNKNOWN or "Unknown")

-- power types
SkadaShim("SPELL_POWER_MANA", 0)
SkadaShim("SPELL_POWER_RAGE", 1)
SkadaShim("SPELL_POWER_FOCUS", 2)
SkadaShim("SPELL_POWER_ENERGY", 3)
SkadaShim("SPELL_POWER_HAPPINESS", 4)
SkadaShim("SPELL_POWER_RUNIC_POWER", 6)
