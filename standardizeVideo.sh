#!/bin/bash
# Use ffmpeg to compress all videos in a directory and resize them to 720p

# Check if the input and output directories are provided as arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 input_dir output_dir [--dry-run] [--include-unlikely]"
    exit 1
fi

# Get the input and output directories
INPUT_DIR="$1"
OUTPUT_DIR="$2"

MAX_PROCS="$(grep -c ^processor /proc/cpuinfo)"

# Check if the input directory exists
if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: Input directory '$INPUT_DIR' does not exist"
    exit 1
fi

# Manual MAX_PROCS
if [[ -n "$3" ]] && [[ "$3" != "--dry-run" ]]; then
    re='^[0-9]+$'
    if ! [[ $3 =~ $re ]]; then
        echo "Error: Not a number: "$3""
        exit 2
    fi
    MAX_PROCS="$3"
fi

# Check options
if [[ "$3" == "--dry-run" ]] || [[ "$4" == "--dry-run" ]] || [[ "$5" == "--dry-run" ]]; then
    DRY_RUN=true
fi
if [[ "$3" == "--include-unlikely" ]] || [[ "$4" == "--include-unlikely" ]] || [[ "$5" == "--include-unlikely" ]]; then
    INCLUDE_UNLIKELY=true
fi

COMMAND_FILE="$(mktemp --suffix='.sh')"
if [ -z "$COMMAND_FILE" ]; then
    echo "Error: Could not create temp file"
    exit 3
fi

CURR_PROCS=0

# Loop through all the video files in the input directory and its subdirectories
find "$INPUT_DIR" -maxdepth 1 -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.avi" -o -iname "*.mov" -o -iname "*.wmv" -o -iname "*.flv" \) | while read -r FILE; do

    # Get the file name and extension
    FILENAME=$(basename "$FILE")
    # EXTENSION="${FILENAME##*.}"

    # Set the output file name and path
    TEMP_OUTPUT_FILE="$OUTPUT_DIR/INCOMPLETE-${FILENAME%.*}.mp4"
    OUTPUT_FILE="$OUTPUT_DIR/${FILENAME%.*}.mp4"

    if [ -f "$OUTPUT_FILE" ]; then
        echo "$OUTPUT_FILE" exists. Skipping...
        continue
    fi

    SIZE="$(du "$FILE" | awk '{print $1}')"
    LENGTH="$(ffprobe -i "$FILE" -show_format -v quiet | sed -n 's/duration=//p')"
    LIKELY_SIZE="$(printf "%.0f" "$(echo "((1192*$LENGTH*0.85)/8)" | bc)")"

    if [ "$INCLUDE_UNLIKELY" != true ] && [ "$LIKELY_SIZE" -gt "$SIZE" ]; then
        echo ""$OUTPUT_FILE" is already smaller ("$SIZE") than the output is likely to be (est. "$LIKELY_SIZE"). Skipping..."
        continue
    fi

    # Set the options for ffmpeg
    OPTIONS="-c:v libx264 -crf 23 -preset veryslow -c:a aac -b:a 192k -maxrate 1M -bufsize 2M"

    # Check the resolution of the video
    RESOLUTION=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$FILE")
    WIDTH=$(echo "$RESOLUTION" | cut -d 'x' -f 1)
    HEIGHT=$(echo "$RESOLUTION" | cut -d 'x' -f 2)

    # Resize the video to 720p if necessary
    if [[ $WIDTH -gt 1280 || $HEIGHT -gt 720 ]]; then
        RESIZE="-vf scale=-2:720"
    else
        RESIZE=""
    fi

    # Construct ffmpeg command and append to file
    echo "echo Launching process for "'"'$FILE'"'"\" ("$(du -h "$FILE" | awk '{print $1}')" to ~"$(echo "($LIKELY_SIZE/1024)" | bc)"M)...\"" >>"$COMMAND_FILE"
    COMMAND="ffmpeg -hide_banner -loglevel warning -i "'"'$FILE'"'" ${RESIZE} ${OPTIONS} "'"'$TEMP_OUTPUT_FILE'"'" && mv "'"'$TEMP_OUTPUT_FILE'"'" "'"'$OUTPUT_FILE'"'" || rm "'"'$TEMP_OUTPUT_FILE'"'" &"
    echo "$COMMAND" >>"$COMMAND_FILE"
    ((CURR_PROCS++))
    if (($CURR_PROCS >= $MAX_PROCS)); then
        echo "wait" >>"$COMMAND_FILE"
        CURR_PROCS=0
    fi
done

if [ -n "$(cat "$COMMAND_FILE")" ]; then
    echo "wait" >>"$COMMAND_FILE"
    chmod +x "$COMMAND_FILE"

    # Run the commands and wait for them to complete (or just echo them in case of --dry-run)
    if [ "$DRY_RUN" != true ]; then
        # Check if the output directory exists or create it
        if [ ! -d "$OUTPUT_DIR" ]; then
            echo "Creating output directory '$OUTPUT_DIR'"
            mkdir -p "$OUTPUT_DIR"
        fi
        "$COMMAND_FILE"
    else
        cat "$COMMAND_FILE"
    fi

    # Clean up
    rm "$COMMAND_FILE"
fi
