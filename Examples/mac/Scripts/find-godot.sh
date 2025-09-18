#!/usr/bin/env bash

# Finds Godot apps in /Applications, reads each bundle's Info.plist version,
# and prints the path closest to the requested version (e.g., "4.4").
# Usage: ./find-godot.sh 4.4

set -euo pipefail
IFS=$'\n\t'

plistbuddy="/usr/libexec/PlistBuddy"
target_pattern="${1:-4.4}"

parse_ver() {
  # Keep only N.N[.N]; empty -> 0
  printf '%s' "${1:-}" | sed -E 's/^([0-9]+(\.[0-9]+){0,2}).*/\1/; s/^$/0/'
}

to_int() {
  local v m n p
  v="$(parse_ver "$1")"
  IFS=. read -r m n p <<<"$v"
  : "${m:=0}" "${n:=0}" "${p:=0}"
  printf '%d\n' "$(( m*1000000 + n*1000 + p ))"
}

is_godot_bundle() {
  # True if CFBundleIdentifier or app name looks like Godot
  local app="$1" ip="$1/Contents/Info.plist" id base
  [[ -f "$ip" ]] || return 1
  id="$("$plistbuddy" -c "Print :CFBundleIdentifier" "$ip" 2>/dev/null || true)"
  base="$(basename "$app")"
  printf '%s\n' "$id"   | grep -qi 'godot' && return 0
  printf '%s\n' "$base" | grep -qi 'godot' && return 0
  return 1
}

read_version() {
  local ip="$1/Contents/Info.plist" v
  v="$("$plistbuddy" -c "Print :CFBundleShortVersionString" "$ip" 2>/dev/null || \
      "$plistbuddy" -c "Print :CFBundleVersion" "$ip" 2>/dev/null || echo 0)"
  parse_ver "$v"
}

target_num="$(to_int "$target_pattern")"
best_path=""
best_dist=""
best_num=""

# Find .app bundles under /Applications (depth allows Godot variants/folders).
while IFS= read -r -d '' app; do
  is_godot_bundle "$app" || continue
  ver="$(read_version "$app")"
  num="$(to_int "$ver")"
  # Distance to target; tie-break by larger version number.
  dist=$(( num > target_num ? num - target_num : target_num - num ))
  if [[ -z "${best_dist:-}" || "$dist" -lt "$best_dist" || ( "$dist" -eq "$best_dist" && "$num" -gt "$best_num" ) ]]; then
    best_dist="$dist"
    best_num="$num"
    best_path="$app"
  fi
done < <(find /Applications -maxdepth 3 -type d -name "*.app" -print0)

if [[ -n "$best_path" ]]; then
  printf '%s\n' "$best_path"
else
  echo "No Godot app found in /Applications matching target ${target_pattern}" >&2
  exit 1
fi
