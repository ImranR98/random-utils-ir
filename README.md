# random-utils-ir
A random set of utilities - mostly written in Node.js.
> Run `npm i` before running any of the Node scripts.

## keepToMD
Convert Google Keep Notes (from Google Takeout) into MarkDown format.
### Usage
`node keepToMD.js <path to Google Keep Takeout directory> <path to empty destination directory for MD files>`

## gather
Find all files in a source directory and all it's subdirectories and copy them to a destination path.
### Usage
`node gather.js <origin directory path> <destination directory path>`

## compare
Compare the files, by file name, between a source and comparison directory (and all their respective subdirectories), then list files that exist in the souce but not the comparison directory.
### Usage
`node compare.js <source directory path> <comparison directory path>`

## imageHueShift
Shift image hues for an image.
### Usage
`node imageHueShift.js <image path> <hue shift number (0-255)>`
