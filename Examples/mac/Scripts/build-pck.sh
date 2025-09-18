#!/usr/bin/env bash

# XCode runs this script during Build Phases -> Run Script
#
# XCode **skips this script during incremental builds** if both:
# - $(SRCROOT)/GodotProject and
# - $(TARGET_BUILD_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/game.pck
# haven't changed.

: "${GODOT_VERSION:=4.4}"
: "${GODOT:=/Applications/Godot.app/Contents/MacOS/Godot}"
: "${GODOT_PROJ_DIR:=${SRCROOT:-.}/GodotProject}"
: "${GODOT_PRESET:=macOS}"
: "${PCK_NAME:=game.pck}"

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

GODOT_APP="$("${script_dir}/find-godot.sh" "$GODOT_VERSION" 2>/dev/null || true)"
[[ -n "${GODOT_APP:-}" ]] && GODOT="${GODOT_APP}/Contents/MacOS/Godot"

[[ -x "$GODOT" ]] || { echo "Godot binary not found/executable: $GODOT" >&2; exit 1; }

echo "Using ${GODOT}"

dest="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/${PCK_NAME}"

"$GODOT" --headless "${GODOT_PROJ_DIR}/project.godot" --quit
"$GODOT" --headless --path "$GODOT_PROJ_DIR" --export-pack "$GODOT_PRESET" "$dest"
