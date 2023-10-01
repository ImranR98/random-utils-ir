// Deletes all empty directories in a directory and all it's subdirectories, recursively until no empty directories remain
const fs = require('fs')

// Get paths of all empty directories in a directory and all it's subdirectories
const getEmptyDirs = (path) => {
    let results = []
    fs.readdirSync(path).forEach((fileName) => {
        filePath = path + '/' + fileName
        if (fs.statSync(filePath).isDirectory()) {
            if (fs.readdirSync(filePath).length == 0) results.push(filePath)
            else results = results.concat(getEmptyDirs(filePath))
        }
    })
    return results
}

// Delete all empty directories in a directory and all it's subdirectories, recursively until no empty directories remain
const recursivelyDeleteEmptyDirs = (path) => {
    let emptyDirs = getEmptyDirs(path)
    while (emptyDirs.length > 0) {
        emptyDirs.forEach(dir => {
            console.log(`Deleting ${dir}`)
            fs.rmdirSync(dir)
        })
        emptyDirs = getEmptyDirs(path)
    }
}

if (process.argv.length < 3) console.log(`Usage: node deleteEmptyDirs.js <path>`)

recursivelyDeleteEmptyDirs(process.argv[2])