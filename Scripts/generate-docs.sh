#!/bin/sh

swift package --allow-writing-to-directory docs generate-documentation --target $1 --include-extended-types --transform-for-static-hosting --hosting-base-path $1 --output-path docs
