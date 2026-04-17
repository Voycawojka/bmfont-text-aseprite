#!/bin/bash

OUTPUT="bmfont-text.aseprite-extension"

zip -r "$OUTPUT" "src" "package.json" "LICENSE" "README.md"

if [ $? -eq 0 ]; then
    echo "Built $OUTPUT"
else
    exit 1 
fi
