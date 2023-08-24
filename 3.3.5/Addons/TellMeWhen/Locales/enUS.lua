local _, core = ...

local setmetatable = setmetatable
local tostring, format = tostring, string.format
local rawset, rawget = rawset, rawget
local L = setmetatable({}, {
	__newindex = function(self, key, value)
		rawset(self, key, value == true and key or value)
	end,
	__index = function(self, key)
		return key
	end
})
function L:F(line, ...)
	line = L[line]
	return format(line, ...)
end
core.L = L

L["Absent"] = true
L["Always"] = true
L["Are you sure you want to reset all groups?"] = true
L["Desaturate Icons"] = true
L["Icons will be desaturated instead of being colored."] = true
L["Buff or Debuff"] = true
L["Buff"] = true
L["Check to only show this group of icons while in combat."] = true
L["Check to show this group of icons while in primary spec."] = true
L["Check to show this group of icons while in secondary spec."] = true
L["Choose spell/item/buff/etc."] = true
L["Clear settings"] = true
L["Click and drag to change size."] = true
L["Columns"] = true
L["Cooldown type"] = true
L["Cooldown"] = true
L["Debuff"] = true
L["Enable"] = true
L["Enter the Name or Id of the Spell, Ability, Item, Buff, Debuff you want this icon to monitor. You can add multiple Buffs/Debuffs by seperating them with ;"] = true
L["Focus Target"] = true
L["Group %d position successfully reset."] = true
L["Groups have been reset!"] = true
L["Height"] = true
L["Icon type"] = true
L["Item"] = true
L["Lock"] = true
L["More options"] = true
L["Only in combat"] = true
L["Only show if cast by self"] = true
L["Pet Target"] = true
L["Present"] = true
L["Primary Spec"] = true
L["Reactive spell or ability"] = true
L["Reset Position"] = true
L["Resize"] = true
L["Right click for icon options. More options in Blizzard interface options menu. Type /tellmewhen to lock and enable addon."] = true
L["Rows"] = true
L["Scale"] = true
L["Secondary Spec"] = true
L["Set the number of icon columns in this group."] = true
L["Set the number of icon rows in this group."] = true
L["Show and enable this group of icons."] = true
L["Show icon when"] = true
L["Show timer"] = true
L["Disable OmniCC"]= true
L["Spacing"] = true
L["Spell or ability"] = true
L["Target of Target"] = true
L["Temporary weapon enchant"] = true
L["These options allow you to change the number, arrangement, and behavior of reminder icons."] = true
L["Totem/non-MoG Ghoul"] = true
L["Unit to watch"] = true
L["Unlock"] = true
L["Unusable"] = true
L["Usable"] = true
L["Weapon slot to monitor"] = true
L["Width"] = true
L['Icons work when locked. When unlocked, you can move/size icon groups and right click individual icons for more settings. You can also type "/tellmewhen" or "/tmw" to lock/unlock.'] = true