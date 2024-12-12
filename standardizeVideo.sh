#!/bin/bash
# Use ffmpeg to compress all videos in a directory and resize them to 720p

# Example recursive usage w/ recursiveDirCommand.sh:
# ./recursiveDirCommand.sh ./standardizeVideo.sh ~/Downloads/A ~/Downloads/B 1

# Check if the input and output directories are provided as arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 input_dir output_dir [-d] [-u] [-b <size>] [-p <number>]
       -d    Dry run
       -u    Compress files even when the output is unlikely to be smaller
                 Output sizes are estimated
       -b    How much smaller (in MB) the output should be for a file to be skipped (default is 0)
                 Output sizes are estimated
                 Do not use in combination with -u
       -p    Number of files to process in parallel (default is 1)
                 Changing this is not recommended since individual file processes are already multithreaded
                 Note: Your CPU has $(grep -c ^processor /proc/cpuinfo) cores"
    exit 1
fi

# Check options
MIN_SIZE_DIFF=0
MAX_PROCS=1
while getopts "dub:p:" opt; do
    case $opt in
    d) DRY_RUN=true ;;
    u) INCLUDE_UNLIKELY=true ;;
    b) MIN_SIZE_DIFF=$(( OPTARG * 1000 )) ;;
    p) MAX_PROCS=$OPTARG ;;
    \?) usage && exit 1 ;;
    esac
done
shift $((OPTIND - 1))

echo $@

# Get the input and output directories
INPUT_DIR="$1"
OUTPUT_DIR="$2"

# Check if the input directory exists
if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: Input directory '$INPUT_DIR' does not exist"
    exit 1
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

    PLAIN_COPY=false

    if [ -f "$OUTPUT_FILE" ]; then
        echo "$OUTPUT_FILE" exists. Will copy without modifying...
        PLAIN_COPY=true
    fi

    SIZE="$(du "$FILE" | awk '{print $1}')"
    LENGTH="$(ffprobe -i "$FILE" -show_format -v quiet | sed -n 's/duration=//p')"
    LIKELY_SIZE="$(printf "%.0f" "$(echo "((1192*$LENGTH*0.85)/8)" | bc)")"
    LIKELY_SIZE_PLUS_MIN=$((LIKELY_SIZE + MIN_SIZE_DIFF))

    if [ "$INCLUDE_UNLIKELY" != true ] && [ "$LIKELY_SIZE_PLUS_MIN" -gt "$SIZE" ]; then
        echo ""$OUTPUT_FILE" is already smaller (or close enough) than the output is likely to be ($SIZE vs. approx. $LIKELY_SIZE_PLUS_MIN ($LIKELY_SIZE + $MIN_SIZE_DIFF)). Will copy without modifying..."
        PLAIN_COPY=true
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
    if [ "$PLAIN_COPY" == true ]; then
        COMMAND="cp "'"'$FILE'"'" "'"'$OUTPUT_FILE'"'" &"
    else
        echo "echo Launching process for "'"'$FILE'"'"\" ("$(du -h "$FILE" | awk '{print $1}')" to ~"$(echo "($LIKELY_SIZE/1024)" | bc)"M)...\"" >>"$COMMAND_FILE"
        COMMAND="ffmpeg -hide_banner -loglevel warning -i "'"'$FILE'"'" ${RESIZE} ${OPTIONS} "'"'$TEMP_OUTPUT_FILE'"'" && mv "'"'$TEMP_OUTPUT_FILE'"'" "'"'$OUTPUT_FILE'"'" || rm "'"'$TEMP_OUTPUT_FILE'"'" &"
    fi
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
