# XCode runs this script during Build Phases -> Run Script
#
# XCode skips this script during incremental builds if both:
# - $(SRCROOT)/GodotProject and
# - $(TARGET_BUILD_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/game.pck
# haven't changed.

set -e

: "${GODOT:=/Applications/Godot.app/Contents/MacOS/Godot}"
: "${GODOT_PROJ_DIR:=${SRCROOT}/GodotProject}"
: "${GODOT_PRESET:=Packer}"
: "${PCK_NAME:=game.pck}"

DEST="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/${PCK_NAME}"

"$GODOT" --headless "${GODOT_PROJ_DIR}/project.godot" --quit
"$GODOT" --headless --path "$GODOT_PROJ_DIR" --export-pack "$GODOT_PRESET" "$DEST"

