﻿-------------------------------------------------------------------------------------------------------------
--
-- TrinityAdmin Version 3.x
-- TrinityAdmin is a derivative of MangAdmin.
--
-- Copyright (C) 2018 Free Software Foundation, Inc.
-- License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
-- This is free software: you are free to change and redistribute it.
-- There is NO WARRANTY, to the extent permitted by law.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
--
-- Official Forums: http://groups.google.com/group/trinityadmin
-- GoogleCode Website: http://code.google.com/p/trinityadmin/
-- Subversion Repository: http://trinityadmin.googlecode.com/svn/
-- Dev Blog: http://trinityadmin.blogspot.com/
-------------------------------------------------------------------------------------------------------------
--[[
How to add a localised string:
1. Look below and find the functional area(Tab) your string belongs in.
2. In that section, find the appropriate type of string (Tooltip, Label, Other)
3. Each line is an assignment equation. On the left side is the 'token' which represents the string. The token is used
  in the source code, and is replaced by the actual string at runtime. The token is quoted, and contained in square brackets ([]).
  Eaxample: ["strength"]
4. Now assign a value to the token for the language you are working with. For example, if I am editing the enUS file, I want to
  assign the value, in US English, to the token:
  ["strength"] = "Strength",
  Please note the line is terminated with a comma (,).
5. A given token must exist in all supported languages. If we edit the deDE file, we would use:
  ["strength"] = "Stärke",
6. Some of these lines also contain color codes (example: |cFF00FF00 and |r) Don't alter these, please.

TrinityAdmin Locale Team:
You have received this file which currently contains enUS strings, but will actually be the file for your
selected language.
1. Edit the first un-commented line below, which should resemble: function Return_enUS(). Change
  the 'enUS' to the four letter code for your locale (example: deDE).
2. Proceed to localisation by examining each line in the file, and altering the US English strings on
  the RIGHT of each equation to your selected language. DO NOT alter anything on the LEFT sides
  (the tokens). Example: ["token_do_not_edit"] = "Edit this string to your language",
3. Some text includes color codes:     ["info_revision"] = "|cFF00FF00Trinity Revision:|r ",
  The Color code should NOT be localised/edited. The color code is a tag, with an opening element
  and a closing element. The opening element is "|c" followed by 8 numbers. The closing element
  is "|r". In the example above, "|cFF00FF00" and "|r" are the color code and should NOT be changed.
  That leaves "Trinity Revision:" as the string to edit in the above example.
4. Some strings may not be edited at all because they are used in code or contain code. They
  are marked.
5. Please do not edit comments. In LUA, the programming language we use here, code comments are seperated from code by the
  use of "" (makes anything AFTER it a comment, to the end of the line) or comments can be enclosed between.

If you have any questions, contact iotech.
]]--

function Return_enUS()
  return {
--[[General]]
  --[[Tooltips]]
    ["ma_IconHint"]                   = "|cffeda55fClick|r to open TrinityAdmin. |cffeda55fShift-Click|r to reload the user interface.",
    ["tt_Default"]                    = "Move your cursor over an element to toggle the tooltip!",
    ["tt_LanguageButton"]             = "Reload TrinityAdmin.", --Removed locals. Updated tooltip to just reload
  --[[Control Labels]]
    ["ma_LanguageButton"]             = "Change language",
    ["info_revision"]                 = "|cFF00FF00TrinityCore rev:|r ", --Updated: Matched string output to TrinityCore
    ["info_platform"]                 = "|cFF00FF00Server Platform:|r ",
    ["info_online"]                   = "|cFF00FF00Players Online:|r ",
    ["info_maxonline"]                = "|cFF00FF00Maximum Online:|r ",
    ["info_uptime"]                   = "|cFF00FF00Uptime:|r ",
    ["ma_CloseWindow"]                = "X",
    ["tt_CloseWindow"]                = "Close TrinityAdmin",
  --[[Other]]
    ["slashcmds"]                     = { "/trinityadmin", "/ta" },
    ["lang"]                          = "English",
    ["realm"]                         = "|cFF00FF00Realm:|r "..GetCVar("realmName"), --do not change this line!
    ["char"]                          = "|cFF00FF00Char:|r "..UnitName("player"), --do not change this line!
    ["guid"]                          = "|cFF00FF00Guid:|r ",
    ["tickets"]                       = "|cFF00FF00Tickets:|r ",
    ["selectionerror1"]               = "Please select only yourself, another player or nothing!",
    ["selectionerror2"]               = "Please select only yourself or nothing!",
    ["selectionerror3"]               = "Please select only another player!",
    ["selectionerror4"]               = "Please select only a NPC!",
    ["searchResults"]                 = "|cFF00FF00Search-Results:|r ",
    ["ma_parameters"]                 = "Parameter(s):", --Used on multiple tabs



--[[GM tab]]
  --[[Name]]
    ["tabmenu_Main"]                  = "GM",
  --[[Tooltips]]
    ["tt_MainButton"]                 = "Toggle TrinityAdmins Mainframe.",
    ["tt_DisplayAccountLevel"]        = "Display your account level",
    ["tt_GMOnButton"]                 = "Activate your GM-mode.",
    ["tt_GMOffButton"]                = "Deactivate your GM-mode.",
    ["tt_FlyOnButton"]                = "Activate the Fly-mode for the selected character.",
    ["tt_FlyOffButton"]               = "Deactivate the Fly-mode for the selected character.",
    ["tt_HoverOnButton"]              = "Activate your Hover-mode.",
    ["tt_HoverOffButton"]             = "Deactivate your Hover-mode.",
    ["tt_WhispOnButton"]              = "Accept whispers from other players.",
    ["tt_WhispOffButton"]             = "Do not accept whispers from other players.",
    ["tt_InvisOnButton"]              = "Make you invisible.",
    ["tt_InvisOffButton"]             = "Make you visible.",
    ["tt_TaxiOnButton"]               = "Show all taxi-routes to the selected player. This cheat will be deactivated on logout.",
    ["tt_TaxiOffButton"]              = "Deactivate the taxi-cheat and restore the players known taxi-routes.",
    ["tt_ShowMapsButton"]             = "Reveals maps for the selected character.",
    ["tt_HideMapsButton"]             = "Hides maps for the selected character.",
    ["tt_SpeedSlider"]                = "Increase or decrease the speed for the selected character.",
    ["tt_ScaleSlider"]                = "Increase or decrease the scale for the selected character.",
    ["tt_instakill"]                  = "When checked, clicking an enemy creature kills it.",
    ["tt_ScreenButton"]               = "Make a screenshot.",
    ["tt_BankButton"]                 = "Show your bank.",
    ["tt_Dismount"]                   = "Dismounts you, if you are mounted",
    ["tt_SetJail_A_Button"]           = "Sets the location of the Alliance Jail to your current location.",
    ["tt_SetJail_H_Button"]           = "Sets the location of the Horde Jail to your current location.",
    ["tt_N"]                          = "Navigate North",
    ["tt_S"]                          = "Navigate South",
    ["tt_E"]                          = "Navigate East",
    ["tt_W"]                          = "Navigate West",
  --["tt_chatonbutton"]               = "Turn GM Chat ON",
  --["tt_chatoffbutton"]              = "Turn GM Chat OFF",
    ["tt_waterwalkonbutton"]          = "Turn Waterwalk ON for the selected creature"  ,
    ["tt_watewrwalkoffbutton"]        = "Turn Waterwalk OFF for the selected creature",
    ["tt_accountlockonbutton"]        = "Lock your account",
    ["tt_accountlockoffbutton"]       = "UnLock your account",
    ["tt_DisplayAccountLvl"]          = "Display your account level.",
    ["tt_SpeedSliderReset"]           = "Reset Speed to 1.0",
    ["tt_ScaleSliderReset"]           = "Reset Scale to 1.0",
    ["tt_gmnotifybutton"]             = "Sends message $message to all online GMs [[Parameters: $message]]",
    ["tt_gmingamebutton"]             = "Shows GMs who are logged in.",
    ["tt_gmlistbutton"]               = "Shows the GM accounts on this server",
    ["tt_petcreatebutton"]            = "Makes the selected ANIMAL your pet.",
    ["tt_petlearnbutton"]             = "Teaches your pet spell [[Parameter: #SPELLID]]",
    ["tt_petunlearnbutton"]           = "Un-Teaches your pet spell [[Parameter: #SPELLID]]",
    ["tt_pettpbutton"]                = "Modifies pet's training points [[Parameter: #points]]",
    ["tt_lookuptaxibutton"]           = "Lookup a TaxiNode [[Parameter: $Areanamepart]]",
    ["tt_gotaxinodebutton"]           = "Teleports to given TaxiNode [[Parameter: #taxinode]]",
    ["tt_gotriggerbutton"]            = "Teleports to given area trigger [[Parameter: #trigger_id]]",
    ["tt_goxybutton"]                 = "Teleports to given coordinates at ground/water level on MapID. If MapID omitted, current map [[Parameters: #x #y [#mapid]]]",
    ["tt_goxyzbutton"]                = "Teleports to given coordinates at #z level on MapID. If MapID omitted, current map [[Parameters: #x #y #z [#mapid]]]",
    ["tt_gozonexybutton"]             = "Teleports to given coordinates at ground/water level in ZoneID. If ZoneID omitted, current zone [[Parameters: #x #y [#zoneid]]]",
    ["tt_lookupzonebutton"]           = "Lookup a Zone. [[Parameters: $Areanamepart]]",
    ["tt_castbutton"]                 = "Cast a spell. [[Parameters: #SpellID]]",
    ["tt_castbackbutton"]             = "Selected creature will cast spell [SpellID] at YOU. [[Parameters: #SpellID]]",
    ["tt_castdistbutton"]             = "You cast a spell [SpellID] at distance [#Dist]. [[Parameters: #SpellID #Dist]]",
    ["tt_castselfbutton"]             = "Selected creature casts spell [SpellID] at itself. [[Parameters: #SpellID]]",
    ["tt_casttargetbutton"]           = "Selected creature casts spell [SpellID] at it's target. [[Parameters: #SpellID]]",
    ["tt_gmclearbutton"]              = "Clears the parameter box.",
    ["tt_listitembutton"]             = "Lists all occurences of [#itemID]. [[Parameters: #ItemID]]",
    ["tt_acctcreatebutton"]           = "Creates a player account [[Parameters: $accountname $password]]",
    ["tt_acctdeletebutton"]           = "Deletes a player account and all characters [[Parameters: $accountname]]",
    ["tt_acctaddonbutton"]            = "Sets $account to use #addon(0=WoW, 1=TBC, 2=WotLK) [[Parameters: $accountname #addon]]",
    ["tt_acctgmlvlbutton"]            = "Sets $account to #gmlevel (0=Player, 1=Helper, 2=Assistant, 3=GM, 4=Admin) [[Parameters: $accountname #gmlevel]]",
    ["tt_acctpasswdbutton"]           = "Sets $account $password [[Parameters: $accountname $password $password]]",
  --[[Control Labels]]
    ["ma_OffButton"]                  = "Off",
    ["ma_displaylevelbutton"]         = "Display Account Level",
    ["ma_GMOnButton"]                 = "GM-mode on",
    ["ma_FlyOnButton"]                = "Fly-mode on",
    ["ma_HoverOnButton"]              = "Hover-mode on",
    ["ma_WhisperOnButton"]            = "Whisper on",
    ["ma_InvisOnButton"]              = "Invisibility on",
    ["ma_TaxiOnButton"]               = "Taxicheat on",
    ["ma_ShowMapsButton"]             = "Show Maps",
    ["ma_HideMapsButton"]             = "Hide Maps",
    ["ma_instakill"]                  = "Insta-kill enemy creatures",
    ["ma_ScreenshotButton"]           = "Screenshot",
    ["ma_BankButton"]                 = "Bank",
    ["ma_DismountButton"]             = "Dismount",
    ["ma_SetJail_A_Button"]           = "SetJail A",
    ["ma_SetJail_H_Button"]           = "SetJail H",
    ["gridnavigator"]                 = "Grid-Navigator",
    ["N"]                             = "N", --Abbreviation for North
    ["S"]                             = "S", --Abbreviation for South
    ["E"]                             = "E", --Abbreviation for East
    ["W"]                             = "W", --Abbreviation for West
    ["ma_chatbutton"]                 = "GM Chat On",
    ["ma_mapsbutton"]                 = "View All Maps",
    ["ma_waterwalkbutton"]            = "Waterwalk On",
    ["ma_accountlockbutton"]          = "Account Lock",
    ["ma_gmnotify"]                   = "GM Notify",
    ["ma_gmingame"]                   = "GMs InGame",
    ["ma_gmlist"]                     = "GM List",
    ["ma_petcreate"]                  = "Pet Create",
    ["ma_petlearn"]                   = "Pet Learn",
    ["ma_petunlearn"]                 = "Pet UnLearn",
    ["ma_pettp"]                      = "Pet TP",
    ["ma_lookuptaxi"]                 = "Lookup Taxi",
    ["ma_gotaxinode"]                 = "Go TaxiNode",
    ["ma_gotrigger"]                  = "Go Trigger",
    ["ma_goxy"]                       = "Go XY",
    ["ma_goxyz"]                      = "Go XYZ",
    ["ma_gozonexy"]                   = "Go ZoneXY",
    ["ma_lookupzone"]                 = "Lookup Zone",
    ["ma_cast"]                       = "Cast",
    ["ma_castback"]                   = "Cast Back",
    ["ma_castdist"]                   = "Cast Dist",
    ["ma_castself"]                   = "Cast Self",
    ["ma_casttarget"]                 = "Cast Target",
    ["ma_listitem"]                   = "List Item",
    ["ma_GmClear"]                    = "Clear Params",
    ["ma_acctcreate"]                 = "Acct Create",
    ["ma_acctdelete"]                 = "Acct Delete",
    ["ma_acctaddon"]                  = "Acct Addon",
    ["ma_acctgmlvl"]                  = "Acct GMLvl",
    ["ma_acctpasswd"]                 = "Acct Passwd",
  --[[Other]]



--[[Char Tab]]
  --[[Name]]
    ["tabmenu_Char"]                  = "CHAR",
    ["tt_CharButton"]                 = "Toggle a window with character-specific actions.",
  --[[Tooltips]]
    ["tt_RotateLeft"]                 = "Rotate left.",
    ["tt_RotateRight"]                = "Rotate right.",
    ["tt_killbutton"]                 = "Kills selected creature/player",
    ["tt_reviveplayer"]               = "Revives the selected player",
    ["tt_saveplayer"]                 = "Saves the selected player's character",
    ["tt_KickButton"]                 = "Kick the selected player from the server.",
    ["tt_CooldownButton"]             = "Removes/expires all spell affect cooldowns on the selected character.",
    ["tt_GUIDButton"]                 = "Shows the GUID of the selected character.",
    ["tt_PinfoButton"]                = "Get information on the selected PLAYER.",
    ["tt_DistanceButton"]             = "Get distance to the selected creature.",
    ["tt_RecallButton"]               = "Recalls selected creature to location before last teleport.",
    ["tt_DemorphButton"]              = "Removes any morphs on the selected character.",
    ["tt_ShowMapsCharButton"]         = "Reveals maps for the selected character.",
    ["tt_HideMapsCharButton"]         = "Hides maps for the selected character.",
    ["tt_learnlangbutton"]            = "Learn selected langauge(s)",
    ["tt_modifybutton"]               = "Modify the selected attribute by the entered amount",
    ["tt_resetbutton"]                = "Reset the selected attribute",
    ["tt_modelzoominbutton"]          = "Zoom in the selected model",
    ["tt_modelzoomoutbutton"]         = "Zoom out the selected model",
    ["tt_charbindsight"]              = "Binds your vision to the selected Unit",
    ["tt_charunbindsight"]            = "UnBinds your vision to the selected Unit (BROKEN in CORE - right-click gear icon in buffs area)",
    ["tt_charrename"]                 = "Toggles selected character for rename at next login",
    ["tt_charcustomize"]              = "Toggles selected character for customization at next login",
    ["tt_charchangerace"]             = "Toggles selected character for race change at next login",
    ["tt_charchnagefaction"]          = "Toggles selected character for faction change at next login",
    ["tt_charcombatstop"]             = "Stops combat for the selected character (or yourself)",
    ["tt_charmaxskill"]               = "Sets the selected characters skills to max value for level",
    ["tt_charfreeze"]                 = "Freezes targeted player and disables their chat",
    ["tt_charunfreeze"]               = "UnFreezes selected player and restores chat",
    ["tt_charlistfreeze"]             = "Lists frozen players in chat window",
    ["tt_charpossess"]                = "Indefinitely possesses the selected creature",
    ["tt_charunpossess"]              = "Unpossesses the selected creature",
    ["tt_charrecall"]                 = "Recalls the selected player to the last teleport position they had",
    ["tt_charrepair"]                 = "Repairs the selected player's armor and weapons",
    ["tt_banbutton"]                  = "Parameters= <account|ip|character> $NameOrIp <-1|xxdyyhzzm> $reason   [[Ban acct/IP & kick. -1=permban, or a string like 4d3h24m16s]]",
    ["tt_gonamebutton"]               = "Parameter= $charactername  [[Teleports you to the specified character]]",
    ["tt_createguildbutton"]          = "Parameters= $GuildLeaderName $GuildName  [[Creates a guild named $GuildName, with $GuildLeaderName as leader]]",
    ["tt_teleaddbutton"]              = "Parameter= $Name  [[Adds a teleport location .tele command for your current location with the name $Name]]",
    ["tt_baninfobutton"]              = "Parameter= <account|ip|character>  [[View detailed info about bans on the specified account/ip/character]]",
    ["tt_groupgobutton"]              = "Parameter= $charactername   [[Teleports the specified character and his/her group to your location]]",
    ["tt_guildinvitebutton"]          = "Parameters= $charactername $guildname   [[Adds $charactername to the guild $guildname]]",
    ["tt_teledelbutton"]              = "Parameter= $telename  [[Removes the location named $telename from the .tele locations list]]",
    ["tt_banlistbutton"]              = "Parameters= <account|ip> $NameOrIp   [[Searches and returns for specific bans matching the parameters]]",
    ["tt_namegobutton"]               = "Parameter= $charactername   [[Teleports the specified character to your location]]",
    ["tt_guildrankbutton"]            = "Parameters= $charactername #ranknumber   [[Sets the character specified to the rank specified in his/her guild]]",
    ["tt_telegroupbutton"]            = "Parameter= $telename  [[Teleports the **selected** character and his/her group to the .tele location named $telename]]",
    ["tt_unbanbutton"]                = "Parameters= <account|ip|character> $NameOrIp  [[Unbans the specified acct/IP/character]]",
    ["tt_guilddeletebutton"]          = "Parameter= $guildname  [[Deletes the specified Guild]]",
    ["tt_guilduninvitebutton"]        = "Parameter= $charactername  [[Kicks the specified character out of his/her guild]]",
    ["tt_telenamebutton"]             = "Parameters= $charactername $telename  [[Teleports $charactername to $telename]]",
    ["tt_mutebutton"]                 = "Parameters= $charactername #minutes  [[Disables chat for $charactername's entire account for #minutes]]",
    ["tt_charmorphbutton"]            = "Parameters = #DisplayID [[Enter the DisplayID of the morph you want to apply]]",
    ["tt_charaurabutton"]             = "Parameters = #AuraID [[Enter the AuraID of the aura you want to apply]]",
    ["tt_charunaurabutton"]           = "Parameters = #AuraID [[Enter the AuraID of the aura you want to remove]]",
    ["tt_JailAButton"]                = "Parameter= $charactername [[Sends the selected character to the Alliance Jail]]",
    ["tt_JailHButton"]                = "Parameter= $charactername [[Sends the selected character to the Horde Jail]]",
    ["tt_UnJailButton"]               = "Parameter= $charactername [[Unjails the character whose name appears in this box.]]",
    ["tt_UnMuteButton"]               = "Unmutes $player.",
    ["tt_QuestAddButton"]             = "Adds #questid to **selected** player.",
    ["tt_QuestCompleteButton"]        = "Marks #questid as complete for **selected** player.",
    ["tt_QuestRemoveButton"]          = "Removes #questid from **selected** player.",
    ["tt_DamageButton"]               = "Parameter= #amount of damage to apply to **selected** creature/player",
    ["tt_HideAreaButton"]             = "Hides #areaid from **selected** player.",
    ["tt_ShowAreaButton"]             = "Shows #areaid to **selected** player.",
    ["tt_HonorAddButton"]             = "Adds #honorpoints to **selected** player.",
    ["tt_HonorUpdateButton"]          = "No parameter required. Saves Honor for **selected** player.",
  --[[Control Labels]]
    ["ma_KillButton"]                 = "Kill",
    ["ma_ReviveButton"]               = "Revive",
    ["ma_SaveButton"]                 = "Save",
    ["ma_KickButton"]                 = "Kick",
    ["ma_CooldownButton"]             = "Cooldown",
    ["ma_GUIDButton"]                 = "Show GUID",
    ["ma_PinfoButton"]                = "PLAYER Info",
    ["ma_DistanceButton"]             = "Distance",
    ["ma_RecallButton"]               = "Recall",
    ["ma_DemorphButton"]              = "Demorph",
    ["ma_ShowMapsCharButton"]         = "Show Maps",
    ["ma_HideMapsCharButton"]         = "Hide Maps",
    ["ma_LearnLangButton"]            = "All languages",
    ["ma_Learn"]                      = "Learn",
    ["ma_Modify"]                     = "Modify",
    ["ma_Reset"]                      = "Reset",
    ["ma_CharBindsight"]              = "Bindsight",
    ["ma_CharUnBindsight"]            = "UnBindsight",
    ["ma_charrename"]                 = "Rename",
    ["ma_charcustomize"]              = "Customize",
    ["ma_charchangerace"]             = "Chng Race",
    ["ma_charchnagefaction"]          = "Chng Faction",
    ["ma_charcombatstop"]             = "CombatStop",
    ["ma_charmaxskill"]               = "MaxSkill",
    ["ma_charfreeze"]                 = "Freeze",
    ["ma_charunfreeze"]               = "UnFreeze",
    ["ma_charlistfreeze"]             = "ListFreeze",
    ["ma_charpossess"]                = "Possess",
    ["ma_charunpossess"]              = "UnPossess",
    ["ma_charrecall"]                 = "Recall",
    ["ma_charrepair"]                 = "Repair",
    ["ma_banbutton"]                  = "Ban",
    ["ma_gonamebutton"]               = "Appear",
    ["ma_createguildbutton"]          = "G Create",
    ["ma_teleaddbutton"]              = "TeleAdd",
    ["ma_baninfobutton"]              = "BanInfo",
    ["ma_groupgobutton"]              = "GroupSumn",
    ["ma_guildinvitebutton"]          = "G Invite",
    ["ma_teledelbutton"]              = "TeleDel",
    ["ma_banlistbutton"]              = "BanList",
    ["ma_namegobutton"]               = "Summon",
    ["ma_guildrankbutton"]            = "G Rank",
    ["ma_telegroupbutton"]            = "TeleGroup",
    ["ma_unbanbutton"]                = "UnBan",
    ["ma_guilddeletebutton"]          = "G Delete",
    ["ma_guilduninvitebutton"]        = "G UnInv",
    ["ma_telenamebutton"]             = "TeleName",
    ["ma_mutebutton"]                 = "Mute",
    ["ma_Aura"]                       = "Aura",
    ["ma_UnAura"]                     = "UnAura",
    ["ma_Morph"]                      = "Morph",
    ["ma_JailAButton"]                = "Jail (A)",
    ["ma_JailHButton"]                = "Jail (H)",
    ["ma_UnJailButton"]               = "UnJail",
    ["ma_UnMuteButton"]               = "UnMute",
    ["ma_QuestAddButton"]             = "QuestAdd",
    ["ma_QuestCompleteButton"]        = "QuestCompl",
    ["ma_QuestRemoveButton"]          = "QuestRem",
    ["ma_DamageButton"]               = "Damage",
    ["ma_HideAreaButton"]             = "HideArea",
    ["ma_ShowAreaButton"]             = "ShowArea",
    ["ma_HonorAddButton"]             = "HonorAdd",
    ["ma_HonorUpdateButton"]          = "HonorUpdt",
  --[[Other]]
    ["ma_LevelUp"]                    = "Level up",
    ["ma_LevelDown"]                  = "Level down",
    ["ma_Money"]                      = "Money",
    ["ma_Energy"]                     = "Energy",
    ["ma_Rage"]                       = "Rage",
    ["ma_Mana"]                       = "Mana",
    ["ma_Healthpoints"]               = "Healthpoints",
    ["ma_Talents"]                    = "Talents",
    ["ma_Stats"]                      = "Stats",
    ["ma_Spells"]                     = "Spells",
    ["ma_Honor"]                      = "Honor",
    ["ma_Level"]                      = "Level",
    ["ma_AllLang"]                    = "All Languages",
    ["ma_resetallspells"]             = "Spells for ALL",
    ["ma_resetalltalents"]            = "Talents for ALL",
    ["ma_achievements"]               = "Achievements",
    ["ma_AllSpeeds"]                  = "AllSpeeds",
    ["ma_Arena"]                      = "Arena",
    ["ma_BackWalk"]                   = "BackWalk",
    ["ma_Drunk"]                      = "Drunk",
    ["ma_FlySpeed"]                   = "FlySpeed",
    ["ma_Gender"]                     = "Gender",
    ["ma_Honor"]                      = "Honor",
    ["ma_MountSpeed"]                 = "MountSpeed",
    ["ma_Phase"]                      = "Phase",
    ["ma_RunicPower"]                 = "RunicPower",
    ["ma_Speed"]                      = "Speed",
    ["ma_StandSate"]                  = "StandState",
    ["ma_SwimSpeed"]                  = "SwimSpeed",
    ["ma_TalentPoints"]               = "TalentPoints",
    -- languages
    ["Common"]                        = "Common",
    ["Orcish"]                        = "Orcish",
    ["Taurahe"]                       = "Taurahe",
    ["Darnassian"]                    = "Darnassian",
    ["Dwarvish"]                      = "Dwarvish",
    ["Thalassian"]                    = "Thalassian",
    ["Demonic"]                       = "Demonic",
    ["Draconic"]                      = "Draconic",
    ["Titan"]                         = "Titan",
    ["Kalimag"]                       = "Kalimag",
    ["Gnomish"]                       = "Gnomish",
    ["Troll"]                         = "Troll",
    ["Gutterspeak"]                   = "Gutterspeak",
    ["Draenei"]                       = "Draenei",



--[[NPC Tab]]
  --[[Name]]
    ["tabmenu_NPC"]                   = "NPC",
    ["tt_NpcButton"]                  = "Toggle a window with npc related functions.",
  --[[Tooltips]]
    ["tt_NPCRotateLeft"]              = "Rotate left",
    ["tt_NPCRotateRight"]             = "Rotate right",
    ["tt_NPCKillButton"]              = "Kills the selected target",
    ["tt_npcrespawn"]                 = "Respawns selected creasture, or if none selected, all nearby creatures",
    ["tt_NPCDistanceButton"]          = "Get distance to the selected creature.",
    ["tt_NPCGUIDButton"]              = "Shows the GUID of the selected character.",
    ["tt_NPCInfoButton"]              = "Get information on the selected NPC.",
    ["tt_NPCDemorph"]                 = "Demorphs selected NPC",
    ["tt_NPCMove"]                    = "Move the selected creature to your location",
    ["tt_NPCDel"]                     = "Deletes the selected creature",
    ["tt_getguid"]                    = "Gets the selected creatures GUID and ID",
    ["tt_NPCAdd"]                     = "Adds a copy of this NPC at your current location.",
    ["tt_NPCGo"]                      = "Teleports you to the NPC in the GUID box",
    ["tt_NPCMorph"]                   = "Parameters = #DisplayID [[Enter the DisplayID of the morph you want to apply]]",
    ["tt_NPCSay"]                     = "Make selected npc say [parameters]",
    ["tt_NPCYell"]                    = "Make selected npc yell [parameters]",
    ["tt_NPCAura"]                    = "Parameters = #AuraID [[Enter the AuraID of the aura you want to apply]]",
    ["tt_NPCUnaura"]                  = "Parameters = #AuraID [[Enter the AuraID of the aura you want to remove]]",
    ["tt_PlayEmote"]                  = "Play Emote from list at left",
    ["tt_GPSButton"]                  = "Shows coordinates for the selected character.",
    ["tt_DisplayUp"]                  = "Increment NPC DisplayID UP by 1",
    ["tt_DisplayDown"]                = "Decrement NPC DisplayID DOWN by 1",
    ["tt_IDUp"]                       = "Increment NPC ID UP by 1",
    ["tt_IDDown"]                     = "Decrement NPC ID DOWN by 1",
    ["tt_npcmodelzoominbutton"]       = "Zoom in the selected model",
    ["tt_npcmodelzoomoutbutton"]      = "Zoom out the selected model",
    ["tt_npcbindsight"]               = "Binds your vision to the selected NPC",
    ["tt_npcunbindsight"]             = "UnBinds your vision to the selected NPC (BROKEN in CORE - right-click gear icon in buffs area)",
    ["tt_npccometome"]                = "Forces the selected NPC to come to your location. Location NOT stored in DB.",
    ["tt_npcpossess"]                 = "Indefinitely possesses the selected creature",
    ["tt_npcunpossess"]               = "Unpossesses the selected creature",
    ["tt_NPCFreezeButton"]            = "Stops movement of the selected NPC, saving Waypoints",
    ["tt_NPCFreezeDelButton"]         = "Stops movement of the selected NPC, NOT saving Waypoints",
    ["tt_WayEndAdd"]                  = "Adds a waypoint to the end of the existing stack",
    ["tt_NPCAddWay"]                  = "Adds a waypoint to the stack. Creature GUID must be in below box",
    ["tt_WayMAdd"]                    = "Adds a waypoint to selected creatures existing move stack",
    ["tt_WayModifyDel"]               = "Deletes the selected waypoint from creatures existing move stack",
    ["tt_WayShow0"]                   = "Stops showing waypoints for selected creature.",
    ["tt_WayShow1"]                   = "Show waypoints for selected creature.",
    ["tt_NPCAdd_WayShowOn"]           = "shows waypoints for the selected creature",
    ["tt_NPCUnFreeze_RandomButton"]   = "Allows random movement of the selected NPC.",
    ["tt_NPCUnFreeze_WayButton"]      = "Allows waypoint movement of the selected NPC.",
    ["tt_MoveStackButton"]            = "Shows movement stack of the selected character.",
  --[[Control Labels]]
    ["Morph"]                         = "Morph",
    ["ma_NPCKillButton"]              = "Kill",
    ["ma_Respawn"]                    = "Respawn",
    ["ma_NPCDistanceButton"]          = "Distance",
    ["ma_NPCGUIDButton"]              = "Show GUID",
    ["ma_NPCInfoButton"]              = "NPC Info",
    ["ma_NPCDemorph"]                 = "Demorph",
    ["ma_NPCMove"]                    = "NPC Move",
    ["ma_NPCDel"]                     = "NPC Del",
    ["ma_getguid"]                    = "Get GUID",
    ["ma_NPCAdd"]                     = "NPC Add",
    ["ma_NPCGo"]                      = "NPC Go",
    ["ma_NPCMorph"]                   = "Morph",
    ["ma_NPCSay"]                     = "NPC Say",
    ["ma_NPCYell"]                    = "NPC Yell",
    ["ma_NPCAura"]                    = "NPC Aura",
    ["ma_NPCUnAura"]                  = "NPC Unaura",
    ["ma_ParameterBoxText"]           = "Params:",
    ["ma_PlayEmote1"]                 = "Emote",
    ["ma_PlayEmote2"]                 = "Emote",
    ["ma_DistanceBox"]                = "Distance",
    ["ma_NPCBindsight"]               = "Bindsight",
    ["ma_NPCUnBindsight"]             = "UnBindsight",
    ["ma_NPCComeToMe"]                = "ComeToMe",
    ["ma_npcpossess"]                 = "Possess",
    ["ma_npcunpossess"]               = "UnPossess",
    ["ma_WayShow1"]                   = "WayShowOn",
    ["ma_WayShow0"]                   = "WayShowOff",
    ["ma_MoveStackButton"]            = "Show Moves",
    ["ma_NPCFreezeButton"]            = "NPCStay",
    ["ma_WayAllDel"]                  = "NPCStayDel",
    ["ma_WayMAdd"]                    = "WayMAdd",
    ["ma_NPCUnFreeze_RandomButton"]   = "Mov Random",
    ["ma_NPCUnFreeze_WayButton"]      = "Mov Waypt",
    ["ma_WayMDel"]                    = "WayMDel",
    ["ma_WayEndAdd"]                  = "WayEndAdd",
    ["ma_WayAdd"]                     = "WayAdd",
    ["ma_WayShow"]                    = "WayShow",
  --[[Other]]



--[[GObjects Tab]]
  --[[Name]]
    ["tabmenu_GO"]                    = "GOB",
    ["tt_GOButton"]                   = "Toggle a window with GObject functions.",
  --[[Tooltips]]
    ["tt_ObjGo"]                      = "Go to the selected object",
    ["tt_ObjAdd"]                     = "Add a copy of the targeted object at your location and orientation",
    ["tt_ObjMove"]                    = "Move the targeted object to your location",
    ["tt_ObjTurn"]                    = "Turns the targeted object to mathc your orientation",
    ["tt_ObjDel"]                     = "Deletes the targeted object",
    ["tt_ObjNear"]                    = "Returns info on objects near you",
    ["tt_ObjTarget"]                  = "Targets the nearest object",
    ["tt_ObjActivate"]                = "Activates the targeted object",
    ["tt_ObjAddTemp"]                 = "Adds a temporary copy of the object",
    ["tt_ObjInfo"]                    = "Gets extended info about the object",
    ["tt_ObjSetPhase"]                = "Sets the phase of the object",
  --[[Control Labels]]
    ["ma_OBJGo"]                      = "Obj Go",
    ["ma_OBJAdd"]                     = "Obj Add",
    ["ma_OBJMove"]                    = "Obj Move",
    ["ma_OBJTurn"]                    = "Obj Turn",
    ["ma_OBJDel"]                     = "Obj Del",
    ["ma_OBJNear"]                    = "Obj Near",
    ["ma_OBJTarget"]                  = "Obj Target",
    ["ma_OBJActivate"]                = "Obj Activate",
    ["ma_OBJAddTemp"]                 = "Obj Add Tmp",
    ["ma_OBJInfo"]                    = "Obj Info",
    ["ma_OBJSetPhase"]                = "Obj Phase",
  --[[Other]]



--[[Tele Tab]]
  --[[Name]]
    ["tabmenu_Tele"]                  = "TELE",
    ["tt_TeleButton"]                 = "Toggle a window with teleport-functions.",
  --[[Tooltips]]
  --[[Control Labels]]
    ["Zone"]                          = "|cFF00FF00Zone:|r ",
  --[[Other]]
    ["ma_NoZones"]                    = "No zones!",
    ["ma_NoSubZones"]                 = "No subzones!",



--[[Tickets Tab]]
  --[[Name]]
    ["tabmenu_ticket"]                = "TICKETS",
    ["tt_TicketButton"]               = "Toggle a window which shows all tickets and lets you administrate them.",
  --[[Tooltips]]
  --[[Control Labels]]
    ["ma_LoadTicketsButton"]          = "Refresh",
    ["ma_GetCharTicketButton"]        = "Summon",
    ["ma_GoCharTicketButton"]         = "Go Player",
    ["ma_AnswerButton"]               = "Mail",
    ["ma_DeleteButton"]               = "Close",
    ["ma_TicketCount"]                = "|cFF00FF00Tickets:|r ",
    ["ma_TicketsNoNew"]               = "You have no new tickets.",
    ["ma_TicketsNewNumber"]           = "You have |cffeda55f%s|r new tickets!",
    ["ma_TicketsGoLast"]              = "Go to last ticket creator (%s).",
    ["ma_TicketsGetLast"]             = "Bring %s to you.",
    ["ma_TicketsInfoPlayer"]          = "|cFF00FF00Player:|r ",
    ["ma_TicketsInfoStatus"]          = "|cFF00FF00Status:|r ",
    ["ma_TicketsInfoAccount"]         = "|cFF00FF00Account:|r ",
    ["ma_TicketsInfoAccLevel"]        = "|cFF00FF00Account-Level:|r ",
    ["ma_TicketsInfoLastIP"]          = "|cFF00FF00Last IP:|r ",
    ["ma_TicketsInfoPlayedTime"]      = "|cFF00FF00Played time:|r ",
    ["ma_TicketsInfoLevel"]           = "|cFF00FF00Level:|r ",
    ["ma_TicketsInfoMoney"]           = "|cFF00FF00Money:|r ",
    ["ma_TicketsInfoLatency"]         = "|cFF00FF00Latency:|r ",
    ["ma_TicketsNoInfo"]              = "No info available",
    ["ma_TicketsNotLoaded"]           = "No ticket loaded...",
    ["ma_TicketsNoTickets"]           = "No tickets available!",
    ["ma_TicketTicketLoaded"]         = "|cFF00FF00Loaded Ticket-Nr:|r %s\n\nPlayer Information\n\n",
    ["ma_Reload"]                     = "Reload",
    ["ma_LoadMore"]                   = "Load more...",
    ["tt_TicketOn"]                   = "Announce new tickets.",
    ["tt_TicketOff"]                  = "Don't announce new tickets.",
  --[[Other]]



--[[Misc Tab]]
  --[[Name]]
    ["tabmenu_Misc"]                  = "MISC",
    ["tt_MiscButton"]                 = "Toggle a window with miscellaneous actions.",
  --[[Tooltips]]
    ["tt_FrmTrSlider"]                = "Change frame transparency.",
    ["tt_BtnTrSlider"]                = "Change button transparency.",
    ["tt_windowismovable"]            = "Allow a movable window",
  --[[Control Labels]]
    ["cmd_toggle"]                    = "Toggle the main window",
    ["cmd_transparency"]              = "Toggle the basic transparency (0.5 or 1.0)",
    ["cmd_tooltip"]                   = "Toggle wether the button tooltips are shown or not",
  --[[Other]]
    ["ma_WeatherFine"]                = "Fine",
    ["ma_WeatherFog"]                 = "Fog",
    ["ma_WeatherRain"]                = "Rain",
    ["ma_WeatherSnow"]                = "Snow",
    ["ma_WeatherSand"]                = "Sand",



--[[Server Tab]]
    ["tabmenu_server"]                = "SERVER",
    ["tt_ServerButton"]               = "Show several server informations and do actions concerning the server.",
  --[[Tooltips]]
    ["tt_AnnounceButton"]             = "Announce a system message.",
    ["tt_ShutdownButton"]             = "Shut down the server in the amount of seconds from the field, if omitted shut down immediately!",
  --[[Control Labels]]
    ["ma_AnnounceButton"]             = "Announce",
    ["ma_ShutdownButton"]             = "Server Shutdown!",
  --[[Other]]



--[[Log Tab]]
    ["tabmenu_log"]                   = "LOG",
    ["tt_LogButton"]                  = "Show the log of all actions done with TrinityAdmin.",
  --[[Tooltips]]
  --[[Control Labels]]
  --[[Other]]



--[[Who Tab]]
    ["tabmenu_who"]                   = "WHO",
    ["tt_whotabmenubutton"]           = "Toggle a window which allows control of Who commands.",
  --[[Tooltips]]
    ["tt_who_customize"]              = "Flag character for customization at next login.",
    ["tt_who_chardelete"]             = "CAUTION! Deletes the selected character. CAUTION!",
    ["tt_who_charrename"]             = "Flags selected character for rename at next login.",
    ["tt_who_permbanbutton"]          = "Bans the selected character's account PERMANENTLY",
    ["tt_who_1daybanbutton"]          = "Bans the selected character's account for 1 day",
    ["tt_who_jailabutton"]            = "Jails the character in the Alliance Jail",
    ["tt_who_jailhbutton"]            = "Jails the character in the Horde Jail",
    ["tt_who_unjailbutton"]           = "UnJails the character",
  --[[Control Labels]]
    ["ma_ShowWhoButton"]              = "Refresh",
    ["ma_resetwhobutton"]             = "Reset",
    ["ma_acctdetail"]                 = "Acct:",
    ["ma_chardetail"]                 = "Char:",
    ["ma_whisperbutton"]              = "Whisper",
    ["ma_SummonWhoButton"]            = "Summon",
    ["ma_GoCharWhoButton"]            = "Appear",
    ["ma_AnswerWhoButton"]            = "Mail",
    ["ma_who_customize"]              = "Customize",
    ["ma_who_chardelete"]             = "|c00FF0000Char Del|r",
    ["ma_who_charrename"]             = "Rename",
    ["ma_DeleteWhoButton"]            = "Kick",
    ["ma_who_1daybanbutton"]          = "1dayBan",
    ["ma_who_permbanbutton"]          = "PermBan",
    ["ma_who_jailabutton"]            = "Jail(A)",
    ["ma_who_jailhbutton"]            = "Jail(H)",
    ["ma_who_unjailbutton"]           = "UnJail",
  --[[Other]]



--[[ChangeLog Tab]]  --Place holder for future update*
  --["tabmenu_changelog"] = "ChangeLog",
  --[[Tooltips]]
  --[[Control Labels]]
  --[[Other]]



--[[Pop UPs]]
  --[[General]]
  --[[ToolTips]]
    ["tt_ItemButton"]                 = "Toggle a popup with the function to search for items and manage your favorites.",
    ["tt_ItemSetButton"]              = "Toggle a popup with the function to search for itemsets and manage your favorites.",
    ["tt_SpellButton"]                = "Toggle a popup with the function to search for spells and manage your favorites.",
    ["tt_QuestButton"]                = "Toggle a popup with the function to search for quests and manage your favorites.",
    ["tt_CreatureButton"]             = "Toggle a popup with the function to search for creatures and manage your favorites.",
    ["tt_ObjectButton"]               = "Toggle a popup with the function to search for objects and manage your favorites.",
    ["tt_SearchDefault"]              = "Now you can enter a keyword and start the search.",
    ["tt_SkillButton"]                = "Toggle a popup with the function to search for skills and manage your favorites.",
  --[[Labels]]
    ["ma_ItemButton"]                 = "Item-Search",
    ["ma_ItemSetButton"]              = "ItemSet-Search",
    ["ma_SpellButton"]                = "Spell-Search",
    ["ma_QuestButton"]                = "Quest-Search",
    ["ma_CreatureButton"]             = "Creature-Search",
    ["ma_ObjectButton"]               = "Object-Search",
    ["ma_TeleSearchButton"]           = "Teleport-Search",
    ["ma_MailRecipient"]              = "Recipient",
    ["ma_Mail"]                       = "Send Mail",
    ["ma_Send"]                       = "Send",
    ["ma_MailSubject"]                = "Subject",
    ["ma_MailYourMsg"]                = "Message...\r\n\r\n\r\n",
    ["ma_SearchButton"]               = "Search...",
    ["ma_ResetButton"]                = "Reset",
    ["ma_FavAdd"]                     = "Add selected",
    ["ma_FavRemove"]                  = "Remove selected",
    ["ma_SelectAllButton"]            = "Select all",
    ["ma_DeselectAllButton"]          = "Deselect all",
    ["ma_MailBytesLeft"]              = "Bytes left: ",
    ["ma_SkillButton"]                = "Skill-Search",
    ["ma_SkillVar1Button"]            = "Skill",
    ["ma_SkillVar2Button"]            = "Max Skill",
    ["ma_ItemVar1Button"]             = "Amount",
    ["ma_ObjectVar1Button"]           = "Loot Template",
    ["ma_ObjectVar2Button"]           = "Spawn Time",
    ["ma_NoFavorites"]                = "There are currently no saved favorites!",
    ["favoriteResults"]               = "|cFF00FF00Favorites:|r ",



--[[Deprecated, but may be used again.]]
    ["ma_LearnAllButton"]             = "All spells",
    ["ma_LearnCraftsButton"]          = "All professions and recipes",
    ["ma_LearnGMButton"]              = "Default GM spells",
    ["ma_LearnClassButton"]           = "All class-spells",
    ["ma_GPSButton"]                  = "GPS",
    ["ma_Online"]                     = "Online",
    ["ma_Offline"]                    = "Offline",



--[[Linkifier]]
    ["lfer_Spawn"]                    = "Spawn",
    ["lfer_List"]                     = "List",
    ["lfer_Reload"]                   = "Reload",
    ["lfer_Goto"]                     = "Goto",
    ["lfer_Move"]                     = "Move",
    ["lfer_Turn"]                     = "Turn",
    ["lfer_Delete"]                   = "Delete",
    ["lfer_Teleport"]                 = "Teleport",
    ["lfer_Morph"]                    = "Morph",
    ["lfer_Add"]                      = "Add",
    ["lfer_Remove"]                   = "Remove",
    ["lfer_Learn"]                    = "Learn",
    ["lfer_Unlearn"]                  = "Unlearn",
    ["lfer_Error"]                    = "Error Search String Matched but an error occured or unable to find type"

}
end
