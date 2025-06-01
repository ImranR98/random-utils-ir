#!/bin/bash
set -e

CURRENT_DIR="$(pwd)"
TARGET_DIR="$1"
if [ -z "$TARGET_DIR" ]; then
    TARGET_DIR="$CURRENT_DIR"
fi
TARGET_DIR="$(realpath "$TARGET_DIR")"

TEMP_DIR=$(mktemp -d)
trap "cd \"$CURRENT_DIR\"; rm -r \"$TEMP_DIR\"" EXIT
cd "$TARGET_DIR"

CONCAT_LIST="$TEMP_DIR/concat_list.txt"
> "$CONCAT_LIST"

FILES=$(ls -t Snapchat-*.mp4)
for file in $FILES; do
    BASENAME=$(basename "$file" .mp4)
    REENCODED_FILE="$TEMP_DIR/${BASENAME}_reencoded.mp4"
    ffmpeg -i "$file" -c:v libx264 -c:a aac -strict experimental -y -preset slow -crf 18 "$REENCODED_FILE"
    echo "file '$REENCODED_FILE'" >> "$CONCAT_LIST"
done

OUTPUT_FN=Snap_"$(date -d @"$(stat --format='%Y' "$(echo "$FILES" | tail -1)")" --utc +%Y-%m-%d-%H%M%S)".mp4
ffmpeg -f concat -safe 0 -i "$CONCAT_LIST" -c copy "$TARGET_DIR"/"$OUTPUT_FN"

echo "$TARGET_DIR"/"$OUTPUT_FN"