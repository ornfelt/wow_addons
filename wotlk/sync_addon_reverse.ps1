# sync_addon_reverse.ps1 - sync an addon back from the wotlk client into this repo's wotlk/Addons
#
# Shorthand for sync_addon.ps1 -Reverse: removes every matching addon dir in wotlk/Addons, then
# copies the matching dirs from <wow_dir>/Interface/AddOns. Takes every sync_addon.ps1 option.
#
# Usage examples:
# copy the client's Skada* dirs into the repo (preview first):
#   .\sync_addon_reverse.ps1 -DryRun
#   .\sync_addon_reverse.ps1
# only the dir named exactly Skada:
#   .\sync_addon_reverse.ps1 Skada -Exact
# other client dir than $env:wow_dir:
#   .\sync_addon_reverse.ps1 -WowDir D:\games\wow335
# print the equivalent PowerShell commands instead of running them:
#   .\sync_addon_reverse.ps1 -ShowCmd

& (Join-Path $PSScriptRoot 'sync_addon.ps1') @args -Reverse
exit $LASTEXITCODE
