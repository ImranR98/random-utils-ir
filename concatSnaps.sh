#!/bin/bash -e

CURRENT_DIR="$(pwd)"
TARGET_DIR="$1"
if [ -z "$TARGET_DIR" ]; then
    TARGET_DIR="$CURRENT_DIR"
fi
TARGET_DIR="$(realpath "$TARGET_DIR")"
TEMP_FILE="$(mktemp)"
trap "cd \"$CURRENT_DIR\"; rm \"$TEMP_FILE\"" EXIT

cd "${TARGET_DIR}"
FILES="$(ls -tr Snapchat-*.mp4)"
OUTPUT_FN=Snap_"$(date -d @"$(stat --format='%Y' "$(echo "$FILES" | head -1)")" --utc +%Y-%m-%d-%H%M%S)".mp4
echo "$FILES" > "$TEMP_FILE"
SED_SAFE_TARGET_DIR="${TARGET_DIR//\//\\\/}"
sed -i -e "s/^/file '$SED_SAFE_TARGET_DIR\//g" "$TEMP_FILE"
sed -i -e "s/$/'/g" "$TEMP_FILE"
cat "$TEMP_FILE"
ffmpeg -f concat -safe 0 -i "$TEMP_FILE" -c copy "$TARGET_DIR"/"$OUTPUT_FN"

echo "$TARGET_DIR"/"$OUTPUT_FN"
