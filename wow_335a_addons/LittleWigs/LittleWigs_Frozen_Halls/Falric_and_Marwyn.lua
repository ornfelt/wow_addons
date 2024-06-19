-------------------------------------------------------------------------------
--  Module Declaration

local mod = BigWigs:NewBoss("Falric and Marwyn", "Halls of Reflection")
if not mod then return end
mod.partyContent = true
mod.otherMenu = "The Frozen Halls"
mod:RegisterEnableMob(38112, 38113)
mod.toggleOptions = {
	{72426, "ICON"}, -- Impending Despair
	{72422, "ICON"}, -- Quivering Strike
	72363, -- Corrupted Flesh
	{72368, "ICON"},-- Shared Suffering
	{72383, "ICON"}, -- Corrupted Touch
	"bosskill",
}

-------------------------------------------------------------------------------
--  Locals

local deaths = 0
local flesh = mod:NewTargetList()
local pName = UnitName("player")

-------------------------------------------------------------------------------
--  Initialization

function mod:OnBossEnable()
	deaths = 0
	self:Log("SPELL_AURA_APPLIED", "Flesh", 72363) --10s no dispell

	self:Log("SPELL_AURA_REMOVED", "Debuff", 72368, 72383, 72422, 72426)
	self:Log("SPELL_AURA_REMOVED", "Removed", 72368, 72383, 72422, 72426)
	self:Death("Win", 38113)
end

-------------------------------------------------------------------------------
--  Event Handlers

function mod:Debuff(player, spellId, _, _, spellName)
	local time = 10
	if spellId == 72426 then --Farlic Impending Despair
		time = 6
		self:SecondaryIcon(72426, player)
	elseif spellId == 72422 then -- Farlic Quivering Strike
		time = 5
		self:PrimaryIcon(72422, player)
	elseif spellId == 72368 then -- Marwyn Shared Suffering
		time=12
		self:SecondaryIcon(72368, player)
	elseif spellId == 72363 then -- Marwyn Corrupted Flesh
		self:PrimaryIcon(72363, player)
	end
	self:TargetMessage(spellId, player, spellName, "Urgent", spellId)
	self:Bar(spellId, player..": "..spellName, time, spellId)
end

do
	local handle = nil
	local id, name = nil, nil
	local warned = nil
	local function fleshWarn()
		if not warned then
			mod:Message(72363, name, "Urgent", id)
			warned = true
		else
			warned = nil
			wipe(flesh)
		end
		handle = nil
	end
	function mod:Flesh(player, spellId, _, _, spellName)
		flesh[#flesh + 1] = player
		if handle then self:CancelTimer(handle) end
		id, name = spellId, spellName
		handle = self:ScheduleTimer(fleshWarn, 0.1) -- has been 0.2 before
	end
end

function mod:Removed(player, spellId, _, _, spellName)
	self:SendMessage("BigWigs_StopBar", self, player..": "..spellName)
	self:PrimaryIcon(spellId, false)
	self:SecondaryIcon(spellId, false)
end
