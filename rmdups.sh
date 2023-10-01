# rmdups
# Generates rm command to get rid of redundant duplicate items in the current directory (compares MD5 hashes)

readarray -t lines < <(md5sum * | awk '$1 in a{print a[$1]; print} {a[$1]=$0}' | sort)
prevHash="$(echo "$lines" | head -1 | awk '{print $1}')"
arr=()
lines+=('')
for line in "${lines[@]}"; do
    hash="$(echo "$line" | awk '{print $1}')"
    file="$(echo "$line" | awk '{$1=""; print $0}' | tail -c +2)"
    if [ "$hash" == "$prevHash" ]; then
        arr+=("$file")
    else
        group="$(for f in "${arr[@]}"; do echo "$(echo "$f" | tr -dc '0-9')"/"$f"; done)"
        sorted="$(echo "$group" | sort -n | awk -F '/' '{print $2}')"
        echo "# "$prevHash":"
        echo "# rm '"$(echo "$sorted" | head -1 )"' # KEEP"
        echo "$sorted" | tail -n +2 | awk '{ print "  rm '\''" $0 "'\''"}'
        echo ""
        arr=("$file")
    fi
    prevHash="$hash"
done
