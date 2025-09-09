#!/bin/sh

swift package --allow-writing-to-directory "docs" generate-documentation --target SwiftGodotBuilder --include-extended-types --transform-for-static-hosting --hosting-base-path "SwiftGodotBuilder" --output-path "docs"

swift package --allow-writing-to-directory "docs" generate-documentation --target SwiftGodotPatterns --include-extended-types --transform-for-static-hosting --hosting-base-path "SwiftGodotBuilder" --output-path "docs/SwiftGodotPatterns"

# Post-process the generated docs to merge documentation/ folder
ditto docs/SwiftGodotPatterns/ docs/
rm -rf docs/SwiftGodotPatterns
