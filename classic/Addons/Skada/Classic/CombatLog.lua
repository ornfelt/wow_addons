-- lua50: native
setfenv(1, SkadaEnv)
-- CombatLog.lua - the 1.12 combat log as 2.4.3's COMBAT_LOG_EVENT_UNFILTERED.
--
-- 1.12 has no combat log event, only combat messages in the chat (CHAT_MSG_COMBAT_* and
-- CHAT_MSG_SPELL_*): text built from GlobalStrings formats such as SPELLLOGSCHOOLSELFOTHER
-- ("Your %s hits %s for %d %s damage."). This file turns those formats into patterns (so any client
-- locale works), matches each message and calls Skada:ParseCombatLog with the arguments 2.4.3's
-- event would have had: timestamp, event, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags,
-- then the event's own arguments (Core/Functions.lua's PREFIXES / SUFFIXES).
--
-- What the text does not give is made up as well as it can be:
--   * GUIDs from the unit names (SkadaGUID in Env.lua); the unit flags from the group roster and the
--     units seen as target / mouseover (player or creature, friendly or hostile);
--   * spell ids from the spell names (SkadaSpellId, the highest rank of the name);
--   * the casters of auras: none in the text, like 2.4.3 (Functions.lua takes them from the casts);
--   * totems: owned by the shaman who last cast the totem's spell (a SPELL_SUMMON is sent);
--   * damage shields: the spell from the school (Thorns, Fire Shield, Retribution Aura ...);
--   * interrupts: the interrupting spell is the source's last spell within a second.

local G = getfenv(0)
local strfind, strsub, strlen, strlower, strgsub = string.find, string.sub, string.len, string.lower, string.gsub
local getn, floor, pairs, tonumber, type = table.getn, math.floor, pairs, tonumber, type

local CombatLog = {}
SkadaClassicCombatLog = CombatLog

-------------------------------------------------------------------------------
-- unit flags (2.4.3 values)

local AFFILIATION_MINE, AFFILIATION_PARTY, AFFILIATION_RAID, AFFILIATION_OUTSIDER = 1, 2, 4, 8
local REACTION_FRIENDLY, REACTION_NEUTRAL, REACTION_HOSTILE = 16, 32, 64
local CONTROL_PLAYER, CONTROL_NPC = 256, 512
local TYPE_PLAYER, TYPE_NPC, TYPE_PET, TYPE_GUARDIAN = 1024, 2048, 4096, 8192

local REACTIONS = {friendly = REACTION_FRIENDLY, neutral = REACTION_NEUTRAL, hostile = REACTION_HOSTILE}
local NO_GUID = "0x0000000000000000"

-------------------------------------------------------------------------------
-- the group and the units seen

local playerName
local roster = {} -- name -> {kind = "player" / "pet", affiliation = mine / party / raid, owner = name}
local seen = {} -- name -> {kind = "player" / "pet" / "npc", reaction = "friendly" / ...}
local summons = {} -- guardian name (totems) -> owner name
local SEEN_MAX = 500 -- units remembered before the list is emptied
local seenCount = 0
local inPvP = false

local function add_roster(unit, affiliation, pet)
	local name = UnitName(unit)
	if not name or name == G.UNKNOWNOBJECT then return end
	roster[name] = {kind = pet and "pet" or "player", affiliation = affiliation}
	local petUnit = pet and nil or (unit == "player" and "pet" or strgsub(unit, "^(%a+)(%d+)$", "%1pet%2"))
	if petUnit and UnitExists(petUnit) then
		local petName = UnitName(petUnit)
		if petName and petName ~= G.UNKNOWNOBJECT then
			roster[petName] = {kind = "pet", affiliation = affiliation, owner = name}
		end
	end
end

local function update_roster()
	for k in pairs(roster) do roster[k] = nil end
	playerName = UnitName("player")
	add_roster("player", AFFILIATION_MINE)
	local raid = GetNumRaidMembers()
	if raid > 0 then
		for i = 1, raid do
			if not UnitIsUnit("raid" .. i, "player") then add_roster("raid" .. i, AFFILIATION_RAID) end
		end
	else
		for i = 1, GetNumPartyMembers() do
			add_roster("party" .. i, AFFILIATION_PARTY)
		end
	end
	local _, instanceType = IsInInstance()
	inPvP = instanceType == "pvp" or instanceType == "arena"
end
CombatLog.UpdateRoster = update_roster

local function remember(unit)
	if not UnitExists(unit) then return end
	local name = UnitName(unit)
	if not name or roster[name] then return end
	local info = seen[name]
	if not info then
		if seenCount >= SEEN_MAX then
			for k in pairs(seen) do seen[k] = nil end
			seenCount = 0
		end
		info = {}
		seen[name] = info
		seenCount = seenCount + 1
	end
	info.kind = SkadaUnitKind(unit)
	if UnitIsFriend("player", unit) then
		info.reaction = "friendly"
	elseif UnitCanAttack("player", unit) then
		info.reaction = "hostile"
	else
		info.reaction = "neutral"
	end
end
CombatLog.Remember = remember

-- guid, flags of a unit name
local function unit_info(name)
	if not name then return NO_GUID, 0 end
	local r = roster[name]
	if r then
		local flags = r.affiliation + REACTION_FRIENDLY + CONTROL_PLAYER + (r.kind == "pet" and TYPE_PET or TYPE_PLAYER)
		return SkadaGUID(name, r.kind), flags
	end
	local owner = summons[name]
	if owner and roster[owner] then
		return SkadaGUID(name, "pet"), roster[owner].affiliation + REACTION_FRIENDLY + CONTROL_PLAYER + TYPE_GUARDIAN
	end
	local info = seen[name]
	local kind = info and info.kind
	if not kind then
		-- battlegrounds: a one-word name is a player
		kind = (inPvP and not strfind(name, " ")) and "player" or "npc"
	end
	local reaction = REACTIONS[info and info.reaction or "hostile"]
	local flags = AFFILIATION_OUTSIDER + reaction
	if kind == "player" then
		flags = flags + CONTROL_PLAYER + TYPE_PLAYER
	elseif kind == "pet" then
		flags = flags + CONTROL_PLAYER + TYPE_PET
	else
		flags = flags + CONTROL_NPC + TYPE_NPC
	end
	return SkadaGUID(name, kind), flags
end
CombatLog.UnitInfo = unit_info

-------------------------------------------------------------------------------
-- schools, power types, misses

local SCHOOL_BY_NAME = {}
for i = 0, 6 do
	local mask = 2 ^ i
	local cap, low = G["SPELL_SCHOOL" .. i .. "_CAP"], G["SPELL_SCHOOL" .. i .. "_NAME"]
	if cap then SCHOOL_BY_NAME[strlower(cap)] = mask end
	if low then SCHOOL_BY_NAME[strlower(low)] = mask end
end

local POWER_BY_NAME = {}
local POWER_NAMES = {MANA = 0, RAGE = 1, FOCUS = 2, ENERGY = 3, HAPPINESS = 4}
for global, power in pairs(POWER_NAMES) do
	local s = G[global]
	if type(s) == "string" then POWER_BY_NAME[strlower(s)] = power end
	POWER_BY_NAME[strlower(global)] = power
end

-- damage shields by school: a known shield the target has, else the usual one of the school
local DAMAGE_SHIELD_SPELLS = {
	[1] = "Thorns", [2] = "Retribution Aura", [4] = "Fire Shield", [8] = "Thorns", [16] = "Frost Armor",
	[32] = "Shadow Shield", [64] = "Arcane Shield"
}

-------------------------------------------------------------------------------
-- message formats -> patterns

-- spec: global string, event, the fields of its arguments in order, options:
--   src / dst = "you" (the player) or "dst" (the target itself), crit, miss, aura, env, ignore
local Y = {src = "you"}
local YD = {dst = "you"}
local YY = {src = "you", dst = "you"}
local function opt(base, extra)
	local t = {}
	for k, v in pairs(base or {}) do t[k] = v end
	for k, v in pairs(extra) do t[k] = v end
	return t
end
local CRIT = {crit = true}

local SPECS = {
	-- melee hits (CHAT_MSG_COMBAT_*_HITS)
	{"hits", "COMBATHITSELFOTHER", "SWING_DAMAGE", {"dst", "amount"}, Y},
	{"hits", "COMBATHITCRITSELFOTHER", "SWING_DAMAGE", {"dst", "amount"}, opt(Y, CRIT)},
	{"hits", "COMBATHITSCHOOLSELFOTHER", "SWING_DAMAGE", {"dst", "amount", "school"}, Y},
	{"hits", "COMBATHITCRITSCHOOLSELFOTHER", "SWING_DAMAGE", {"dst", "amount", "school"}, opt(Y, CRIT)},
	{"hits", "COMBATHITOTHERSELF", "SWING_DAMAGE", {"src", "amount"}, YD},
	{"hits", "COMBATHITCRITOTHERSELF", "SWING_DAMAGE", {"src", "amount"}, opt(YD, CRIT)},
	{"hits", "COMBATHITSCHOOLOTHERSELF", "SWING_DAMAGE", {"src", "amount", "school"}, YD},
	{"hits", "COMBATHITCRITSCHOOLOTHERSELF", "SWING_DAMAGE", {"src", "amount", "school"}, opt(YD, CRIT)},
	{"hits", "COMBATHITOTHEROTHER", "SWING_DAMAGE", {"src", "dst", "amount"}},
	{"hits", "COMBATHITCRITOTHEROTHER", "SWING_DAMAGE", {"src", "dst", "amount"}, CRIT},
	{"hits", "COMBATHITSCHOOLOTHEROTHER", "SWING_DAMAGE", {"src", "dst", "amount", "school"}},
	{"hits", "COMBATHITCRITSCHOOLOTHEROTHER", "SWING_DAMAGE", {"src", "dst", "amount", "school"}, CRIT},
	{"hits", "IMMUNESELFOTHER", "SWING_MISSED", {"dst"}, opt(Y, {miss = "IMMUNE"})},
	{"hits", "IMMUNEOTHERSELF", "SWING_MISSED", {"src"}, opt(YD, {miss = "IMMUNE"})},
	{"hits", "IMMUNEOTHEROTHER", "SWING_MISSED", {"src", "dst"}, {miss = "IMMUNE"}},
	{"hits", "IMMUNESELFSELF", "SWING_MISSED", {}, opt(YY, {miss = "IMMUNE"})},
	{"hits", "VSENVIRONMENTALDAMAGE_FALLING_SELF", "ENVIRONMENTAL_DAMAGE", {"amount"}, opt(YD, {env = "FALLING"})},
	{"hits", "VSENVIRONMENTALDAMAGE_FALLING_OTHER", "ENVIRONMENTAL_DAMAGE", {"dst", "amount"}, {env = "FALLING"}},
	{"hits", "VSENVIRONMENTALDAMAGE_DROWNING_SELF", "ENVIRONMENTAL_DAMAGE", {"amount"}, opt(YD, {env = "DROWNING"})},
	{"hits", "VSENVIRONMENTALDAMAGE_DROWNING_OTHER", "ENVIRONMENTAL_DAMAGE", {"dst", "amount"}, {env = "DROWNING"}},
	{"hits", "VSENVIRONMENTALDAMAGE_FATIGUE_SELF", "ENVIRONMENTAL_DAMAGE", {"amount"}, opt(YD, {env = "FATIGUE"})},
	{"hits", "VSENVIRONMENTALDAMAGE_FATIGUE_OTHER", "ENVIRONMENTAL_DAMAGE", {"dst", "amount"}, {env = "FATIGUE"}},
	{"hits", "VSENVIRONMENTALDAMAGE_FIRE_SELF", "ENVIRONMENTAL_DAMAGE", {"amount"}, opt(YD, {env = "FIRE"})},
	{"hits", "VSENVIRONMENTALDAMAGE_FIRE_OTHER", "ENVIRONMENTAL_DAMAGE", {"dst", "amount"}, {env = "FIRE"}},
	{"hits", "VSENVIRONMENTALDAMAGE_LAVA_SELF", "ENVIRONMENTAL_DAMAGE", {"amount"}, opt(YD, {env = "LAVA"})},
	{"hits", "VSENVIRONMENTALDAMAGE_LAVA_OTHER", "ENVIRONMENTAL_DAMAGE", {"dst", "amount"}, {env = "LAVA"}},
	{"hits", "VSENVIRONMENTALDAMAGE_SLIME_SELF", "ENVIRONMENTAL_DAMAGE", {"amount"}, opt(YD, {env = "SLIME"})},
	{"hits", "VSENVIRONMENTALDAMAGE_SLIME_OTHER", "ENVIRONMENTAL_DAMAGE", {"dst", "amount"}, {env = "SLIME"}},

	-- melee misses (CHAT_MSG_COMBAT_*_MISSES)
	{"misses", "MISSEDSELFOTHER", "SWING_MISSED", {"dst"}, opt(Y, {miss = "MISS"})},
	{"misses", "MISSEDOTHERSELF", "SWING_MISSED", {"src"}, opt(YD, {miss = "MISS"})},
	{"misses", "MISSEDOTHEROTHER", "SWING_MISSED", {"src", "dst"}, {miss = "MISS"}},

	-- deaths (CHAT_MSG_COMBAT_*_DEATH)
	{"death", "UNITDIESSELF", "UNIT_DIED", {}, YD},
	{"death", "UNITDIESOTHER", "UNIT_DIED", {"dst"}},
	{"death", "UNITDESTROYEDOTHER", "UNIT_DESTROYED", {"dst"}},
	{"death", "SELFKILLOTHER", "PARTY_KILL", {"dst"}, Y},
	{"death", "PARTYKILLOTHER", "PARTY_KILL", {"dst", "src"}},

	-- spell damage
	{"spell", "SPELLLOGSELFOTHER", "SPELL_DAMAGE", {"spell", "dst", "amount"}, Y},
	{"spell", "SPELLLOGCRITSELFOTHER", "SPELL_DAMAGE", {"spell", "dst", "amount"}, opt(Y, CRIT)},
	{"spell", "SPELLLOGSCHOOLSELFOTHER", "SPELL_DAMAGE", {"spell", "dst", "amount", "school"}, Y},
	{"spell", "SPELLLOGCRITSCHOOLSELFOTHER", "SPELL_DAMAGE", {"spell", "dst", "amount", "school"}, opt(Y, CRIT)},
	{"spell", "SPELLLOGSELFSELF", "SPELL_DAMAGE", {"spell", "amount"}, YY},
	{"spell", "SPELLLOGCRITSELFSELF", "SPELL_DAMAGE", {"spell", "amount"}, opt(YY, CRIT)},
	{"spell", "SPELLLOGSCHOOLSELFSELF", "SPELL_DAMAGE", {"spell", "amount", "school"}, YY},
	{"spell", "SPELLLOGCRITSCHOOLSELFSELF", "SPELL_DAMAGE", {"spell", "amount", "school"}, opt(YY, CRIT)},
	{"spell", "SPELLLOGOTHERSELF", "SPELL_DAMAGE", {"src", "spell", "amount"}, YD},
	{"spell", "SPELLLOGCRITOTHERSELF", "SPELL_DAMAGE", {"src", "spell", "amount"}, opt(YD, CRIT)},
	{"spell", "SPELLLOGSCHOOLOTHERSELF", "SPELL_DAMAGE", {"src", "spell", "amount", "school"}, YD},
	{"spell", "SPELLLOGCRITSCHOOLOTHERSELF", "SPELL_DAMAGE", {"src", "spell", "amount", "school"}, opt(YD, CRIT)},
	{"spell", "SPELLLOGOTHEROTHER", "SPELL_DAMAGE", {"src", "spell", "dst", "amount"}},
	{"spell", "SPELLLOGCRITOTHEROTHER", "SPELL_DAMAGE", {"src", "spell", "dst", "amount"}, CRIT},
	{"spell", "SPELLLOGSCHOOLOTHEROTHER", "SPELL_DAMAGE", {"src", "spell", "dst", "amount", "school"}},
	{"spell", "SPELLLOGCRITSCHOOLOTHEROTHER", "SPELL_DAMAGE", {"src", "spell", "dst", "amount", "school"}, CRIT},
	{"spell", "PERIODICAURADAMAGESELFSELF", "SPELL_PERIODIC_DAMAGE", {"amount", "school", "spell"}, YY},
	{"spell", "PERIODICAURADAMAGESELFOTHER", "SPELL_PERIODIC_DAMAGE", {"dst", "amount", "school", "spell"}, Y},
	{"spell", "PERIODICAURADAMAGEOTHERSELF", "SPELL_PERIODIC_DAMAGE", {"amount", "school", "src", "spell"}, YD},
	{"spell", "PERIODICAURADAMAGEOTHEROTHER", "SPELL_PERIODIC_DAMAGE", {"dst", "amount", "school", "src", "spell"}},
	{"spell", "DAMAGESHIELDSELFOTHER", "DAMAGE_SHIELD", {"amount", "school", "dst"}, Y},
	{"spell", "DAMAGESHIELDOTHERSELF", "DAMAGE_SHIELD", {"src", "amount", "school"}, YD},
	{"spell", "DAMAGESHIELDOTHEROTHER", "DAMAGE_SHIELD", {"src", "amount", "school", "dst"}},
	{"spell", "INSTAKILLSELF", "SPELL_INSTAKILL", {"spell"}, YD},
	{"spell", "INSTAKILLOTHER", "SPELL_INSTAKILL", {"dst", "spell"}},

	-- heals and power
	{"spell", "HEALEDSELFSELF", "SPELL_HEAL", {"spell", "amount"}, YY},
	{"spell", "HEALEDCRITSELFSELF", "SPELL_HEAL", {"spell", "amount"}, opt(YY, CRIT)},
	{"spell", "HEALEDSELFOTHER", "SPELL_HEAL", {"spell", "dst", "amount"}, Y},
	{"spell", "HEALEDCRITSELFOTHER", "SPELL_HEAL", {"spell", "dst", "amount"}, opt(Y, CRIT)},
	{"spell", "HEALEDOTHERSELF", "SPELL_HEAL", {"src", "spell", "amount"}, YD},
	{"spell", "HEALEDCRITOTHERSELF", "SPELL_HEAL", {"src", "spell", "amount"}, opt(YD, CRIT)},
	{"spell", "HEALEDOTHEROTHER", "SPELL_HEAL", {"src", "spell", "dst", "amount"}},
	{"spell", "HEALEDCRITOTHEROTHER", "SPELL_HEAL", {"src", "spell", "dst", "amount"}, CRIT},
	{"spell", "PERIODICAURAHEALSELFSELF", "SPELL_PERIODIC_HEAL", {"amount", "spell"}, YY},
	{"spell", "PERIODICAURAHEALSELFOTHER", "SPELL_PERIODIC_HEAL", {"dst", "amount", "spell"}, Y},
	{"spell", "PERIODICAURAHEALOTHERSELF", "SPELL_PERIODIC_HEAL", {"amount", "src", "spell"}, YD},
	{"spell", "PERIODICAURAHEALOTHEROTHER", "SPELL_PERIODIC_HEAL", {"dst", "amount", "src", "spell"}},
	{"spell", "POWERGAINSELFSELF", "SPELL_PERIODIC_ENERGIZE", {"amount", "power", "spell"}, YY},
	{"spell", "POWERGAINSELFOTHER", "SPELL_PERIODIC_ENERGIZE", {"dst", "amount", "power", "spell"}, {src = "dst"}},
	{"spell", "POWERGAINOTHERSELF", "SPELL_PERIODIC_ENERGIZE", {"amount", "power", "src", "spell"}, YD},
	{"spell", "POWERGAINOTHEROTHER", "SPELL_PERIODIC_ENERGIZE", {"dst", "amount", "power", "src", "spell"}},

	-- auras
	{"spell", "AURAADDEDSELFHELPFUL", "SPELL_AURA_APPLIED", {"spell"}, opt(YD, {aura = "BUFF"})},
	{"spell", "AURAADDEDOTHERHELPFUL", "SPELL_AURA_APPLIED", {"dst", "spell"}, {aura = "BUFF"}},
	{"spell", "AURAADDEDSELFHARMFUL", "SPELL_AURA_APPLIED", {"spell"}, opt(YD, {aura = "DEBUFF"})},
	{"spell", "AURAADDEDOTHERHARMFUL", "SPELL_AURA_APPLIED", {"dst", "spell"}, {aura = "DEBUFF"}},
	{"spell", "AURAAPPLICATIONADDEDSELFHELPFUL", "SPELL_AURA_APPLIED_DOSE", {"spell", "amount"}, opt(YD, {aura = "BUFF"})},
	{"spell", "AURAAPPLICATIONADDEDOTHERHELPFUL", "SPELL_AURA_APPLIED_DOSE", {"dst", "spell", "amount"}, {aura = "BUFF"}},
	{"spell", "AURAAPPLICATIONADDEDSELFHARMFUL", "SPELL_AURA_APPLIED_DOSE", {"spell", "amount"}, opt(YD, {aura = "DEBUFF"})},
	{"spell", "AURAAPPLICATIONADDEDOTHERHARMFUL", "SPELL_AURA_APPLIED_DOSE", {"dst", "spell", "amount"}, {aura = "DEBUFF"}},
	{"spell", "AURAREMOVEDSELF", "SPELL_AURA_REMOVED", {"spell"}, YD},
	{"spell", "AURAREMOVEDOTHER", "SPELL_AURA_REMOVED", {"spell", "dst"}},
	{"spell", "AURADISPELSELF", "SPELL_AURA_REMOVED", {"spell"}, YD},
	{"spell", "AURADISPELOTHER", "SPELL_AURA_REMOVED", {"dst", "spell"}},

	-- casts
	{"spell", "SPELLCASTGOSELF", "SPELL_CAST_SUCCESS", {"spell"}, Y},
	{"spell", "SPELLCASTGOSELFTARGETTED", "SPELL_CAST_SUCCESS", {"spell", "dst"}, Y},
	{"spell", "SPELLCASTGOOTHER", "SPELL_CAST_SUCCESS", {"src", "spell"}},
	{"spell", "SPELLCASTGOOTHERTARGETTED", "SPELL_CAST_SUCCESS", {"src", "spell", "dst"}},
	{"spell", "SIMPLECASTOTHERSELF", "SPELL_CAST_SUCCESS", {"src", "spell"}, YD},
	{"spell", "SPELLPERFORMGOSELF", "SPELL_CAST_SUCCESS", {"spell"}, Y},
	{"spell", "SPELLPERFORMGOSELFTARGETTED", "SPELL_CAST_SUCCESS", {"spell", "dst"}, Y},
	{"spell", "SPELLPERFORMGOOTHER", "SPELL_CAST_SUCCESS", {"src", "spell"}},
	{"spell", "SPELLPERFORMGOOTHERTARGETTED", "SPELL_CAST_SUCCESS", {"src", "spell", "dst"}},
	{"spell", "SIMPLEPERFORMOTHERSELF", "SPELL_CAST_SUCCESS", {"src", "spell"}, YD},
	{"spell", "SPELLCASTSELFSTART", "SPELL_CAST_START", {"spell"}, Y},
	{"spell", "SPELLCASTOTHERSTART", "SPELL_CAST_START", {"src", "spell"}},
	{"spell", "SPELLPERFORMSELFSTART", "SPELL_CAST_START", {"spell"}, Y},
	{"spell", "SPELLPERFORMOTHERSTART", "SPELL_CAST_START", {"src", "spell"}},
	{"spell", "SPELLFAILCASTSELF", "SPELL_CAST_FAILED", {"spell", "reason"}, Y},
	{"spell", "SPELLFAILCASTOTHER", "SPELL_CAST_FAILED", {"src", "spell", "reason"}},
	{"spell", "SPELLFAILPERFORMSELF", "SPELL_CAST_FAILED", {"spell", "reason"}, Y},
	{"spell", "SPELLFAILPERFORMOTHER", "SPELL_CAST_FAILED", {"src", "spell", "reason"}},
	{"spell", "SPELLINTERRUPTSELFOTHER", "SPELL_INTERRUPT", {"dst", "extra"}, Y},
	{"spell", "SPELLINTERRUPTOTHERSELF", "SPELL_INTERRUPT", {"src", "extra"}, YD},
	{"spell", "SPELLINTERRUPTOTHEROTHER", "SPELL_INTERRUPT", {"src", "dst", "extra"}},
	{"spell", "SPELLEXTRAATTACKSSELF", "SPELL_EXTRA_ATTACKS", {"amount", "spell"}, YY},
	{"spell", "SPELLEXTRAATTACKSSELF_SINGULAR", "SPELL_EXTRA_ATTACKS", {"amount", "spell"}, YY},
	{"spell", "SPELLEXTRAATTACKSOTHER", "SPELL_EXTRA_ATTACKS", {"src", "amount", "spell"}, {dst = "src"}},
	{"spell", "SPELLEXTRAATTACKSOTHER_SINGULAR", "SPELL_EXTRA_ATTACKS", {"src", "amount", "spell"}, {dst = "src"}},

	-- spell misses
	{"spell", "SPELLMISSSELFOTHER", "SPELL_MISSED", {"spell", "dst"}, opt(Y, {miss = "MISS"})},
	{"spell", "SPELLMISSSELFSELF", "SPELL_MISSED", {"spell"}, opt(YY, {miss = "MISS"})},
	{"spell", "SPELLMISSOTHERSELF", "SPELL_MISSED", {"src", "spell"}, opt(YD, {miss = "MISS"})},
	{"spell", "SPELLMISSOTHEROTHER", "SPELL_MISSED", {"src", "spell", "dst"}, {miss = "MISS"}},
	{"spell", "SPELLLOGABSORBSELFOTHER", "SPELL_MISSED", {"spell", "dst"}, opt(Y, {miss = "ABSORB"})},
	{"spell", "SPELLLOGABSORBSELFSELF", "SPELL_MISSED", {"spell"}, opt(YY, {miss = "ABSORB"})},
	{"spell", "SPELLLOGABSORBOTHERSELF", "SPELL_MISSED", {"src", "spell"}, opt(YD, {miss = "ABSORB"})},
	{"spell", "SPELLLOGABSORBOTHEROTHER", "SPELL_MISSED", {"src", "spell", "dst"}, {miss = "ABSORB"}},
	{"spell", "IMMUNESPELLSELFOTHER", "SPELL_MISSED", {"dst", "spell"}, opt(Y, {miss = "IMMUNE"})},
	{"spell", "IMMUNESPELLSELFSELF", "SPELL_MISSED", {"spell"}, opt(YY, {miss = "IMMUNE"})},
	{"spell", "IMMUNESPELLOTHERSELF", "SPELL_MISSED", {"src", "spell"}, opt(YD, {miss = "IMMUNE"})},
	{"spell", "IMMUNESPELLOTHEROTHER", "SPELL_MISSED", {"dst", "src", "spell"}, {miss = "IMMUNE"}},
	{"spell", "IMMUNEDAMAGECLASSSELFOTHER", "SWING_MISSED", {"dst", "school"}, opt(Y, {miss = "IMMUNE"})},
	{"spell", "IMMUNEDAMAGECLASSOTHERSELF", "SWING_MISSED", {"src", "school"}, opt(YD, {miss = "IMMUNE"})},
	{"spell", "IMMUNEDAMAGECLASSOTHEROTHER", "SWING_MISSED", {"dst", "src", "school"}, {miss = "IMMUNE"}},

	-- known formats Skada does not use (listed so their messages match no other format)
	{"spell", "AURACHANGEDSELF", nil, {"spell", "extra"}, {ignore = true}},
	{"spell", "AURACHANGEDOTHER", nil, {"dst", "spell", "extra"}, {ignore = true}},
	{"spell", "AURASTOLENSELFOTHER", nil, {"dst", "spell"}, {ignore = true}},
	{"spell", "AURASTOLENOTHERSELF", nil, {"src", "spell"}, {ignore = true}},
	{"spell", "AURASTOLENOTHEROTHER", nil, {"src", "dst", "spell"}, {ignore = true}},
	{"spell", "DISPELFAILEDSELFOTHER", nil, {"dst", "spell"}, {ignore = true}},
	{"spell", "DISPELFAILEDOTHERSELF", nil, {"src", "spell"}, {ignore = true}},
	{"spell", "DISPELFAILEDOTHEROTHER", nil, {"src", "dst", "spell"}, {ignore = true}},
	{"spell", "ITEMENCHANTMENTADDSELFSELF", nil, {"spell", "item"}, {ignore = true}},
	{"spell", "ITEMENCHANTMENTADDSELFOTHER", nil, {"spell", "dst", "item"}, {ignore = true}},
	{"spell", "ITEMENCHANTMENTADDOTHERSELF", nil, {"src", "spell", "item"}, {ignore = true}},
	{"spell", "ITEMENCHANTMENTADDOTHEROTHER", nil, {"src", "spell", "dst", "item"}, {ignore = true}},
	{"spell", "ITEMENCHANTMENTREMOVESELF", nil, {"spell", "item"}, {ignore = true}},
	{"spell", "ITEMENCHANTMENTREMOVEOTHER", nil, {"spell", "dst", "item"}, {ignore = true}},
	{"spell", "SPELLDURABILITYDAMAGESELFOTHER", nil, {"spell", "dst", "item"}, {ignore = true}},
	{"spell", "SPELLDURABILITYDAMAGEOTHERSELF", nil, {"src", "spell", "item"}, {ignore = true}},
	{"spell", "SPELLDURABILITYDAMAGEOTHEROTHER", nil, {"src", "spell", "dst", "item"}, {ignore = true}},
	{"spell", "SPELLDURABILITYDAMAGEALLSELFOTHER", nil, {"spell", "dst"}, {ignore = true}},
	{"spell", "SPELLDURABILITYDAMAGEALLOTHERSELF", nil, {"src", "spell"}, {ignore = true}},
	{"spell", "SPELLDURABILITYDAMAGEALLOTHEROTHER", nil, {"src", "spell", "dst"}, {ignore = true}},
	{"spell", "SPELLPOWERDRAINSELFOTHER", nil, {"spell", "amount", "power", "dst"}, {ignore = true}},
	{"spell", "SPELLPOWERDRAINSELFSELF", nil, {"spell", "amount", "power"}, {ignore = true}},
	{"spell", "SPELLPOWERDRAINOTHERSELF", nil, {"src", "spell", "amount", "power"}, {ignore = true}},
	{"spell", "SPELLPOWERDRAINOTHEROTHER", nil, {"src", "spell", "amount", "power", "dst"}, {ignore = true}},
	{"spell", "SPELLPOWERLEECHSELFOTHER", nil, {"spell", "amount", "power", "dst", "amount2", "power2"}, {ignore = true}},
	{"spell", "SPELLPOWERLEECHOTHERSELF", nil, {"src", "spell", "amount", "power", "src2", "amount2", "power2"}, {ignore = true}},
	{"spell", "SPELLPOWERLEECHOTHEROTHER", nil, {"src", "spell", "amount", "power", "dst", "src2", "amount2", "power2"}, {ignore = true}},
	{"spell", "SPELLHAPPINESSDRAINSELF", nil, {"spell", "amount"}, {ignore = true}},
	{"spell", "SPELLHAPPINESSDRAINOTHER", nil, {"src", "spell", "amount"}, {ignore = true}},
	{"spell", "SPELLDISMISSPETSELF", nil, {"spell"}, {ignore = true}},
	{"spell", "SPELLDISMISSPETOTHER", nil, {"src", "spell"}, {ignore = true}},
	{"spell", "SPELLTEACHSELFSELF", nil, {"spell"}, {ignore = true}},
	{"spell", "SPELLTEACHSELFOTHER", nil, {"dst", "spell"}, {ignore = true}},
	{"spell", "SPELLTEACHOTHERSELF", nil, {"src", "spell"}, {ignore = true}},
	{"spell", "SPELLTEACHOTHEROTHER", nil, {"src", "dst", "spell"}, {ignore = true}},
}

-- the 1.12 melee miss formats ("You attack. %s dodges." ...) and spell miss formats
local MELEE_MISSES = {DODGE = "DODGE", PARRY = "PARRY", BLOCK = "BLOCK", EVADE = "EVADE", DEFLECT = "DEFLECT", IMMUNE = "IMMUNE", ABSORB = "ABSORB", RESIST = "RESIST"}
for key, miss in pairs(MELEE_MISSES) do
	tinsert(SPECS, {"misses", "VS" .. key .. "SELFOTHER", "SWING_MISSED", {"dst"}, opt(Y, {miss = miss})})
	tinsert(SPECS, {"misses", "VS" .. key .. "OTHERSELF", "SWING_MISSED", {"src"}, opt(YD, {miss = miss})})
	tinsert(SPECS, {"misses", "VS" .. key .. "OTHEROTHER", "SWING_MISSED", {"src", "dst"}, {miss = miss}})
end
local SPELL_MISSES = {RESIST = "RESIST", DODGED = "DODGE", PARRIED = "PARRY", BLOCKED = "BLOCK", EVADED = "EVADE", DEFLECTED = "DEFLECT", REFLECT = "REFLECT", IMMUNE = "IMMUNE"}
for key, miss in pairs(SPELL_MISSES) do
	tinsert(SPECS, {"spell", "SPELL" .. key .. "SELFOTHER", "SPELL_MISSED", {"spell", "dst"}, opt(Y, {miss = miss})})
	tinsert(SPECS, {"spell", "SPELL" .. key .. "SELFSELF", "SPELL_MISSED", {"spell"}, opt(YY, {miss = miss})})
	tinsert(SPECS, {"spell", "SPELL" .. key .. "OTHERSELF", "SPELL_MISSED", {"src", "spell"}, opt(YD, {miss = miss})})
	tinsert(SPECS, {"spell", "SPELL" .. key .. "OTHEROTHER", "SPELL_MISSED", {"src", "spell", "dst"}, {miss = miss}})
end

local MAGIC = "([%^%$%(%)%%%.%[%]%*%+%-%?])"

-- a format ("%s hits %s for %d.", "%2$s ...") as an anchored pattern, the argument index of each
-- capture, the number of literal characters and the longest literal run (a quick plain-text check)
local function compile(fmt)
	local pattern, order, literal = "^", {}, 0
	local run, longest = "", ""
	local i, n, argi = 1, strlen(fmt), 0
	while i <= n do
		local c = strsub(fmt, i, i)
		local st, en, pos, conv = strfind(fmt, "^%%(%d?)%$?([sd])", i)
		if st then
			argi = argi + 1
			order[getn(order) + 1] = pos ~= "" and tonumber(pos) or argi
			pattern = pattern .. (conv == "d" and "(%d+)" or "(.+)")
			if strlen(run) > strlen(longest) then longest = run end
			run = ""
			i = en + 1
		else
			if c == "%" and strsub(fmt, i + 1, i + 1) == "%" then i = i + 1 end
			pattern = pattern .. strgsub(c, MAGIC, "%%%1")
			run = run .. c
			literal = literal + 1
			i = i + 1
		end
	end
	if strlen(run) > strlen(longest) then longest = run end
	return pattern .. "$", order, literal, longest
end

local FAMILIES = {hits = {}, misses = {}, death = {}, spell = {}}

local function build()
	local done = {}
	for i = 1, getn(SPECS) do
		local family, key, event, fields, o = SPECS[i][1], SPECS[i][2], SPECS[i][3], SPECS[i][4], SPECS[i][5] or {}
		local fmt = G[key]
		if type(fmt) == "string" and not done[family .. fmt] then
			done[family .. fmt] = true
			local pattern, order, literal, longest = compile(fmt)
			local spec = {key = key, event = event, pattern = pattern, literal = literal, longest = longest, o = o, field = {}}
			-- the field of each capture, by the argument index the format names
			for c = 1, getn(order) do
				spec.field[c] = fields[order[c]]
			end
			tinsert(FAMILIES[family], spec)
		end
	end
	-- the most literal text first: "%s's %s hits %s for %d." before "%s hits %s for %d."
	for _, list in pairs(FAMILIES) do
		table.sort(list, function(a, b)
			if a.literal ~= b.literal then return a.literal > b.literal end
			return getn(a.field) < getn(b.field)
		end)
	end
end

-- the trailers 1.12 appends to damage messages
local TRAILERS = {}
local function add_trailer(key, field)
	local fmt = G[key]
	if type(fmt) ~= "string" then return end
	local pattern = compile(fmt)
	-- anchored at the end, not the start
	tinsert(TRAILERS, {pattern = strsub(pattern, 2), field = field})
end
add_trailer("ABSORB_TRAILER", "absorbed")
add_trailer("BLOCK_TRAILER", "blocked")
add_trailer("RESIST_TRAILER", "resisted")
add_trailer("GLANCING_TRAILER", "glancing")
add_trailer("CRUSHING_TRAILER", "crushing")
add_trailer("VULNERABLE_TRAILER", "vulnerable")

-- which family each chat event carries
local EVENT_FAMILY = {}
local function family_of(event)
	if strfind(event, "^CHAT_MSG_COMBAT_.*_HITS$") then return "hits" end
	if strfind(event, "^CHAT_MSG_COMBAT_.*_MISSES$") then return "misses" end
	if strfind(event, "^CHAT_MSG_COMBAT_.*_DEATH$") then return "death" end
	if strfind(event, "^CHAT_MSG_SPELL_") then return "spell" end
end
local CHAT_EVENTS = {
	"CHAT_MSG_COMBAT_SELF_HITS", "CHAT_MSG_COMBAT_SELF_MISSES", "CHAT_MSG_COMBAT_PET_HITS", "CHAT_MSG_COMBAT_PET_MISSES",
	"CHAT_MSG_COMBAT_PARTY_HITS", "CHAT_MSG_COMBAT_PARTY_MISSES", "CHAT_MSG_COMBAT_FRIENDLYPLAYER_HITS",
	"CHAT_MSG_COMBAT_FRIENDLYPLAYER_MISSES", "CHAT_MSG_COMBAT_HOSTILEPLAYER_HITS", "CHAT_MSG_COMBAT_HOSTILEPLAYER_MISSES",
	"CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS", "CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES",
	"CHAT_MSG_COMBAT_CREATURE_VS_PARTY_HITS", "CHAT_MSG_COMBAT_CREATURE_VS_PARTY_MISSES",
	"CHAT_MSG_COMBAT_CREATURE_VS_CREATURE_HITS", "CHAT_MSG_COMBAT_CREATURE_VS_CREATURE_MISSES",
	"CHAT_MSG_COMBAT_FRIENDLY_DEATH", "CHAT_MSG_COMBAT_HOSTILE_DEATH",
	"CHAT_MSG_SPELL_SELF_DAMAGE", "CHAT_MSG_SPELL_SELF_BUFF", "CHAT_MSG_SPELL_PET_DAMAGE", "CHAT_MSG_SPELL_PET_BUFF",
	"CHAT_MSG_SPELL_PARTY_DAMAGE", "CHAT_MSG_SPELL_PARTY_BUFF", "CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE",
	"CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF", "CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE", "CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF",
	"CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE", "CHAT_MSG_SPELL_CREATURE_VS_SELF_BUFF",
	"CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE", "CHAT_MSG_SPELL_CREATURE_VS_PARTY_BUFF",
	"CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE", "CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF",
	"CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF", "CHAT_MSG_SPELL_DAMAGESHIELDS_ON_OTHERS",
	"CHAT_MSG_SPELL_AURA_GONE_SELF", "CHAT_MSG_SPELL_AURA_GONE_PARTY", "CHAT_MSG_SPELL_AURA_GONE_OTHER",
	"CHAT_MSG_SPELL_BREAK_AURA", "CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS",
	"CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "CHAT_MSG_SPELL_PERIODIC_PARTY_BUFFS",
	"CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS",
	"CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE", "CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS",
	"CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE", "CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS"
}
for i = 1, getn(CHAT_EVENTS) do
	EVENT_FAMILY[CHAT_EVENTS[i]] = family_of(CHAT_EVENTS[i])
end

-------------------------------------------------------------------------------
-- matching

local captured = {} -- field -> captured text, reused
local trailer = {} -- absorbed / blocked / resisted / glancing / crushing, reused

-- "Bob's Elune's Grace": a "src's spell" split is wrong when the whole text is a spell name and the
-- source is no unit known
local function bad_split(src, spell)
	if not src or roster[src] or seen[src] then return false end
	local whole = src .. "'s " .. spell
	return SkadaSpellKnown(whole)
end

local function match_spec(spec, msg)
	if spec.longest ~= "" and not strfind(msg, spec.longest, 1, true) then return false end
	local r = {strfind(msg, spec.pattern)}
	if not r[1] then return false end
	for k in pairs(captured) do captured[k] = nil end
	for c = 1, getn(spec.field) do
		local field = spec.field[c]
		if field then captured[field] = r[c + 2] end
	end
	if captured.src and captured.spell and bad_split(captured.src, captured.spell) then return false end
	return true
end

local lastCast = {} -- source name -> {time, spell}: the interrupting spell
local INTERRUPT_WINDOW = 1
local auraTypes = {} -- [dst name][spell] = "BUFF" / "DEBUFF", for SPELL_AURA_REMOVED
local lastDeath = {} -- name -> time, one UNIT_DIED per death
local DEATH_WINDOW = 1
local timeOffset = time() - GetTime()

local function spell_args(name)
	local id = SkadaSpellId(name)
	return id, name, SkadaSpellSchool(id)
end

local function fire(event, srcName, dstName, ...)
	local srcGUID, srcFlags = unit_info(srcName)
	local dstGUID, dstFlags = unit_info(dstName)
	local ts = timeOffset + GetTime()
	CombatLog.skada:ParseCombatLog(nil, ts, event, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, unpack(arg))
end

local function handle(spec)
	local o = spec.o
	if o.ignore then return end
	local event = spec.event
	local c = captured
	local srcName = (o.src == "you") and playerName or c.src
	local dstName = (o.dst == "you") and playerName or c.dst
	if o.src == "dst" then srcName = dstName end
	if o.dst == "src" then dstName = srcName end
	local amount = c.amount and tonumber(c.amount)
	local school = c.school and SCHOOL_BY_NAME[strlower(c.school)]
	local crit = o.crit and 1 or nil

	if event == "SWING_DAMAGE" then
		fire(event, srcName, dstName, amount, school or 1, trailer.resisted, trailer.blocked, trailer.absorbed, crit, trailer.glancing, trailer.crushing)
	elseif event == "SWING_MISSED" then
		fire(event, srcName, dstName, o.miss)
	elseif event == "ENVIRONMENTAL_DAMAGE" then
		fire(event, nil, dstName, o.env, amount, school or 1, trailer.resisted, trailer.blocked, trailer.absorbed, nil, nil, nil)
	elseif event == "SPELL_DAMAGE" or event == "SPELL_PERIODIC_DAMAGE" then
		local id, name, spellSchool = spell_args(c.spell)
		if srcName then lastCast[srcName] = {GetTime(), c.spell} end
		fire(event, srcName, dstName, id, name, school or spellSchool, amount, school or spellSchool, trailer.resisted, trailer.blocked, trailer.absorbed, crit, trailer.glancing, trailer.crushing)
	elseif event == "DAMAGE_SHIELD" then
		local id, name = spell_args(DAMAGE_SHIELD_SPELLS[school or 1] or DAMAGE_SHIELD_SPELLS[1])
		fire(event, srcName, dstName, id, name, school or 1, amount, school or 1, trailer.resisted, trailer.blocked, trailer.absorbed, nil, nil, nil)
	elseif event == "SPELL_MISSED" then
		local id, name, spellSchool = spell_args(c.spell)
		if srcName then lastCast[srcName] = {GetTime(), c.spell} end
		fire(event, srcName, dstName, id, name, spellSchool, o.miss)
	elseif event == "SPELL_HEAL" or event == "SPELL_PERIODIC_HEAL" then
		local id, name, spellSchool = spell_args(c.spell)
		fire(event, srcName, dstName, id, name, spellSchool, amount, crit)
	elseif event == "SPELL_PERIODIC_ENERGIZE" then
		local id, name, spellSchool = spell_args(c.spell)
		fire(event, srcName, dstName, id, name, spellSchool, amount, POWER_BY_NAME[strlower(c.power or "")] or 0)
	elseif event == "SPELL_AURA_APPLIED" or event == "SPELL_AURA_APPLIED_DOSE" or event == "SPELL_AURA_REMOVED" then
		local id, name, spellSchool = spell_args(c.spell)
		local types = auraTypes[dstName or ""]
		local auraType = o.aura
		if auraType then
			if not types then
				types = {}
				auraTypes[dstName or ""] = types
			end
			types[c.spell] = auraType
		else
			auraType = types and types[c.spell] or "BUFF"
			if types then types[c.spell] = nil end
		end
		fire(event, nil, dstName, id, name, spellSchool, auraType, amount)
	elseif event == "SPELL_CAST_SUCCESS" or event == "SPELL_CAST_START" or event == "SPELL_CAST_FAILED" then
		local id, name, spellSchool = spell_args(c.spell)
		if event == "SPELL_CAST_SUCCESS" then
			if srcName then lastCast[srcName] = {GetTime(), c.spell} end
			-- totems: the caster owns the unit of that name from now on
			if strfind(c.spell, "Totem") and srcName and roster[srcName] then
				local totem = strgsub(c.spell, "%s+[IVX]+$", "")
				summons[totem] = srcName
				fire("SPELL_SUMMON", srcName, totem, id, name, spellSchool)
			end
		end
		fire(event, srcName, dstName, id, name, spellSchool, c.reason)
	elseif event == "SPELL_INTERRUPT" then
		local last = srcName and lastCast[srcName]
		local used = (last and GetTime() - last[1] <= INTERRUPT_WINDOW) and last[2] or G.INTERRUPT or "Interrupt"
		local id, name, spellSchool = spell_args(used)
		local xid, xname, xschool = spell_args(c.extra)
		fire(event, srcName, dstName, id, name, spellSchool, xid, xname, xschool)
	elseif event == "SPELL_EXTRA_ATTACKS" then
		local id, name, spellSchool = spell_args(c.spell)
		fire(event, srcName, dstName, id, name, spellSchool, amount)
	elseif event == "SPELL_INSTAKILL" then
		local id, name, spellSchool = spell_args(c.spell)
		fire(event, srcName, dstName, id, name, spellSchool)
	elseif event == "UNIT_DIED" or event == "UNIT_DESTROYED" or event == "PARTY_KILL" then
		if event == "PARTY_KILL" then
			fire(event, srcName, dstName)
			event = "UNIT_DIED"
		end
		local now = GetTime()
		if dstName and not (lastDeath[dstName] and now - lastDeath[dstName] < DEATH_WINDOW) then
			lastDeath[dstName] = now
			if auraTypes[dstName] then auraTypes[dstName] = nil end
			fire(event, nil, dstName)
		end
	end
end

-- strips the trailers off a damage message: "... for 50. (10 absorbed) (glancing)"
local function strip_trailers(msg)
	for k in pairs(trailer) do trailer[k] = nil end
	local found = true
	while found do
		found = false
		for i = 1, getn(TRAILERS) do
			local t = TRAILERS[i]
			local st, _, value = strfind(msg, t.pattern)
			if st then
				trailer[t.field] = tonumber(value) or 1
				msg = strsub(msg, 1, st - 1)
				found = true
			end
		end
	end
	return msg
end

-- what the parser saw (for checking it): messages matched / not matched, the last ones not matched
CombatLog.matched, CombatLog.missed = 0, 0
CombatLog.unmatched = {}
local UNMATCHED_KEPT = 20

function CombatLog.Parse(event, msg)
	local family = EVENT_FAMILY[event]
	if not family or not msg then return end
	local original = msg
	if family == "hits" or family == "spell" then
		msg = strip_trailers(msg)
	else
		for k in pairs(trailer) do trailer[k] = nil end
	end
	local list = FAMILIES[family]
	for i = 1, getn(list) do
		local spec = list[i]
		if match_spec(spec, msg) then
			CombatLog.matched = CombatLog.matched + 1
			handle(spec)
			return spec.key
		end
	end
	CombatLog.missed = CombatLog.missed + 1
	local kept = CombatLog.unmatched
	if getn(kept) >= UNMATCHED_KEPT then tremove(kept, 1) end
	tinsert(kept, event .. ": " .. original)
end

-------------------------------------------------------------------------------
-- start / stop (Init.lua's Private.StartWatching / StopWatching)

local frame = CreateFrame("Frame")
frame:Hide()

local ROSTER_EVENTS = {"PLAYER_ENTERING_WORLD", "PARTY_MEMBERS_CHANGED", "RAID_ROSTER_UPDATE", "UNIT_PET"}
local UNIT_EVENTS = {PLAYER_TARGET_CHANGED = "target", UPDATE_MOUSEOVER_UNIT = "mouseover"}

frame:SetScript("OnEvent", function(self, event, msg)
	if EVENT_FAMILY[event] then
		CombatLog.Parse(event, msg)
	elseif UNIT_EVENTS[event] then
		remember(UNIT_EVENTS[event])
	else
		update_roster()
	end
end)

-- 1.12 logs only what happens near the player (and no periodic spells unless asked): the widest
-- ranges, as DPSMate sets them
local LOG_CVARS = {
	CombatLogPeriodicSpells = 1, CombatLogRangeParty = 200, CombatLogRangePartyPet = 200,
	CombatLogRangeFriendlyPlayers = 200, CombatLogRangeFriendlyPlayersPets = 200,
	CombatLogRangeHostilePlayers = 200, CombatLogRangeHostilePlayersPets = 200, CombatLogRangeCreature = 200,
	CombatDeathLogRange = 200
}
local function widen_log()
	for name, value in pairs(LOG_CVARS) do
		if GetCVar(name) then
			SetCVar(name, value)
		elseif RegisterCVar then
			RegisterCVar(name, value)
		end
	end
end

function CombatLog.Start(skada)
	CombatLog.skada = skada
	widen_log()
	if not FAMILIES.spell[1] then build() end
	update_roster()
	for i = 1, getn(CHAT_EVENTS) do frame:RegisterEvent(CHAT_EVENTS[i]) end
	for i = 1, getn(ROSTER_EVENTS) do frame:RegisterEvent(ROSTER_EVENTS[i]) end
	for event in pairs(UNIT_EVENTS) do frame:RegisterEvent(event) end
end

function CombatLog.Stop()
	frame:UnregisterAllEvents()
end
