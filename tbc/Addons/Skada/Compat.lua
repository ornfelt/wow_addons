-- Compat.lua - Skada on the TBC 2.4.3 client (interface 20400).
--
-- Skada here is bkader's Skada-WoTLK (3.3.5) with as few changes as possible. This file loads first
-- (Skada.toc) and fills in what 2.4.3 lacks, so the rest of the code can stay as it is:
--   * addon files get no "..." in 2.4.3: SkadaAddonArgs(...) gives every file the addon's name and its
--     shared private table (the 3.x behaviour);
--   * Lua / API globals added in 3.x (wipe, UnitPower, GetInstanceInfo, the talent group API ...);
--   * widget methods added in 3.x (SetSize, GetSize, SetWordWrap, SetNormalFontObject ...), only
--     added where the client has none, so Blizzard's own methods are never replaced.
-- The other TBC changes are marked "TBC:" in the files they are in (combat log arguments,
-- events, modules left out).

local ADDON_NAME = "Skada"
local private = {}

-- the addon's name and private table, as 3.x passes them to each file through "..."
function SkadaAddonArgs(name, ns)
	if ns then return name, ns end
	return ADDON_NAME, private
end

local _G = _G
local type, pairs, select, tostring = type, pairs, select, tostring

-------------------------------------------------------------------------------
-- Lua

local function wipe(t)
	for k in pairs(t) do
		t[k] = nil
	end
	return t
end
table.wipe = table.wipe or wipe
_G.wipe = _G.wipe or table.wipe

_G.strbyte = _G.strbyte or string.byte
_G.strchar = _G.strchar or string.char
_G.strrep = _G.strrep or string.rep

-- number of characters of an UTF-8 string
_G.strlenutf8 = _G.strlenutf8 or function(s)
	local _, n = string.gsub(s, "[^\128-\191]", "")
	return n
end

-------------------------------------------------------------------------------
-- game API

-- one talent group, no glyphs, no dual spec
_G.GetActiveTalentGroup = _G.GetActiveTalentGroup or function() return 1 end
_G.GetNumTalentGroups = _G.GetNumTalentGroups or function() return 1 end
_G.GetNumGlyphSockets = _G.GetNumGlyphSockets or function() return 0 end
_G.GetGlyphSocketInfo = _G.GetGlyphSocketInfo or function() end
_G.TALENT_ACTIVATION_SPELLS = _G.TALENT_ACTIVATION_SPELLS or {}
_G.GetUnspentTalentPoints = _G.GetUnspentTalentPoints or function(inspect)
	if inspect then return 0 end
	return (UnitCharacterPoints("player")) or 0
end

-- no LFG roles, vehicles or zone map ids in 2.4.3
_G.UnitGroupRolesAssigned = _G.UnitGroupRolesAssigned or function() return "NONE" end
_G.UnitHasVehicleUI = _G.UnitHasVehicleUI or function() return false end
_G.GetCurrentMapAreaID = _G.GetCurrentMapAreaID or function() return 0 end

-- one power type per unit in 2.4.3 (UnitMana): another type reads as 0
local UnitPowerType, UnitMana, UnitManaMax = UnitPowerType, UnitMana, UnitManaMax
_G.UnitPower = _G.UnitPower or function(unit, powerType)
	if powerType and powerType ~= UnitPowerType(unit) then return 0 end
	return UnitMana(unit)
end
_G.UnitPowerMax = _G.UnitPowerMax or function(unit, powerType)
	if powerType and powerType ~= UnitPowerType(unit) then return 0 end
	return UnitManaMax(unit)
end

-- 1 normal, 2 heroic (5-man); raids have one difficulty
_G.GetDungeonDifficulty = _G.GetDungeonDifficulty or GetCurrentDungeonDifficulty or GetInstanceDifficulty
_G.GetRaidDifficulty = _G.GetRaidDifficulty or function() return 1 end

-- raid sizes of the TBC and classic raids; the smallest that holds the raid
local RAID_SIZES = {10, 20, 25, 40}
local PARTY_SIZE = 5

-- name, type, difficulty, difficulty name, max players, dynamic difficulty, is dynamic
_G.GetInstanceInfo = _G.GetInstanceInfo or function()
	local _, instanceType = IsInInstance()
	instanceType = instanceType or "none"
	local difficulty = (instanceType == "party" and GetInstanceDifficulty and GetInstanceDifficulty()) or 1
	local maxPlayers
	if instanceType == "party" then
		maxPlayers = PARTY_SIZE
	elseif instanceType == "raid" then
		local members = GetNumRaidMembers()
		for i = 1, #RAID_SIZES do
			maxPlayers = RAID_SIZES[i]
			if members <= maxPlayers then break end
		end
	end
	return GetRealZoneText(), instanceType, difficulty, nil, maxPlayers, 0, false
end

-- 2.4.3's name of InterfaceOptionsFrame_OpenToCategory (same arguments: a category name or frame)
_G.InterfaceOptionsFrame_OpenToCategory = _G.InterfaceOptionsFrame_OpenToCategory or _G.InterfaceOptionsFrame_OpenToFrame

_G.ChatEdit_GetActiveWindow = _G.ChatEdit_GetActiveWindow or function()
	local editBox = _G.ChatFrameEditBox
	if editBox and editBox:IsShown() then return editBox end
end

-------------------------------------------------------------------------------
-- tables and constants

_G.CLASS_SORT_ORDER = _G.CLASS_SORT_ORDER or {
	"WARRIOR", "PALADIN", "PRIEST", "SHAMAN", "DRUID", "ROGUE", "MAGE", "WARLOCK", "HUNTER"
}

if not _G.LOCALIZED_CLASS_NAMES_MALE then
	-- the client's own names where its strings have them, else English
	local names = {
		WARRIOR = "Warrior", PALADIN = "Paladin", PRIEST = "Priest", SHAMAN = "Shaman", DRUID = "Druid",
		ROGUE = "Rogue", MAGE = "Mage", WARLOCK = "Warlock", HUNTER = "Hunter"
	}
	for class in pairs(names) do
		local localized = _G[class]
		if type(localized) == "string" and localized ~= "" then
			names[class] = localized
		end
	end
	_G.LOCALIZED_CLASS_NAMES_MALE = names
end

_G.YELLOW_FONT_COLOR = _G.YELLOW_FONT_COLOR or {r = 1, g = 1, b = 0}
_G.ORANGE_FONT_COLOR = _G.ORANGE_FONT_COLOR or {r = 1, g = 0.5, b = 0.25}

-------------------------------------------------------------------------------
-- widget methods

local methods = {}

function methods.SetSize(self, width, height)
	self:SetWidth(width)
	self:SetHeight(height or width)
end

function methods.GetSize(self)
	return self:GetWidth(), self:GetHeight()
end

function methods.IsMouseOver(self, top, bottom, left, right)
	return MouseIsOver(self, top, bottom, left, right)
end

-- 2.4.3 font strings have no word wrap switch
function methods.SetWordWrap() end
function methods.CanWordWrap() return true end

-- edit boxes: invisible letters (link codes) are never counted
function methods.SetCountInvisibleLetters() end

-- buttons: 3.x's normal font object is 2.4.3's text font object
function methods.SetNormalFontObject(self, font)
	return self:SetTextFontObject(font)
end
function methods.GetNormalFontObject(self)
	return self:GetTextFontObject()
end

-- fonts / font strings: font, colour and shadow of another font object
function methods.CopyFontObject(self, other)
	if type(other) == "string" then other = _G[other] end
	if type(other) ~= "table" or not other.GetFont then return end
	local file, size, flags = other:GetFont()
	if file then self:SetFont(file, size, flags) end
	if other.GetTextColor and self.SetTextColor then
		self:SetTextColor(other:GetTextColor())
	end
	if other.GetShadowColor and self.SetShadowColor then
		self:SetShadowColor(other:GetShadowColor())
		self:SetShadowOffset(other:GetShadowOffset())
	end
end

-- which methods each widget kind gets (a method only where the client has none)
local FRAME_METHODS = {"SetSize", "GetSize", "IsMouseOver"}
local REGION_METHODS = {"SetSize", "GetSize"}
local widgets = {
	Frame = FRAME_METHODS,
	Button = {"SetSize", "GetSize", "IsMouseOver", "SetNormalFontObject", "GetNormalFontObject"},
	CheckButton = {"SetSize", "GetSize", "IsMouseOver", "SetNormalFontObject", "GetNormalFontObject"},
	EditBox = {"SetSize", "GetSize", "IsMouseOver", "SetCountInvisibleLetters"},
	StatusBar = FRAME_METHODS,
	ScrollFrame = FRAME_METHODS,
	Slider = FRAME_METHODS,
	GameTooltip = FRAME_METHODS,
	MessageFrame = FRAME_METHODS,
	ScrollingMessageFrame = FRAME_METHODS,
	SimpleHTML = FRAME_METHODS,
	ColorSelect = FRAME_METHODS,
	Cooldown = FRAME_METHODS,
	Model = FRAME_METHODS,
	PlayerModel = FRAME_METHODS
}

local function AddMethods(object, names)
	local mt = object and getmetatable(object)
	local index = mt and mt.__index
	if type(index) ~= "table" then return end
	for i = 1, #names do
		local name = names[i]
		if index[name] == nil then
			index[name] = methods[name]
		end
	end
end

do
	-- every sample widget sits on a hidden parent: never shown, an edit box never takes the focus
	local parent = CreateFrame("Frame")
	parent:Hide()
	for kind, names in pairs(widgets) do
		AddMethods(CreateFrame(kind, nil, parent), names)
	end
	AddMethods(parent:CreateTexture(), REGION_METHODS)
	AddMethods(parent:CreateFontString(), {"SetSize", "GetSize", "SetWordWrap", "CanWordWrap", "CopyFontObject"})
	AddMethods(GameFontNormal, {"CopyFontObject"})
end
