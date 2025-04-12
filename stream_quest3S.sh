#!/bin/bash
set -e

# Stream from Meta Quest 3S over Wi-Fi
# No audio support
# Assumes the headset is the only ADB device connected

if [ -z "$(which scrcpy)" ]; then
    echo "strcpy not installed!" >&2
    exit 1
fi

stream() {
    scrcpy --tcpip --audio-dup -b 25M --crop 1500:1400:180:220
}

stream && exit || :

if [[ "$(adb devices| grep -v offline | wc -l)" -le 2 ]]; then
    echo "Plug in your headset now, ensure USB debugging is enabled, and allow the USB connection to this PC. [press Enter to continue]"
    read anything
fi

stream
