#!/bin/bash
# Given two directories, find file names they have in common and print out the commands needed to keep the smaller one.
# If the smaller file is in $2, it is copied to $1, replacing the original.
# If the smaller file is in $1, it stays in $1.
# So the results are in $1, which is modified. $2 is never changed.

# Check if the directories are provided as arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 primary_dir secondary_dir [--ignore-ext]"
    exit 1
fi

# Get the directories
PRIMARY_DIR="$1"
SECONDARY_DIR="$2"

# Check if the directories exist
if [ ! -d "$PRIMARY_DIR" ]; then
    echo "# Error: Primary directory '$PRIMARY_DIR' does not exist"
    exit 1
fi
if [ ! -d "$SECONDARY_DIR" ]; then
    echo "# Error: Secondary directory '$SECONDARY_DIR' does not exist"
    exit 1
fi
if [ "$3" == "--ignore-ext" ]; then
    IGNORE_EXT=true
fi

# Loop through all the video files in the input directory and its subdirectories
find "$PRIMARY_DIR" -maxdepth 1 -type f | while read -r FILE_A; do
    echo ""

    FILENAME=$(basename "$FILE_A")
    EXTENSION="${FILENAME##*.}"

    SIZE_A=0
    SIZE_A="$(du "$FILE_A" | awk '{print $1}')"

    if [ "$IGNORE_EXT" == true ]; then
        FILES_B="$(ls "$SECONDARY_DIR/${FILENAME%.*}".* 2>/dev/null)"
    else
        FILES_B="$SECONDARY_DIR/${FILENAME}"
    fi

    echo "$FILES_B" | while read FILE_B; do
        if [ ! -f "$FILE_B" ]; then
            echo -e "# \033[31m"$FILENAME" does not exist in "$SECONDARY_DIR", skipping...\033[0m"
            continue
        fi

        SIZE_B=0

        SIZE_B="$(du "$FILE_B" | awk '{print $1}')"

        echo "# Sizes for "$FILENAME": "$SIZE_A" VS "$SIZE_B"..."

        if [[ $SIZE_B -ge $SIZE_A ]]; then
            echo "# The smaller (or equal) file is already in "$PRIMARY_DIR". Skipping..."
        else
            echo -e "# \033[32mThe smaller file is in "$SECONDARY_DIR". Overwrite '"$FILE_A"' by running:\033[0m"
            echo "rm \""$FILE_A"\" && cp \""$FILE_B"\" \""$PRIMARY_DIR/"\""
        fi
    done
done
