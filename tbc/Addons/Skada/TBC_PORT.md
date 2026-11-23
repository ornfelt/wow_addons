# Skada on the TBC 2.4.3 client

This is `wotlk/Addons/Skada` (bkader's Skada-WoTLK 1.8.87 with the local fixes) ported to the
2.4.3 client (interface 20400) with as few changes as possible, so the two copies keep the same
design and code structure: `diff -r wotlk/Addons/Skada tbc/Addons/Skada` shows the whole port.
Every TBC change in an existing file is marked `TBC:`.

Install / update the client copy with `tbc/sync_addon.ps1` (or `.sh`; env var `wow_tbc_dir`).

## What changed

| Where | Change |
| --- | --- |
| `Compat.lua` (new, loaded first) | `SkadaAddonArgs(...)`: 2.4.3 passes no `...` to addon files, so every file's `local folder, Skada = ...` became `= SkadaAddonArgs(...)` (the locales' `NewLocale(...)` too). 3.x globals 2.4.3 lacks (`wipe`, `UnitPower`, `GetInstanceInfo`, the talent group / glyph API, `UnitGroupRolesAssigned`, `CLASS_SORT_ORDER`, ...) and 3.x widget methods (`SetSize`, `GetSize`, `IsMouseOver`, `SetWordWrap`, `SetNormalFontObject`, `CopyFontObject`, ...), each only where the client has none. |
| `Compat.xml` (new) | `OptionsListButtonTemplate` (3.x template, used by AceGUI's TreeGroup in the options window). |
| `Core/Functions.lua` | The combat log argument lists (no overkill in damage events, no overheal / absorbed in heal events). The overheal is estimated from the target's missing health (2.4.3 sends the heal event before the health update). Aura events have no caster in 2.4.3: it is taken from the group's last cast of that spell on that unit, or from when the aura was applied. Missed events have no amount: a fully absorbed / blocked / resisted hit is estimated from the attacker's landed hits with that spell. The combat start buff scan takes spell ids and casters from those auras (2.4.3's `UnitBuff` has neither). |
| `Core/Core.lua` | No vehicle events. `PLAYER_REGEN_DISABLED` also starts the combat on a tentative segment (2.4.3 can fire it after the pull's combat log event, which dropped slow solo fights). |
| `Core/Menus.lua` | Skada's dropdown menus open through `SkadaToggleDropDownMenu` (Compat.lua): 2.4.3 calls a menu's `initialize(level, menuList)`, 3.x `initialize(frame, level)`, so every menu opened empty. Blizzard's own `ToggleDropDownMenu` is left alone (other addons share it). |
| `Modules/Tweaks.lua` | 2.4.3's chat filter signature (`filter(msg)` with the `event` / `arg2` globals). Fury of Frostmourne name fallback. |
| `Modules/Healthstone.lua` | Master Healthstone as the name to match (Fel Healthstone is 3.x). |
| `Locales/enUS.lua` | Fallbacks for global strings 2.4.3 lacks (`MINIMUM`, `MAXIMUM`, `CRIT_ABBR`, `APPLY`, `ENEMY`, ...). |
| `Libs/AceGUI-3.0/.../TabGroup.lua` | 2.4.3's `PanelTemplates_TabResize(padding, tab, ...)` argument order, and the text's own width as its `absoluteTextSize` (newer AceGUI's way: the anchored width depends on the tab's, which grew the tabs to 415 px on my_wow's client). |
| `Libs/LibCompat-1.0/.../LibGroupTalents-1.0.lua` | `CHARACTER_POINTS_CHANGED` instead of `PLAYER_TALENT_UPDATE`, no glyph events. |
| Left out | `Modules/Threat.lua` (no threat API in 2.4.3), `Modules/Failbot.lua` + `LibFail-1.0` (WotLK raid fails), `LibDualSpec-1.0` (no dual spec), `TaintLess.xml` (3.x taint fixes). |

## Estimates and limits (2.4.3 combat log)

- Overheal: estimated for group members and the target (any other unit's heals count as 0 overheal).
- Absorbs: hits that are only partly absorbed are exact. A fully absorbed hit is sized from that attacker's
  recent hits with the same spell (none seen yet: not counted).
- Auras applied before the login / reload have no known caster, so the combat start buff scan cannot
  credit them; auras applied while logged in are credited.
- No overkill: the death log shows no overkill.

## Tested (2026-11-23, real 2.4.3 client on mangos-tbc)

Load without Lua errors; damage, damage taken, healing (with the overheal estimate checked against
`UnitHealth`), absorbs (Ice Barrier), buffs, activity, tooltips, segments, the total segment kept over
a reload, the options window (tree, tabs, sliders). Not tested in a group, raid, battleground or arena.

Again on 2026-11-23 (later): an error sweep with screenshots (every mode and its sub mode on a segment
and the total, the menus and a submenu, choosing a segment from the menu, the reset popup and its
Cancel, the report window, all 31 options pages, reloads) and five real fights - 0 Lua errors, no
error dialog. It found the empty menus above.

## my_wow's TBC client (`Code2/Wow/tools/my_wow/c/wow`, 2026-11-23)

Skada works on it with the same files. The fixes were in the client, not the addon (apart from the
TabGroup width above, which is right on the real client too). The client was missing these addon APIs:
`Region:SetParent` (AceGUI moves every widget into its window with it), `Frame:SetBackdrop(table)`,
the resize methods, `CreateFont`, `GetSpellLink`, `string.split`, font object and shadow methods,
blend mode / orientation methods, `EnableMouse()` / `GetCursorPosition(...)` argument forms,
`SetPoint` to an unnamed frame. It also lacked loose addon files (`.tga` / `.blp` textures, `.ttf`
fonts beside the MPQs), and it reset an addon's own metatable on a frame (LibBars' bar groups) every
time the frame was handed back to Lua. Tested the same way as the real client (the sweep, a real
fight, real mouse clicks on a bar): 0 Lua errors, and it looks like the real client.
