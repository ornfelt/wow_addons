#!/usr/bin/env bash
# sync_addon.sh - sync an addon from this repo's wotlk/Addons into the wotlk client
#
# Removes every addon dir in <wow_dir>/Interface/AddOns whose name matches the addon (old
# versions and leftover companion addons such as SkadaImprovement), then copies the matching
# dirs from the source. SavedVariables in WTF are left alone, so the addon keeps its settings.
# The client dir comes from the env var wow_dir unless --wow-dir is given.
#
# Usage examples:
# sync Skada (default) into $wow_dir/Interface/AddOns:
#   ./sync_addon.sh
# another addon, prefix match (every DBM-* dir):
#   ./sync_addon.sh DBM-
# only the dir named exactly Skada (other Skada* dirs in the client are kept):
#   ./sync_addon.sh Skada --exact
# other source AddOns dir (positional or named):
#   ./sync_addon.sh Skada /tmp/Skada-WoTLK
#   ./sync_addon.sh --addon Skada --source /tmp/Skada-WoTLK
# other client dir than $wow_dir:
#   ./sync_addon.sh --wow-dir ~/games/wow335
# preview, change nothing:
#   ./sync_addon.sh --dry-run
# print the equivalent bash commands instead of running them:
#   ./sync_addon.sh --show-cmd
# case sensitive name match:
#   ./sync_addon.sh Skada --case-sensitive

set -euo pipefail
shopt -s nullglob

RESET='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
MAGENTA='\033[35m'

write_ok()      { echo -e "${GREEN}${1}${RESET}"; }
write_err()     { echo -e "${RED}${1}${RESET}" >&2; }
write_warn()    { echo -e "${YELLOW}${1}${RESET}"; }
write_info()    { echo -e "${CYAN}${1}${RESET}"; }
write_info_alt(){ echo -e "${MAGENTA}${1}${RESET}"; }

WOW_DIR_ENV="wow_dir"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
invocation="$0 $*"

addon="Skada"
source_dir="$script_dir/Addons"
wow_dir_arg="${wow_dir:-}"
exact=0
case_sensitive=0
dry_run=0
show_cmd=0
positional=()

while (($#)); do
    case "$1" in
        -a|--addon)          addon="$2"; shift 2 ;;
        -s|--source)         source_dir="$2"; shift 2 ;;
        -w|--wow-dir)        wow_dir_arg="$2"; shift 2 ;;
        -e|--exact)          exact=1; shift ;;
        -c|--case-sensitive) case_sensitive=1; shift ;;
        -n|--dry-run)        dry_run=1; shift ;;
        --show-cmd)          show_cmd=1; shift ;;
        -h|--help)           sed -n '2,/^$/p' "$0"; exit 0 ;;
        -*)                  write_err "Unknown option: $1"; exit 1 ;;
        *)                   positional+=("$1"); shift ;;
    esac
done
if ((${#positional[@]} > 0)); then addon="${positional[0]}"; fi
if ((${#positional[@]} > 1)); then source_dir="${positional[1]}"; fi

matches() {
    local name="$1" a="$addon"
    if ((!case_sensitive)); then name="${name,,}"; a="${a,,}"; fi
    if ((exact)); then [[ "$name" == "$a" ]]; else [[ "$name" == "$a"* ]]; fi
}

# matching addon dirs under $1, one per line, sorted
addon_dirs() {
    local d
    [[ -d "$1" ]] || return 0
    for d in "$1"/*/; do
        d="${d%/}"
        if matches "${d##*/}"; then echo "$d"; fi
    done | sort
}

# existing child of $1 named $2 in any case (Interface/AddOns vs interface/addons), else $1/$2
find_ci() {
    local d name
    for d in "$1"/*/; do
        d="${d%/}"; name="${d##*/}"
        if [[ "${name,,}" == "${2,,}" ]]; then echo "$d"; return; fi
    done
    echo "$1/$2"
}

# "## Version:" of <dir>/<dir name>.toc, ? when there is none
toc_version() {
    local toc="$1/${1##*/}.toc" v=""
    [[ -f "$toc" ]] && v="$(tr -d '\r' <"$toc" | awk -F':[ \t]*' 'tolower($1) ~ /^##[ \t]*version$/ { print $2; exit }')"
    echo "${v:-?}"
}

# --- checks ------------------------------------------------------------------
if [[ -z "${addon// }" ]]; then
    write_err "Addon name is empty - an empty prefix would match every addon."; exit 1
fi
if [[ -z "$wow_dir_arg" ]]; then
    write_err "Env var '$WOW_DIR_ENV' is not set - set it to the wotlk client dir or pass --wow-dir."; exit 1
fi
[[ -d "$wow_dir_arg" ]] || { write_err "Client dir not found: $wow_dir_arg"; exit 1; }
[[ -d "$source_dir" ]]  || { write_err "Source dir not found: $source_dir"; exit 1; }

wow_dir_arg="$(cd "$wow_dir_arg" && pwd)"
source_dir="$(cd "$source_dir" && pwd)"
client_addons="$(find_ci "$(find_ci "$wow_dir_arg" Interface)" AddOns)"
match_desc="'$addon'"; ((exact)) || match_desc="'$addon*'"
if ((case_sensitive)); then match_desc+=" (case sensitive)"; else match_desc+=" (case insensitive)"; fi

mapfile -t src_dirs < <(addon_dirs "$source_dir")
if ((${#src_dirs[@]} == 0)); then
    write_err "No addon dir matching $match_desc in $source_dir - nothing removed."; exit 1
fi
mapfile -t old_dirs < <(addon_dirs "$client_addons")
addons_missing=0; [[ -d "$client_addons" ]] || addons_missing=1

for d in "${src_dirs[@]}"; do
    [[ -f "$d/${d##*/}.toc" ]] || write_warn "warning: ${d##*/} has no ${d##*/}.toc - the client will not load it"
done

# --- show the commands only --------------------------------------------------
if ((show_cmd)); then
    echo "# $invocation"
    for d in "${old_dirs[@]}"; do printf 'rm -rf %q\n' "$d"; done
    ((addons_missing)) && printf 'mkdir -p %q\n' "$client_addons"
    for d in "${src_dirs[@]}"; do printf 'cp -r %q %q/\n' "$d" "$client_addons"; done
    exit 0
fi

# --- sync --------------------------------------------------------------------
prefix=""; ((dry_run)) && prefix="[dry run] "
write_info "${prefix}Syncing $match_desc"
write_info "  from $source_dir"
write_info "  to   $client_addons"

declare -A old_versions=()
for d in "${old_dirs[@]}"; do
    name="${d##*/}"
    old_versions["${name,,}"]="$(toc_version "$d")"
    ((dry_run)) || rm -rf "$d"
    write_warn "${prefix}removed $name (${old_versions["${name,,}"]})"
done

if ((addons_missing)); then
    write_warn "${prefix}creating missing $client_addons"
    ((dry_run)) || mkdir -p "$client_addons"
fi

file_count=0
for d in "${src_dirs[@]}"; do
    name="${d##*/}"
    new_version="$(toc_version "$d")"
    files="$(find "$d" -type f | wc -l | tr -d ' ')"
    file_count=$((file_count + files))
    ((dry_run)) || cp -r "$d" "$client_addons/"
    if [[ -n "${old_versions["${name,,}"]+x}" ]]; then
        change="${old_versions["${name,,}"]} -> $new_version"
    else
        change="new, $new_version"
    fi
    write_ok "${prefix}copied  $name ($change, $files files)"
done

leftover=()
for d in "${old_dirs[@]}"; do
    name="${d##*/}" found=0
    for s in "${src_dirs[@]}"; do
        s="${s##*/}"
        if [[ "${s,,}" == "${name,,}" ]]; then found=1; fi
    done
    ((found)) || leftover+=("$name")
done

echo
write_info_alt "${prefix}Done: removed ${#old_dirs[@]} dir(s), copied ${#src_dirs[@]} dir(s) / $file_count files."
if ((${#leftover[@]} > 0)); then
    write_info_alt "  cleaned up, not in the source: $(IFS=,; echo "${leftover[*]}" | sed 's/,/, /g')"
fi
((dry_run)) || write_info "Restart the client (or /reload if only files changed) to load it."
