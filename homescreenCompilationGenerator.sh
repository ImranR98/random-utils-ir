#!/bin/bash

# $1 has png and mp4 files with some file names containing 'home-screen' (all files also assumed to begin with YYYY-MM-DD dates.
# These (assumed to be phone screenshots/recordings of a home screen) are compiled into a video (screenshots from the same day are put into one image).
# If there are too many images from the same day, there may be errors.
# Required commands are assumed to be installed. Generally minimal error checking or validation.

addImageBorder() {
	gravity="$1"
	if [ "$gravity" == 'west' ] || [ "$gravity" == 'east' ]; then
		splice='2x0'
	elif [ "$gravity" == 'north' ] || [ "$gravity" == 'south' ]; then
		splice='0x2'
	else
		echo >&2 "Invalid gravity! Use north/south/east/west."
		exit 1
	fi
	convert "$2" -gravity "$gravity" -background black -splice "$splice" "$3"
}

joinImages() {
	direction="$1"
	shift
	outputFile="$1"
	shift
	if [ "$direction" == 'horizontal' ]; then
		gravity='west'
	elif [ "$direction" == 'vertical' ]; then
		gravity='north'
	else
		echo >&2 "Invalid direction! Use horizontal/vertical."
		exit 1
	fi
	mergeInd=0
	tempMergeDir="$(mktemp -d)"
	for f in "${@}"; do
		if [ $mergeInd -eq 0 ]; then
			cp "$f" "$tempMergeDir"
		else
			addImageBorder "$gravity" "$f" "$tempMergeDir"/"$(basename "$f")"
		fi
		mergeInd=$(($mergeInd + 1))
	done
	mergeInd=''
	if [ "$direction" == 'horizontal' ]; then
		appendOpt="+"
	else
		appendOpt="-"
	fi
	convert "$tempMergeDir"/* "$appendOpt"append -background '#3B3B3B' "$outputFile"
	rm -r "$tempMergeDir"
}

groupPNGsByDatePrefix() {
	for group in $(ls "$1" | awk -F '-' '{print $1"-"$2"-"$3}' | uniq); do
		num="$(ls "$1"/"$group"-*.png | wc -l)"
		if [ "$num" -eq 1 ]; then
			cp "$1"/"$group"-*.png "$2"/"$group".png
		elif [ "$num" -lt 5 ]; then
			joinImages 'horizontal' "$2"/"$group".png "$1"/"$group"-*.png >/dev/null
		else
			files=$(ls "$1"/"$group"-*.png)
			tempImageDir="$(mktemp -d)"
			i=1
			while [ true ]; do
				if [ "$(echo "$files")" == "" ]; then
					break
				else
					joinImages 'horizontal' "$tempImageDir"/"$group"-"$i".png $(echo "$files" | head -4)
					files=$(echo "$files" | tail -n +5)
				fi
				i=$(($i + 1))
			done
			joinImages 'vertical' "$2"/"$group".png "$tempImageDir"/*.png
			rm -r "$tempImageDir"
		fi
	done
}

PNGsToMP4s() {
	for f in "$1"/*.png; do
		ffmpeg -hide_banner -loglevel error -loop 1 -i "$f" -c:v libopenh264 -t 3 -r:v 60 -vf "scale=-1:1080,setsar=1,format=yuv420p" "$2"/"$(basename "$f")".mp4
	done
}

standardizeMP4s() {
	for f in "$1"/*.mp4; do
		ffmpeg -hide_banner -loglevel error -i "$f" -c:a aac -ar 48000 -ac 2 -c:v copy -video_track_timescale 600 "$2"/"$(basename "$f")"
	done
}

concatMP4s() {
	for f in "$1"/*.mp4; do echo "file '$f'" >> "$1"/videos.txt; done
	ffmpeg -hide_banner -loglevel error -f concat -safe 0 -i "$1"/videos.txt -c copy "$2"
}

# Run

if [ ! -d "$1" ] || [ ! -d "$2" ]; then
	echo >&2 "Invalid arguments! Provide source/destination directories."
	exit 1
fi

tempDirA="$(mktemp -d)"
cp "$1"/*home-screen*.png "$tempDirA"
for f in "$tempDirA"/*\ *; do mv "$f" "${f// /_}"; done
tempDirB="$(mktemp -d)"
groupPNGsByDatePrefix "$tempDirA" "$tempDirB"
rm -r "$tempDirA"
PNGsToMP4s "$tempDirB" "$tempDirB"
cp "$1"/*home-screen*.mp4 "$tempDirB"
for f in "$tempDirB"/*\ *; do mv "$f" "${f// /_}"; done
tempDirC="$(mktemp -d)"
standardizeMP4s "$tempDirB" "$tempDirC"
rm -r "$tempDirB"
concatMP4s "$tempDirC" "$2"/output.mp4
rm -r "$tempDirC"
