#!/bin/sh

swift package --disable-sandbox preview-documentation --target SwiftGodotBuilder --include-extended-types --output-path docs
