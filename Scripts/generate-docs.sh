#!/bin/sh

swift package --allow-writing-to-directory "docs" generate-documentation --target SwiftGodotBuilder --include-extended-types --transform-for-static-hosting --hosting-base-path "SwiftGodotBuilder" --output-path "docs/"
