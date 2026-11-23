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
| `Modules/Tweaks.lua` | 2.4.3's chat filter signature (`filter(msg)` with the `event` / `arg2` globals). Fury of Frostmourne name fallback. |
| `Modules/Healthstone.lua` | Master Healthstone as the name to match (Fel Healthstone is 3.x). |
| `Locales/enUS.lua` | Fallbacks for global strings 2.4.3 lacks (`MINIMUM`, `MAXIMUM`, `CRIT_ABBR`, `APPLY`, `ENEMY`, ...). |
| `Libs/AceGUI-3.0/.../TabGroup.lua` | 2.4.3's `PanelTemplates_TabResize(padding, tab, ...)` argument order. |
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
