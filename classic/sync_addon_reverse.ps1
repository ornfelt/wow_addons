# sync_addon_reverse.ps1 - sync an addon back from the classic client into this repo's classic/Addons
#
# Shorthand for sync_addon.ps1 -Reverse: removes every matching addon dir in classic/Addons, then
# copies the matching dirs from <wow_classic_dir>/Interface/AddOns. Takes every sync_addon.ps1 option.
#
# Usage examples:
# copy the client's Skada* dirs into the repo (preview first):
#   .\sync_addon_reverse.ps1 -DryRun
#   .\sync_addon_reverse.ps1
# only the dir named exactly Skada:
#   .\sync_addon_reverse.ps1 Skada -Exact
# other client dir than $env:wow_classic_dir:
#   .\sync_addon_reverse.ps1 -WowDir D:\games\wow112
# print the equivalent PowerShell commands instead of running them:
#   .\sync_addon_reverse.ps1 -ShowCmd

& (Join-Path $PSScriptRoot 'sync_addon.ps1') @args -Reverse
exit $LASTEXITCODE
