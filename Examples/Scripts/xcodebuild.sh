#!/bin/sh
#
# Build a game without launching XCode for e.g. hot-reloading or automated builds.
# You can pass additional xcodebuild arguments to this script.
#
# derivedDataPath should match XCode because our build scripts look at this path
# to see if the game.pck file has changed (for incremental builds)

set -e

scheme="SwiftGodotBuilderExample"
configuration="Debug"
arch="arm64"

xcodebuild "$@" \
-arch "$arch" -scheme "$scheme" -configuration "$configuration" \
-derivedDataPath "$HOME/Library/Developer/Xcode/DerivedData" build

echo "\nBuild Successful:\n"
ls ~/Library/Developer/Xcode/DerivedData/$scheme-*/Build/Products/Debug/$scheme.app/Contents/MacOS/$scheme
