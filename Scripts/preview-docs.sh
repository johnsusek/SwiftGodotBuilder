#!/bin/sh

swift package --disable-sandbox preview-documentation --target $1 --include-extended-types --output-path docs
