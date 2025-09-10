#!/bin/sh

swift package --allow-writing-to-directory "docs-build" generate-documentation --target SwiftGodotBuilder --include-extended-types --transform-for-static-hosting --hosting-base-path "SwiftGodotBuilder" --output-path "docs-build/SwiftGodotBuilder"
swift package --allow-writing-to-directory "docs-build" generate-documentation --target SwiftGodotPatterns --include-extended-types --transform-for-static-hosting --hosting-base-path "SwiftGodotBuilder" --output-path "docs-build/SwiftGodotPatterns"
rsync -a docs-build/SwiftGodotPatterns/ docs-build/SwiftGodotBuilder/
rm -rf docs
mv docs-build/SwiftGodotBuilder docs
