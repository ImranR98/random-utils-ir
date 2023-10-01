#!/bin/bash

# Ensure this is installed: python3 -m pip install secretstorage

set -e

playlistid="$1"
if [ -z "$playlistid" ]; then
    echo 'Playlist ID not provided' >&2
    exit 1
fi
yt-dlp https://www.youtube.com/playlist?list="$playlistid" --restrict-filenames --embed-subs --embed-thumbnail --embed-metadata -f "bv*[ext=mp4][height<=720]+ba[ext=m4a] / b[ext=mp4][height<=720] / bv*+ba / b" --output "~/Downloads/%(playlist)s/%(playlist_index)03d - %(title)s.%(ext)s" --cookies-from-browser chromium+gnomekeyring
latest_folder=$(ls -t ~/Downloads | head -n 1)
echo "Please confirm that the playlist is in ~/Downloads/"$latest_folder" by pressing enter (if this is wrong, enter the correct folder name):"
read val
if [ -n "$val" ]; then
    latest_folder="$val"
fi
cd ~/Downloads/"$latest_folder"
for FILE in *; do
    exiftool '-FileModifyDate > DateTimeOriginal' "$FILE" -m 
    exiftool '-DateTimeOriginal > CreateDate' "$FILE" -m 
    exiftool '-DateTimeOriginal > MediaCreateDate' "$FILE" -m 
    exiftool '-DateTimeOriginal > TrackCreateDate' "$FILE" -m 
    exiftool '-DateTimeOriginal > FileCreateDate' "$FILE" -m 
    exiftool '-DateTimeOriginal > ModifyDate' "$FILE" -m 
    exiftool '-DateTimeOriginal > MediaModifyDate' "$FILE" -m 
    exiftool '-DateTimeOriginal > TrackModifyDate' "$FILE" -m 
    exiftool '-DateTimeOriginal > FileModifyDate' "$FILE" -m
done
rm *_original
for f in *; do mv "$f" "$(date +%Y%m%d)"_"$f"; done
cd ..
