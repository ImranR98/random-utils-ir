# Given a command string $1, an input dir $2 and an output dir $3...
# Run all commands of the form '$1 "$2/X" "$3/X"' where X is a subpath of $2 (including '.' which is $2 itself) recursively for all possible subdirectories

# Check if the input and output directories are provided as arguments
if [ $# -lt 3 ]; then
    echo "Usage: $0 command input_dir output_dir"
    exit 1
fi

# Get the input and output directories
COMMAND="$1"
shift
INPUT_DIR="$1"
shift
OUTPUT_DIR="$1"
shift

if [ -z "$(which "$COMMAND")" ]; then
    echo "Error: Command '$COMMAND' does not exist"
    exit 1
fi

# Check if the input directory exists
if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: Input directory '$INPUT_DIR' does not exist"
    exit 2
fi

INPUT_DIR="$(realpath "$INPUT_DIR")"

get_relative_path() {
    local A="$1"
    local B="$2"
    if [ "$A" = "$B" ]; then
        echo ""
        return
    fi
    local diff=$(basename "$B")
    while [ "$A" != "$(dirname "$B")" ]; do
        B=$(dirname "$B")
        diff="$(basename "$B")"/"$diff"
    done
    echo "$diff"
}

find "$INPUT_DIR" -type d | while read -r DIR; do
    REL_PATH=$(get_relative_path "$INPUT_DIR" "$DIR")
    FINAL_COMMAND=""$COMMAND" '$DIR' '$OUTPUT_DIR/$REL_PATH' $@"
    eval "$FINAL_COMMAND"
done
