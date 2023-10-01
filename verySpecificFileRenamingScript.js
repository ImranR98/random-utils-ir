/*

Picture this:
1. You have a bunch of MarkDown files, each of which has some images in it.
2. The images are stored in separate directories based on the MD file they are referenced from (no image is referenced from more than one file)
3. Each image directory has the same name as the MD file its contents are referenced from.
4. Many images are named 'Untitled.png', 'Untitled 1.png', ...
5. This means there are several different 'Untitled.png' (for example) in many different directories.

You would like to:
1. Rename all 'Untitled' images so that no two 'Untitled' files share the same name, even across different directories.
2. Update the image references in the MD files based on the renaming in the previous step.

This script does that. Yes, a very specific use case for a one-time need that I'll probably never use again but I kept it because you never know.
Directory path is hardcoded and there are no safety checks to ensure it exists.

Note that while I mentioned images above (since those are my intended targets),
this script will grab anything that starts with 'Untitled' and is in a subdirectory named after a MD file in the specified directory.

*/

const fs = require('fs')

const path = process.argv[2]

let replacements = []

const letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z']
let letterIndex = 0

fs.readdirSync(path).forEach(file => {
    if (fs.statSync(`${path}/${file}`).isDirectory()) {
        const charToAdd = letterIndex < 26 ? letters[letterIndex] : letterIndex - 25
        replacements.push({ find: `${encodeURIComponent(file)}/Untitled`, replace: `${encodeURIComponent(file)}/Untitled${charToAdd}` })
        fs.readdirSync(`${path}/${file}`).forEach(innerFile => {
            if (innerFile.startsWith('Untitled')) {
                const newFile = 'Untitled' + charToAdd + innerFile.slice(8)
                fs.renameSync(`${path}/${file}/${innerFile}`, `${path}/${file}/${newFile}`)
            }
        })
        letterIndex++
    }
})

fs.readdirSync(path).forEach(file => {
    if (!fs.statSync(`${path}/${file}`).isDirectory() && file.toLowerCase().endsWith('.md')) {
        let data = fs.readFileSync(`${path}/${file}`).toString()
        replacements.forEach(replacement => {
            data = data.split(replacement.find).join(replacement.replace)
        })
        fs.writeFileSync(`${path}/${file}`, data)
    }
})