-- lua50: native
-- Env.lua - the environment every Skada file runs in on the 1.12 client (Lua 5.0).
--
-- Skada here is the TBC port (tbc/Addons/Skada) rewritten as Lua 5.0 by classic/tools/lua51to50.py.
-- Each converted file starts with "setfenv(1, SkadaEnv)". SkadaEnv reads every global it lacks from
-- the real globals and writes new globals there (SavedVariables, slash commands, Skada itself), so the
-- code behaves as before. What SkadaEnv has itself stays private to Skada, so other vanilla addons
-- never see a GetSpellInfo or a wipe and keep detecting the client as 1.12:
--   * the Lua 5.1 library 5.0 lacks (select, unpack with i / j, string.match, table.wipe, # and %
--     through __len and __mod ...);
--   * game API added after 1.12 (GetSpellInfo from Classic/SpellData.lua, made-up GUIDs, ...);
--   * CreateFrame: 1.12 calls script handlers without arguments (this, event, arg1 ... are globals),
--     so the frames Skada creates get a SetScript / GetScript / HookScript that pass (self, ...) as
--     2.x does, plus the 2.x / 3.x widget methods 1.12 lacks;
--   * a LibStub of its own: Skada's converted libraries never mix with another addon's.
-- This file loads first (Skada.toc) and is plain Lua 5.0.

local G = getfenv(0)
local env = {}
SkadaEnv = env

env._G = env -- _G[name] reads through to the globals; LibStub (false here) stays private
env.LibStub = false
-- (the metatable that reads / writes through to the globals is set at the end of this file: every
-- env.X below must stay in env)

local type, pairs, next, rawget, rawset, tostring, tonumber = type, pairs, next, rawget, rawset, tostring, tonumber
local floor, getn = math.floor, table.getn
local strfind, strsub, strlen, strgsub, strbyte, strchar, strupper = string.find, string.sub, string.len, string.gsub, string.byte, string.char, string.upper
local native_unpack, native_insert, native_concat = unpack, table.insert, table.concat

-- a value for env only where neither env nor the client has one
local function shim(name, value)
	if rawget(env, name) == nil and G[name] == nil then
		rawset(env, name, value)
	end
end
env.SkadaShim = shim

-------------------------------------------------------------------------------
-- Lua 5.1 operators and varargs

-- #t / #s: 5.1's border of a table (raw, like 5.1) or the length of a string
local function len(t)
	if type(t) == "string" then return strlen(t) end
	if rawget(t, 1) == nil then return 0 end
	local i, j = 1, 2
	while rawget(t, j) ~= nil do
		i = j
		j = j * 2
	end
	while j - i > 1 do
		local m = floor((i + j) / 2)
		if rawget(t, m) == nil then j = m else i = m end
	end
	return i
end
env.__len = len

-- a % b (5.1: a - floor(a / b) * b; math.mod is fmod)
local function mod(a, b)
	return a - floor(a / b) * b
end
env.__mod = mod

local UNPACK_RECURSION_MAX = 40 -- longer ranges go through a temporary table

local function unpack_range(t, i, j)
	if i > j then return end
	return t[i], unpack_range(t, i + 1, j)
end

-- unpack(t [, i [, j]]); without i / j as 5.0's unpack (t.n counts trailing nils: varargs' arg table)
local function unpack(t, i, j)
	if i == nil and j == nil then return native_unpack(t) end
	i = i or 1
	j = j or len(t)
	if j - i < UNPACK_RECURSION_MAX then return unpack_range(t, i, j) end
	local tmp = {n = j - i + 1}
	for k = i, j do tmp[k - i + 1] = t[k] end
	return native_unpack(tmp)
end
env.unpack = unpack

function env.select(n, ...)
	if n == "#" then return arg.n end
	if n < 0 then n = arg.n + n + 1 end
	return unpack(arg, n, arg.n)
end

-------------------------------------------------------------------------------
-- table

local function wipe(t)
	for k in pairs(t) do
		t[k] = nil
	end
	return t
end

-- table.insert / table.remove on 5.1's # (5.0's keep a size of their own that goes stale when
-- elements are set directly, as the 5.1 code does)
local function tinsert(t, pos, value)
	if value == nil then
		t[len(t) + 1] = pos
		return
	end
	for k = len(t), pos, -1 do
		t[k + 1] = t[k]
	end
	t[pos] = value
end

local function tremove(t, pos)
	local n = len(t)
	if n == 0 then return nil end
	pos = pos or n
	local value = t[pos]
	for k = pos, n - 1 do
		t[k] = t[k + 1]
	end
	t[n] = nil
	return value
end

local function maxn(t)
	local m = 0
	for k in pairs(t) do
		if type(k) == "number" and k > m then m = k end
	end
	return m
end

local tbl = {}
for k, v in pairs(table) do tbl[k] = v end
tbl.insert, tbl.remove, tbl.getn, tbl.wipe, tbl.maxn = tinsert, tremove, len, wipe, maxn
function tbl.concat(t, sep, i, j)
	return native_concat(t, sep or "", i or 1, j or len(t))
end
env.table = tbl
env.tinsert, env.tremove, env.wipe = tinsert, tremove, wipe
env.tContains = function(t, value)
	for _, v in pairs(t) do
		if v == value then return true end
	end
end

-------------------------------------------------------------------------------
-- string

local function match_result(s, st, en, ...)
	if not st then return nil end
	if arg.n == 0 then return strsub(s, st, en) end
	return native_unpack(arg)
end

local function match(s, pattern, init)
	return match_result(s, strfind(s, pattern, init))
end

-- strsplit(sep, s [, limit]): sep is a set of separator characters, as in WoW
local function split(sep, s, limit)
	local parts, n, pos = {}, 0, 1
	local set = "[" .. strgsub(sep, "([%^%]%-%%])", "%%%1") .. "]"
	while true do
		if limit and n == limit - 1 then break end
		local st, en = strfind(s, set, pos)
		if not st then break end
		n = n + 1
		parts[n] = strsub(s, pos, st - 1)
		pos = en + 1
	end
	n = n + 1
	parts[n] = strsub(s, pos)
	parts.n = n
	return native_unpack(parts)
end

local function trim(s, chars)
	local set = chars and ("[" .. strgsub(chars, "([%^%]%-%%])", "%%%1") .. "]") or "%s"
	s = strgsub(s, "^" .. set .. "+", "")
	s = strgsub(s, set .. "+$", "")
	return s
end

local function join(sep, ...)
	return native_concat(arg, sep, 1, arg.n)
end

-- string.byte(s, i, j): several bytes as in 5.1 (5.0 returns one)
local function byte(s, i, j)
	if j == nil then return strbyte(s, i) end
	i = i or 1
	if i < 0 then i = strlen(s) + i + 1 end
	if j < 0 then j = strlen(s) + j + 1 end
	if i > j then return end
	local bytes = {n = j - i + 1}
	for k = i, j do bytes[k - i + 1] = strbyte(s, k) end
	return native_unpack(bytes)
end

local function reverse(s)
	local out = {}
	for k = strlen(s), 1, -1 do out[strlen(s) - k + 1] = strsub(s, k, k) end
	return native_concat(out)
end

-- string.gsub with 5.1's replacements: a table, %0 (the whole match) in a string, and a function or
-- table giving nil / false (5.1 keeps the match, 5.0 would delete it). The pattern gets an outer
-- capture for the whole match (not for patterns with back-references: 5.0's own gsub then).
local function call_repl(f, ...) -- arg[1] is the whole match, the rest the pattern's captures
	local r
	if arg.n == 1 then r = f(arg[1]) else r = f(unpack(arg, 2, arg.n)) end
	if r == nil or r == false then return arg[1] end
	return r
end

local function gsub(s, pattern, repl, n)
	local kind = type(repl)
	local special = kind == "table" or kind == "function" or (kind == "string" and strfind(repl, "%%0"))
	if special and not strfind(pattern, "%%[1-9]") then
		local anchored = strsub(pattern, 1, 1) == "^"
		pattern = anchored and ("^(" .. strsub(pattern, 2) .. ")") or ("(" .. pattern .. ")")
		if kind == "table" then
			local t = repl
			repl = function(...)
				return call_repl(function(key) return t[key] end, unpack(arg))
			end
		elseif kind == "function" then
			local f = repl
			repl = function(...)
				return call_repl(f, unpack(arg))
			end
		else
			local template = repl
			repl = function(...)
				local captures = arg
				return (strgsub(template, "%%(.)", function(c)
					local d = tonumber(c)
					if d then return captures[d + 1] or "" end
					return c
				end))
			end
		end
	end
	if n then return strgsub(s, pattern, repl, n) end
	return strgsub(s, pattern, repl)
end

local str = {}
for k, v in pairs(string) do str[k] = v end
str.match, str.gmatch, str.split, str.trim, str.join = match, string.gfind, split, trim, join
str.byte, str.reverse, str.gsub = byte, reverse, gsub
env.string = str
env.strmatch, env.gmatch, env.strsplit, env.strtrim, env.strjoin = match, string.gfind, split, trim, join
env.strbyte, env.strrev, env.gsub, env.strchar, env.strrep = byte, reverse, gsub, strchar, string.rep
env.strconcat = function(...) return native_concat(arg, "", 1, arg.n) end
env.tostringall = function(...)
	for k = 1, arg.n do arg[k] = tostring(arg[k]) end
	return native_unpack(arg)
end
env.strlenutf8 = function(s)
	local _, n = strgsub(s, "[^\128-\191]", "")
	return n
end

-------------------------------------------------------------------------------
-- math and bit

local m = {}
for k, v in pairs(math) do m[k] = v end
m.huge = 1 / 0
m.fmod = math.mod
m.modf = function(x)
	local i = x >= 0 and floor(x) or -floor(-x)
	return i, x - i
end
env.math = m

if not G.bit then
	local BIT_COUNT = 32
	local function bitop(a, b, op)
		local r, p = 0, 1
		a, b = mod(a, 4294967296), mod(b, 4294967296)
		for _ = 1, BIT_COUNT do
			local x, y = mod(a, 2), mod(b, 2)
			if op(x, y) then r = r + p end
			a, b, p = floor(a / 2), floor(b / 2), p * 2
		end
		return r
	end
	env.bit = {
		band = function(a, b) return bitop(a, b, function(x, y) return x == 1 and y == 1 end) end,
		bor = function(a, b) return bitop(a, b, function(x, y) return x == 1 or y == 1 end) end,
		bxor = function(a, b) return bitop(a, b, function(x, y) return x ~= y end) end,
		bnot = function(a) return 4294967295 - mod(a, 4294967296) end,
		lshift = function(a, n) return mod(a * 2 ^ n, 4294967296) end,
		rshift = function(a, n) return floor(mod(a, 4294967296) / 2 ^ n) end
	}
end

-------------------------------------------------------------------------------
-- loadstring: code made at run time runs in SkadaEnv too. The libraries' generated dispatchers
-- (5.1 chunks take their arguments through "...", 5.0 chunks take none) read them through
-- SkadaChunkArgs(): the returned function keeps its arguments for the chunk.

local native_loadstring = loadstring
local chunkArgs = {n = 0}
function env.SkadaChunkArgs()
	return native_unpack(chunkArgs)
end
function env.loadstring(code, name)
	local f, err = native_loadstring(code, name)
	if not f then return nil, err end
	setfenv(f, env)
	if not strfind(code, "SkadaChunkArgs", 1, true) then return f end
	return function(...)
		chunkArgs = arg
		return f()
	end
end

-------------------------------------------------------------------------------
-- 2.x / 3.x functions of the client's Lua API

shim("print", function(...)
	for i = 1, arg.n do arg[i] = tostring(arg[i]) end
	DEFAULT_CHAT_FRAME:AddMessage(native_concat(arg, " ", 1, arg.n))
end)

-- collectgarbage(opt): 5.0 takes a limit (none: collect now); "count" is gcinfo() in 1.12
local native_collectgarbage = collectgarbage
function env.collectgarbage(opt)
	if opt == "count" then return gcinfo() end
	if type(opt) == "number" then return native_collectgarbage(opt) end
	return native_collectgarbage()
end

-- Skada's errors never open the client's error dialog: each distinct error is printed once to the
-- chat (red) and kept in SkadaEnv.SkadaErrors. Used by the libraries' safecalls (events, timers,
-- callbacks: geterrorhandler) and by the frame scripts below; other addons' errors are untouched.
local ERROR_PREFIX = "|cffff4040Skada error:|r "
local reportedErrors = {}
env.SkadaErrors = {}
local function skada_error(msg)
	msg = tostring(msg)
	if reportedErrors[msg] then return end
	reportedErrors[msg] = true
	tinsert(env.SkadaErrors, msg)
	if G.DEFAULT_CHAT_FRAME then G.DEFAULT_CHAT_FRAME:AddMessage(ERROR_PREFIX .. msg) end
end
env.SkadaError = skada_error
env.geterrorhandler = function() return skada_error end

-- hooksecurefunc([table,] name, hook): the hook runs after the original, with its arguments
shim("hooksecurefunc", function(t, name, hook)
	if type(t) == "string" then
		t, name, hook = G, t, name
	end
	local orig = t[name]
	t[name] = function(...)
		local r1, r2, r3, r4, r5, r6, r7, r8 = orig(native_unpack(arg))
		hook(native_unpack(arg))
		return r1, r2, r3, r4, r5, r6, r7, r8
	end
end)

shim("securecall", function(f, ...)
	if type(f) == "string" then f = G[f] end
	return f(native_unpack(arg))
end)
shim("issecurevariable", function() return false end)
shim("InCombatLockdown", function() return false end)
shim("debugstack", function() return "" end)
shim("debugprofilestop", function() return GetTime() * 1000 end)

-------------------------------------------------------------------------------
-- frames: 2.x script handlers and widget methods

local scripts = setmetatable({}, {__mode = "k"}) -- [frame][script] = the (self, ...) handler
local nativeSetScript, nativeGetScript = {}, {}

local function adapter(script, fn)
	if script == "OnEvent" then
		return function()
			local ok, err = pcall(fn, this, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
			if not ok then skada_error(err) end
		end
	end
	return function()
		local ok, err = pcall(fn, this, arg1, arg2, arg3, arg4, arg5)
		if not ok then skada_error(err) end
	end
end

local function SetScript(self, script, fn)
	local t = scripts[self]
	if not t then
		t = {}
		scripts[self] = t
	end
	t[script] = fn
	local native = nativeSetScript[self:GetObjectType()]
	if fn == nil then return native(self, script, nil) end
	return native(self, script, adapter(script, fn))
end

local function GetScript(self, script)
	local t = scripts[self]
	local fn = t and t[script]
	if fn then return fn end
	return nativeGetScript[self:GetObjectType()](self, script)
end

-- a 1.12 handler found here takes no arguments and reads this / arg1 ..., still set when it runs
local function HookScript(self, script, hook)
	local prev = GetScript(self, script)
	if not prev then return SetScript(self, script, hook) end
	return SetScript(self, script, function(...)
		prev(native_unpack(arg))
		return hook(native_unpack(arg))
	end)
end

local methods = {}
methods.SetScript, methods.GetScript, methods.HookScript = SetScript, GetScript, HookScript

function methods.SetSize(self, width, height)
	self:SetWidth(width)
	self:SetHeight(height or width)
end

function methods.GetSize(self)
	return self:GetWidth(), self:GetHeight()
end

function methods.IsMouseOver(self, top, bottom, left, right)
	if G.MouseIsOver then return MouseIsOver(self, top, bottom, left, right) end
	return GetMouseFocus and GetMouseFocus() == self
end

function methods.GetFontString(self)
	local name = self.GetName and self:GetName()
	local fs = self.SkadaFontString or (name and G[name .. "Text"])
	if not fs then
		fs = self:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		fs:SetAllPoints(self)
		self.SkadaFontString = fs
	end
	return wrap(fs)
end

function methods.SetWordWrap() end
function methods.SetCursorPosition() end
function methods.GetCursorPosition() return 0 end
function methods.CanWordWrap() return true end
function methods.SetCountInvisibleLetters() end
function methods.SetClampedToScreen() end
function methods.SetClampRectInsets() end
function methods.SetHitRectInsets() end
function methods.SetToplevel() end
function methods.SetFixedFrameStrata() end
function methods.SetFixedFrameLevel() end
function methods.SetMotionScriptsWhileDisabled() end
function methods.SetHorizTile() end
function methods.SetVertTile() end
function methods.SetNonSpaceWrap() end
function methods.SetIndentedWordWrap() end
function methods.SetRotatesTexture() end
function methods.SetDrawLayer() end

function methods.SetNormalFontObject(self, font)
	return self:SetTextFontObject(font)
end
function methods.GetNormalFontObject(self)
	return self:GetTextFontObject()
end

function methods.CopyFontObject(self, other)
	if type(other) == "string" then other = G[other] end
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

-- which methods each kind of object may get (only where the client has none)
local FRAME_METHODS = {
	"SetSize", "GetSize", "IsMouseOver", "SetClampedToScreen", "SetClampRectInsets", "SetHitRectInsets",
	"SetToplevel", "SetFixedFrameStrata", "SetFixedFrameLevel", "SetMotionScriptsWhileDisabled",
	"SetNormalFontObject", "GetNormalFontObject", "SetCountInvisibleLetters", "SetCursorPosition", "GetCursorPosition"
}
local TEXTURE_METHODS = {"SetSize", "GetSize", "SetHorizTile", "SetVertTile", "SetRotatesTexture", "SetDrawLayer"}
local FONTSTRING_METHODS = {"SetSize", "GetSize", "SetWordWrap", "CanWordWrap", "SetNonSpaceWrap", "SetIndentedWordWrap", "CopyFontObject"}

local wrap -- wrap(object): the methods above on one widget (and the regions it creates)

local function CreateTexture(self, name, layer, inherits)
	local texture = self.SkadaNativeCreateTexture(self, name, layer, inherits)
	return wrap(texture)
end

local function CreateFontString(self, name, layer, inherits)
	local fs = self.SkadaNativeCreateFontString(self, name, layer, inherits)
	return wrap(fs)
end

local wrapped = setmetatable({}, {__mode = "k"})

-- methods that hand out a region (a button's font string, a status bar's texture ...): the region
-- gets the methods above too
local REGION_GETTERS = {
	"GetFontString", "GetNormalTexture", "GetHighlightTexture", "GetPushedTexture", "GetDisabledTexture",
	"GetCheckedTexture", "GetStatusBarTexture", "GetThumbTexture"
}
local nativeGetters = {} -- [kind][name] = the client's method

-- 2.x's short SetPoint forms: (point), (point, x, y), (point, region), (point, region, relPoint);
-- 1.12 wants (point, region, relPoint, x, y). SetAllPoints(true / nil) means the parent.
local nativeAnchors = {} -- [kind] = {SetPoint, SetAllPoints}
local function SetPoint(self, point, a, b, c, d)
	local native = nativeAnchors[self:GetObjectType()][1]
	if type(a) == "number" then
		return native(self, point, self:GetParent(), point, a, b or 0)
	end
	if a == nil then a = self:GetParent() end
	return native(self, point, a, b or point, c or 0, d or 0)
end
-- SetText(nil) clears the text in 2.x, 1.12 refuses it
local nativeSetText = {}
local function SetText(self, text, a, b, c, d)
	if text == nil then text = "" end
	return nativeSetText[self:GetObjectType()](self, text, a, b, c, d)
end
local function SetFormattedText(self, fmt, ...)
	return SetText(self, string.format(fmt, native_unpack(arg)))
end
local function SetAllPoints(self, region)
	if region == nil or region == true then region = self:GetParent() end
	return nativeAnchors[self:GetObjectType()][2](self, region)
end
local getters = {}
for i = 1, getn(REGION_GETTERS) do
	local name = REGION_GETTERS[i]
	getters[name] = function(self, a, b)
		return wrap(nativeGetters[self:GetObjectType()][name](self, a, b))
	end
end

function wrap(obj)
	if type(obj) ~= "table" or wrapped[obj] or not obj.GetObjectType then return obj end
	wrapped[obj] = true
	local kind = obj:GetObjectType()
	if not nativeAnchors[kind] then nativeAnchors[kind] = {obj.SetPoint, obj.SetAllPoints} end
	obj.SetPoint, obj.SetAllPoints = SetPoint, SetAllPoints
	if obj.SetText then
		if not nativeSetText[kind] then nativeSetText[kind] = obj.SetText end
		obj.SetText = SetText
		if not obj.SetFormattedText then obj.SetFormattedText = SetFormattedText end
	end
	local list
	if kind == "Texture" then
		list = TEXTURE_METHODS
	elseif kind == "FontString" then
		list = FONTSTRING_METHODS
	else
		list = FRAME_METHODS
		if not nativeSetScript[kind] then
			nativeSetScript[kind], nativeGetScript[kind] = obj.SetScript, obj.GetScript
		end
		obj.SetScript, obj.GetScript, obj.HookScript = SetScript, GetScript, HookScript
		local natives = nativeGetters[kind]
		if not natives then
			natives = {}
			nativeGetters[kind] = natives
			for i = 1, getn(REGION_GETTERS) do
				natives[REGION_GETTERS[i]] = obj[REGION_GETTERS[i]]
			end
		end
		for i = 1, getn(REGION_GETTERS) do
			local name = REGION_GETTERS[i]
			if natives[name] then obj[name] = getters[name] end
		end
		-- 1.12 buttons have no GetFontString: the text region the template named
		if kind == "Button" or kind == "CheckButton" then
			if not natives.GetFontString then obj.GetFontString = methods.GetFontString end
		end
		if obj.CreateTexture then
			obj.SkadaNativeCreateTexture, obj.CreateTexture = obj.CreateTexture, CreateTexture
			obj.SkadaNativeCreateFontString, obj.CreateFontString = obj.CreateFontString, CreateFontString
		end
		-- the regions and child frames a template made
		if obj.GetRegions then
			local regions = {obj:GetRegions()}
			for i = 1, getn(regions) do wrap(regions[i]) end
		end
		if obj.GetChildren then
			local children = {obj:GetChildren()}
			for i = 1, getn(children) do wrap(children[i]) end
		end
	end
	for i = 1, getn(list) do
		local name = list[i]
		if obj[name] == nil then
			obj[name] = methods[name]
		end
	end
	return obj
end
env.SkadaWrapFrame = wrap

local native_CreateFrame = CreateFrame
function env.CreateFrame(kind, name, parent, template)
	return wrap(native_CreateFrame(kind, name, parent, template))
end

-- a font object made from a hidden font string: SetFont / GetFont / colours / shadow / justify
shim("CreateFont", function(name)
	local holder = native_CreateFrame("Frame")
	holder:Hide()
	local fs = holder:CreateFontString(name)
	fs:SetFontObject(G.GameFontNormal)
	return wrap(fs)
end)

-------------------------------------------------------------------------------
-- events and frames Skada uses that 1.12 has under other names or not at all

shim("GameTooltip_Hide", function() GameTooltip:Hide() end)
shim("IsModifierKeyDown", function() return IsShiftKeyDown() or IsControlKeyDown() or IsAltKeyDown() end)
shim("UIDropDownMenu_CreateInfo", function() return {} end)
shim("ChatFontSmall", G.ChatFontNormal or G.GameFontHighlightSmall)
shim("ChatFrame_AddMessageEventFilter", function() end)
shim("ChatFrame_RemoveMessageEventFilter", function() end)
shim("CombatLogClearEntries", function() end)
shim("GetCurrentDungeonDifficulty", function() return 1 end)
shim("GetInstanceDifficulty", function() return 1 end)
shim("IsActiveBattlefieldArena", function() return nil end)
shim("GetBattlefieldArenaFaction", function() return nil end)
shim("UnitCastingInfo", function() return nil end)
shim("UnitIsFeignDeath", function() return nil end)
shim("UnitIsVisible", function(unit) return UnitExists(unit) end)
shim("GetSpellLink", function(id) return env.GetSpellInfo(id) end)
shim("GetBuildInfo", function() return "1.12.1", "5875", "Sep 19 2006", 11200 end)
shim("UpdateAddOnMemoryUsage", function() end)
shim("GetAddOnMemoryUsage", function() return gcinfo and gcinfo() or 0 end)
shim("IsMouseButtonDown", function() return nil end)
shim("GetCursorInfo", function() return nil end)
shim("CloseSpecialWindows", function() return nil end)
shim("GetPartyAssignment", function() return nil end)
shim("BNSendWhisper", function() end)
shim("GetMinimapShape", nil)

-- UIDropDownMenu (1.12 calls info.func(arg1, arg2) with the button as "this", 2.x passes the button first)
local native_AddButton = UIDropDownMenu_AddButton
function env.UIDropDownMenu_AddButton(info, level)
	local func = info.func
	if func and func ~= info.SkadaAdapter then
		local adapted = function(a1, a2)
			return func(this, a1, a2, this and this.checked)
		end
		info.func, info.SkadaAdapter = adapted, adapted
	end
	return native_AddButton(info, level)
end

-- dropdown initialize functions: 1.12 calls initialize(level), 2.x initialize(frame, level)
local function adapt_initialize(frame, init)
	if not init or init == frame.SkadaInitAdapter then return init end
	local adapted = function(level)
		return init(frame, level or G.UIDROPDOWNMENU_MENU_LEVEL)
	end
	frame.SkadaInitAdapter = adapted
	return adapted
end
local native_ToggleDropDownMenu, native_UIDropDownMenu_Initialize = ToggleDropDownMenu, UIDropDownMenu_Initialize
function env.ToggleDropDownMenu(level, value, frame, anchor, x, y)
	if frame and frame.initialize then
		frame.initialize = adapt_initialize(frame, frame.initialize)
	end
	return native_ToggleDropDownMenu(level, value, frame, anchor, x, y)
end
function env.UIDropDownMenu_Initialize(frame, init, displayMode, level)
	return native_UIDropDownMenu_Initialize(frame, adapt_initialize(frame, init), displayMode, level)
end

-- StaticPopup (1.12 calls OnAccept(data, data2), OnShow(data) ... without the dialog, 2.x passes it first)
local POPUP_CALLBACKS = {"OnAccept", "OnCancel", "OnShow", "OnHide", "OnUpdate", "EditBoxOnEnterPressed", "EditBoxOnEscapePressed"}
local function popup_dialog()
	local f = this
	while f and not f.which and f.GetParent do f = f:GetParent() end
	return f
end
local native_StaticPopup_Show = StaticPopup_Show
function env.StaticPopup_Show(which, text1, text2, data)
	local info = G.StaticPopupDialogs[which]
	if info and not info.SkadaAdapted then
		info.SkadaAdapted = true
		for i = 1, getn(POPUP_CALLBACKS) do
			local f = info[POPUP_CALLBACKS[i]]
			if f then
				info[POPUP_CALLBACKS[i]] = function(a1, a2)
					local dialog = popup_dialog()
					if dialog and not dialog.editBox and dialog.GetName then
						dialog.editBox = G[dialog:GetName() .. "EditBox"]
					end
					return f(dialog, a1, a2)
				end
			end
		end
	end
	return native_StaticPopup_Show(which, text1, text2, data)
end

-- the addon's TOC fields, if the client cannot read them
local METADATA = {Version = "1.8.87-classic", Title = "Skada", Author = "Kader"}
shim("GetAddOnMetadata", function(_, field) return METADATA[field] end)

-- logged in once PLAYER_LOGIN has fired
do
	local loggedIn = false
	local f = native_CreateFrame("Frame")
	f:RegisterEvent("PLAYER_LOGIN")
	f:SetScript("OnEvent", function() loggedIn = true end)
	shim("IsLoggedIn", function() return loggedIn end)
end

-- in a raid: the raid members' names
shim("UnitInRaid", function(unit)
	if GetNumRaidMembers() == 0 then return nil end
	local name = UnitName(unit)
	for i = 1, GetNumRaidMembers() do
		if UnitName("raid" .. i) == name then return i - 1 end
	end
end)

shim("UnitInBattleground", function(unit)
	for i = 1, (G.MAX_BATTLEFIELD_QUEUES or 3) do
		local status = GetBattlefieldStatus and GetBattlefieldStatus(i)
		if status == "active" then return UnitInRaid(unit) end
	end
end)

-------------------------------------------------------------------------------
-- spells: GetSpellInfo from Classic/SpellData.lua (the 1.12 client has no spell ids at all)

local ICON_PATH = "Interface\\Icons\\"
local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local DATA_MAX_LINE = 400 -- longest data line, for finding the line start of an id

local spellById, spellByName = {}, {} -- caches: id -> {name, icon, school}, name -> id

local function parse_line(lineStart)
	local _, _, name, school, icon, ids = strfind(env.SKADA_SPELL_DATA, "^([^\t\n]+)\t(%d+)\t([^\t\n]*)\t(#[%d#]+)\n", lineStart)
	return name, tonumber(school), icon, ids
end

-- the data line holding a spell id
local function line_of_id(id)
	local data = env.SKADA_SPELL_DATA
	local pos = strfind(data, "#" .. id .. "#", 1, true)
	if not pos then return end
	local from = pos - DATA_MAX_LINE
	if from < 1 then from = 1 end
	local lineStart
	local s = from
	while true do
		local nl = strfind(data, "\n", s, true)
		if not nl or nl >= pos then break end
		lineStart = nl + 1
		s = nl + 1
	end
	return lineStart
end

local function line_of_name(name)
	local pos = strfind(env.SKADA_SPELL_DATA, "\n" .. name .. "\t", 1, true)
	return pos and (pos + 1)
end

local function cache_line(lineStart, id)
	local name, school, icon, ids = parse_line(lineStart)
	if not name then return end
	local _, _, first = strfind(ids, "^#(%d+)#")
	first = tonumber(first)
	local info = {name, icon ~= "" and (ICON_PATH .. icon) or DEFAULT_ICON, school}
	spellById[id or first] = info
	spellById[first] = spellById[first] or info
	spellByName[name] = first
	return info
end

-- name, rank, icon (+ 2.x's cost, funnel, power type, cast time, ranges as nil); also takes a name
function env.GetSpellInfo(spell)
	if spell == nil then return end
	local info
	if type(spell) == "number" then
		info = spellById[spell]
		if info == nil then
			local lineStart = line_of_id(spell)
			info = lineStart and cache_line(lineStart, spell) or false
			spellById[spell] = info
		end
	else
		local id = env.SkadaSpellId(spell)
		info = id and spellById[id]
	end
	if not info then return end
	return info[1], nil, info[2]
end

local DYNAMIC_ID_BASE = 900000 -- ids for names Spell.dbc does not know (items, server spells)
local nextDynamicId = DYNAMIC_ID_BASE

-- the spell id a name stands for (its highest rank), a made-up one for an unknown name
function env.SkadaSpellId(name)
	if not name then return end
	local id = spellByName[name]
	if id then return id end
	local lineStart = line_of_name(name)
	local info = lineStart and cache_line(lineStart)
	if info then return spellByName[name] end
	nextDynamicId = nextDynamicId + 1
	spellByName[name] = nextDynamicId
	spellById[nextDynamicId] = {name, DEFAULT_ICON, 1}
	return nextDynamicId
end

-- a name Spell.dbc knows (no made-up id is given for it)
function env.SkadaSpellKnown(name)
	local id = spellByName[name]
	if id then return id < DYNAMIC_ID_BASE end
	return line_of_name(name) ~= nil
end

-- the school mask of a spell (Spell.dbc), 1 (physical) when unknown
function env.SkadaSpellSchool(id)
	local info = id and spellById[id]
	return info and info[3] or 1
end

-------------------------------------------------------------------------------
-- units: made-up GUIDs (1.12 has none). Players, pets and creatures are told apart by name; a
-- creature that is a known boss carries its real creature id (Classic/BossData.lua) so Skada's boss
-- detection works.

local HASH_MOD = 16777216 -- 24 bits: 6 hex digits
local guidByKey, keyByHash = {}, {}

local function hash(s)
	local h = 5381
	for i = 1, strlen(s) do
		h = mod(h * 33 + strbyte(s, i), HASH_MOD)
	end
	return h
end

local GUID_PREFIX = {player = "0x0000000000", pet = "0xF140000000", npc = "0xF130"}

-- kind: "player", "pet" or "npc"
function env.SkadaGUID(name, kind)
	if not name then return end
	kind = kind or "npc"
	local key = kind .. ":" .. name
	local guid = guidByKey[key]
	if guid then return guid end
	local h = hash(key)
	while keyByHash[h] and keyByHash[h] ~= key do
		h = mod(h + 1, HASH_MOD)
	end
	keyByHash[h] = key
	if kind == "npc" then
		local entry = env.SKADA_BOSS_IDS and env.SKADA_BOSS_IDS[name] or 0
		guid = string.format("%s00%04X%06X", GUID_PREFIX.npc, entry, h)
	else
		guid = string.format("%s%06X", GUID_PREFIX[kind], h)
	end
	guidByKey[key] = guid
	return guid
end

local function unit_kind(unit)
	if UnitIsPlayer(unit) then return "player" end
	if strfind(unit, "pet") or (UnitPlayerControlled and UnitPlayerControlled(unit)) then return "pet" end
	return "npc"
end
env.SkadaUnitKind = unit_kind

function env.UnitGUID(unit)
	unit = env.SkadaUnitId(unit)
	if not unit or not UnitExists(unit) then return end
	return env.SkadaGUID(UnitName(unit), unit_kind(unit))
end

shim("GetPlayerInfoByGUID", function() return nil end)

-- 2.x's unit functions also take a group member's name; 1.12's take unit ids only ("party1", ...)
local function name_unit(name)
	if UnitName("player") == name then return "player" end
	if UnitName("pet") == name then return "pet" end
	for i = 1, GetNumRaidMembers() do
		if UnitName("raid" .. i) == name then return "raid" .. i end
		if UnitName("raidpet" .. i) == name then return "raidpet" .. i end
	end
	for i = 1, GetNumPartyMembers() do
		if UnitName("party" .. i) == name then return "party" .. i end
		if UnitName("partypet" .. i) == name then return "partypet" .. i end
	end
end

local function unit_id(unit)
	if type(unit) ~= "string" or strfind(unit, "^%l") then return unit end -- ids are lower case
	local _, _, name = strfind(unit, "^([^%-]+)") -- "Name-Realm"
	return name_unit(name) or "raidpet40" -- a unit id that does not exist (1.12 refuses unknown ones)
end
env.SkadaUnitId = unit_id

local UNIT_FUNCTIONS = {
	"UnitIsConnected", "UnitClass", "UnitName", "UnitExists", "UnitIsDeadOrGhost", "UnitIsDead", "UnitHealth",
	"UnitHealthMax", "UnitLevel", "UnitRace", "UnitIsPlayer", "UnitInParty", "UnitPowerType", "UnitMana",
	"UnitManaMax", "UnitAffectingCombat", "UnitIsFriend", "UnitCanAttack", "UnitSex", "UnitFactionGroup",
	"UnitIsUnit", "UnitIsGhost", "UnitBuff", "UnitDebuff", "UnitCharacterPoints", "UnitIsVisible"
}
for i = 1, getn(UNIT_FUNCTIONS) do
	local name = UNIT_FUNCTIONS[i]
	local f = rawget(env, name) or G[name]
	if f then
		env[name] = function(a, b, c)
			return f(unit_id(a), (name == "UnitIsUnit" or name == "UnitIsFriend" or name == "UnitCanAttack") and unit_id(b) or b, c)
		end
	end
end

-------------------------------------------------------------------------------
-- buffs: 1.12's UnitBuff gives the icon and stack count only; the name comes from the tooltip

local scanner
local function buff_name(unit, index, debuff)
	if not scanner then
		scanner = native_CreateFrame("GameTooltip", "SkadaClassicScanTooltip", nil, "GameTooltipTemplate")
		scanner:SetOwner(G.WorldFrame, "ANCHOR_NONE")
	end
	scanner:ClearLines()
	scanner:SetOwner(G.WorldFrame, "ANCHOR_NONE")
	if debuff then scanner:SetUnitDebuff(unit, index) else scanner:SetUnitBuff(unit, index) end
	local line = G.SkadaClassicScanTooltipTextLeft1
	return line and line:GetText()
end

local native_UnitBuff, native_UnitDebuff = UnitBuff, UnitDebuff

-- 2.4.3's returns: name, rank, icon, count, duration, time left (no duration / time left in 1.12)
function env.UnitBuff(unit, index)
	local icon, count = native_UnitBuff(unit, index)
	if not icon then return end
	return buff_name(unit, index), nil, icon, count or 1, nil, nil
end

function env.UnitDebuff(unit, index)
	local icon, count, dispelType = native_UnitDebuff(unit, index)
	if not icon then return end
	return buff_name(unit, index, true), nil, icon, count or 1, dispelType, nil, nil
end

-------------------------------------------------------------------------------
-- from here on SkadaEnv reads what it lacks from the globals and writes new names there; what
-- belongs to SkadaEnv itself is set with rawset (SkadaShim, the data files)

setmetatable(env, {__index = G, __newindex = G})
