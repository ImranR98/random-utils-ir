// Finds all files ending with a specific extension (or one of a specific set of extensions) in a specific directory and its subdirectories
const fs = require('fs')

// Run a function on all files in a directory and its subdirectories
const processAllFiles = (path, func) => {
    fs.readdirSync(path).forEach((fileName) => {
        filePath = path + '/' + fileName
        var stat = fs.statSync(filePath)
        stat && stat.isDirectory() ? results = processAllFiles(filePath, func) : func(filePath)
    })
}

// Print a string (meant to be a path to a file) if it ends with one of the extensions in a specific array of extensions
const printFileIfType = (filePath, extensions) => {
    let print = false
    for (let i = 0; i < extensions.length; i++) {
        if (filePath.endsWith(`.${extensions[i].toLowerCase()}`)) print = true
    }
    if (print) console.log(filePath)
}

if (process.argv.length < 4) console.log(`Usage: node findByType.js <directory> <extension 1> <extension 2> ...`)

const extensions = process.argv.splice(3)

processAllFiles(process.argv[2], (filePath) => {
    printFileIfType(filePath, extensions)
})