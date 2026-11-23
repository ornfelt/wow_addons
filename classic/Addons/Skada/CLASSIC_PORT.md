# Skada on the classic 1.12 client

This is the TBC port (`tbc/Addons/Skada`, see `TBC_PORT.md`) taken one step further back, to the
1.12.1 client (interface 11200). Same files, same design: `diff -r tbc/Addons/Skada classic/Addons/Skada`
shows the port. It replaces DPSMate: `classic/sync_addon.ps1` / `.sh` removes every `DPSMate*` dir
from the client when it syncs Skada (`-KeepReplaced` / `--keep-replaced` keeps them; the repo keeps
its DPSMate copies in `classic/Addons`).

## Why it is more than the TBC port

1.12 runs **Lua 5.0** and has **no combat log event**:

* Lua 5.0 has no `#`, `%`, `...` in function bodies, string methods (`s:format()`), hex numbers or
  long bracket levels, and lacks `select`, `string.match`, `table.wipe`, `unpack(t, i, j)` ... The
  code is rewritten by `classic/tools/lua51to50.py` (in place, same lines), the missing library comes
  from `Classic/Env.lua`.
* The combat log is text in the chat (`CHAT_MSG_COMBAT_*`, `CHAT_MSG_SPELL_*`), without GUIDs, unit
  flags or spell ids. `Classic/CombatLog.lua` turns it into 2.4.3's `COMBAT_LOG_EVENT_UNFILTERED`
  arguments, so `Core/Functions.lua` (with its TBC estimates) parses it unchanged.

## What changed

| Where | Change |
| --- | --- |
| every `.lua` | `lua51to50.py --env SkadaEnv`: `#x` -> `__len(x)`, `a % b` -> `__mod(a, b)`, `...` -> `unpack(arg)` (main chunk: `SkadaAddonArgs()`), `s:fn()` -> `string.fn(s)`, hex -> decimal, `[==[` strings / comments -> 5.0 forms, and `setfenv(1, SkadaEnv)` on line 1. |
| every `.xml` | 1.12 loads no `<Script file="dir\x.lua"/>` from a sub dir: such runs became `<Include>`s of generated `dir\Load_classic.xml` files (same tool). |
| `Classic/Env.lua` (new, first) | `SkadaEnv`, the environment of every Skada file: reads what it lacks from the globals and writes new names there (SavedVariables, slash commands), but what it holds stays private, so other vanilla addons (which tell the client version apart by globals such as `GetSpellInfo`) see nothing new. Holds: the 5.1 library, `loadstring` in the env (the libraries' generated dispatchers), `CreateFrame` whose frames call script handlers with `(self, ...)` (1.12 uses `this` / `arg1`) and have the 2.x methods / argument forms 1.12 lacks (`SetSize`, `SetPoint("CENTER")`, `SetText(nil)`, `GetFontString` ...), dropdown (`initialize`, `func`) / StaticPopup callback arguments, unit functions that take a group member's name (and 2.x-only unit ids such as `focus` read as a unit that does not exist), `OnSizeChanged` with the frame's size in UI units (1.12 passes fractions of the screen), `GetSpellInfo` from `SpellData.lua`, made-up GUIDs (players / pets / creatures by name; known bosses carry their real creature id), `UnitBuff` names from the tooltip, a private `LibStub`. Skada's errors never open the client's error dialog: the libraries' safecalls (`geterrorhandler`) and the frame scripts print each distinct error once to the chat (red "Skada error:") and keep it in `SkadaEnv.SkadaErrors`; other addons' errors are untouched. |
| `Classic/CombatLog.lua` (new) | The combat message formats of the client's GlobalStrings as patterns (any locale), matched per chat event family, trailers (absorbed / blocked / resisted / glancing / crushing) stripped; each message is sent to `Skada:ParseCombatLog` as the 2.4.3 event. Unit flags from the roster and the units seen as target / mouseover, totems owned by the shaman who cast them (`SPELL_SUMMON`), damage shields named by school, interrupts by the source's last spell. Widens the combat log ranges to 200 yd (as DPSMate does). |
| `Classic/SpellData.lua`, `Classic/BossData.lua` (generated) | `classic/tools/gen_classic_data.py`: every spell name of the 1.12 `Spell.dbc` with school, icon and ids (highest rank first), and boss name -> creature id from LibBossIDs. |
| `Compat.lua` | The TBC `Compat.lua` for 1.12, every value in `SkadaEnv` (`SkadaShim`); no Interface Options (the options open in their own window). |
| `Compat.xml` | + `OptionsFrameTabButtonTemplate` (2.4.3's audio options tab under that name). |
| `Core/Init.lua` | `StartWatching` / `StopWatching` start / stop `Classic/CombatLog.lua` instead of the combat log event. |
| `Locales/enUS.lua` | English fallbacks for the global strings 1.12 lacks. |
| `Libs/...` | Lua 5.0 fixes the tool cannot see: the dispatcher code strings (`SkadaChunkArgs()`, `unpack(arg)`), CallbackHandler's `arg` locals, a LibDeflate `repeat` local, LibCompress' generated `str:gsub`, AceConfigDialog indexing a string, AceGUI's ScrollFrame hiding widgets outside the view (1.12 does not clip child frames). Each marked `classic:`. |

Update from a newer TBC copy: copy `tbc/Addons/Skada` over, run `lua51to50.py Addons/Skada --env SkadaEnv`
(files with the `lua50: native` marker or already converted are skipped), redo the `classic:` edits.

## Limits (1.12 combat log)

* No GUIDs: units are told apart by name (two mobs of one name are one actor).
* Spells by name: the highest rank's id stands for every rank.
* No spell ids or casters of auras; buffs on others by tooltip name.
* Only what the client logs in range (200 yd set at start).
* No talent inspection in 1.12: specs / roles of others are unknown.
* Potions / Healthstone modules list TBC / WotLK items.

## Tested (2026-11-23, real 1.12.1 client on vmangos)

Loads without Lua errors and adds no globals that other addons could mistake for a newer client
(checked: `GetSpellInfo`, `select`, `string.match`, `wipe`, `UnitGUID`). Solo fights (frost mage
vs Winterspring mobs): every combat message matched, Damage / DPS / Activity, segments named after the
mob, the spell breakdown with icons and its tooltip, data kept over a logout, the options window
(tree, tabs, scrolling). An error sweep (every mode and its sub mode on a segment and the total, the
menus and a submenu, choosing a segment, the reset popup and its Cancel, the report window, all 31
options pages, reloads) gave 0 Lua errors in the whole client, and no error dialog on any screenshot. Not tested: healing (no healer character used), absorbs, groups, raids,
battlegrounds.

### benilla (2026-11-23)

[benilla](https://github.com/samwhosung/benilla), the 1.12 client in Rust, in all three builds the user
runs: plain (`main` a29fc1ae), gfx (`gfx-dll-backend` 2859c084, `--features gfx`) and trimmed
(`trimmed-bevy` 776606af). Its own Lua 5.0 and FrameXML engine runs Skada unchanged; two things
Skada met there were fixed in `Classic/Env.lua` (both also right on the real client): the bar
windows shrank to nothing through SpecializedLibBars' `SetLength`, fed `OnSizeChanged`'s `arg1` /
`arg2` (fractions of the screen - the real client passes the very same values at the same moments,
0.137885 for a 240 wide frame at a 0.9 UI scale, so benilla is faithful there; the handlers now get
the frame's own size), and an unknown unit id (`focus`) raises an error (fights were dropped). Each build: the same error sweep (0 Lua errors, every view drawn) and three real fights
(frost mage, Winterspring), Damage per segment as on the real client. benilla reads its addons from
`benilla-config/AddOns` (a worktree, such as the trimmed one, uses its primary checkout's; set
`$BENILLA_HOME` to choose); the headless check is benilla's addon harness
(`cargo build --profile play -p benilla-app --example addon_harness`, then
`addon_harness <classic/Addons> --probe Skada --event CHAT_MSG_SPELL_SELF_DAMAGE "Your Fireball hits Hogger for 500 Fire damage." --eval ...`).

### cenilla (2026-11-23)

cenilla, benilla's C port (4415c246, level with trimmed-bevy), exited as Skada loaded: its
read-fonts port refused (`bn_panic`) the Macintosh format 6 cmap subtable of Skada's Accidental
Presidency, Adventure and FORCED SQUARE fonts. Fixed in cenilla itself (a3c42074: cmap format 6
carried as read-fonts / harfrust read it, with read-fonts' test); then the same error sweep (0 Lua
errors) and three real fights, `OnSizeChanged` values as on the real client. Its addons live in
`cenilla-config/AddOns`.
