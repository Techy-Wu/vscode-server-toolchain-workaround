#!/bin/bash

# Set file size limit to 2KB
MAX_SIZE=$((2 * 1024))

# Scan all files smaller than 2KB in the current directory and its subdirectories
# and attempt to recreate them as symbolic links based on their content
find . -type f -size -${MAX_SIZE}c | while read -r file; do
    # Read the first line of the file to get the target path
    target=$(head -n 1 "$file" | tr -d '\r\n')

    # Check if the target exists and is not empty
    if [[ -n "$target" && -e "$(dirname "$file")/$target" ]]; then
        echo "🔗 Resume the symbolic link: $file → $target"
        rm -f "$file"
        ln -s "$target" "$file"
    else
        echo "⚠️ Skip: $file (target does not exist or is empty)"
    fi
done