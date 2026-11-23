#!/usr/bin/env bash
# sync_addon_reverse.sh - sync an addon back from the wotlk client into this repo's wotlk/Addons
#
# Shorthand for sync_addon.sh --reverse: removes every matching addon dir in wotlk/Addons, then
# copies the matching dirs from <wow_dir>/Interface/AddOns. Takes every sync_addon.sh option.
#
# Usage examples:
# copy the client's Skada* dirs into the repo (preview first):
#   ./sync_addon_reverse.sh --dry-run
#   ./sync_addon_reverse.sh
# only the dir named exactly Skada:
#   ./sync_addon_reverse.sh Skada --exact
# other client dir than $wow_dir:
#   ./sync_addon_reverse.sh --wow-dir ~/games/wow335
# print the equivalent bash commands instead of running them:
#   ./sync_addon_reverse.sh --show-cmd

exec "$(dirname "${BASH_SOURCE[0]}")/sync_addon.sh" "$@" --reverse
