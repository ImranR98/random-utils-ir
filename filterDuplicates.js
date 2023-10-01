// filterDuplicates.js

// Compare the files in two given directories A (reference) and B (target)
// For every file in B for which there is no file in A with the same name and size, move that file from B to a given destination directory C (non-duplicates)
// Provided that name and size is an indicator of duplicates, this means B will be left with files that are dupicated in A, with the rest having been moved to C
// If the nameOnly option is true, size will be ignored
// If the fuzzy option is true, files with the same name and sizes within 1.2kb of each other will be considered duplicates

// Imports
const fs = require('fs')

// Configuration
const referenceDir = process.argv[2]
const targetDir = process.argv[3]
const nonDuplicateDestinationDir = process.argv[4]
const nameOnly = true
const fuzzy = true

// Helper Functions
const validateDir = (dirPath) => {
    if (!fs.existsSync(dirPath) || !fs.statSync(dirPath).isDirectory())
        throw `This is not a valid directory: ${dirPath}`
}
const readDirWithSizes = (dirPath) => fs.readdirSync(dirPath).map(file => {
    const stats = fs.statSync(`${dirPath}/${file}`)
    if (!stats.isFile()) return null
    return { file, size: stats.size }
}).filter(file => !!file)

// Main Process
validateDir(referenceDir)
validateDir(targetDir)
validateDir(nonDuplicateDestinationDir)
const refFiles = readDirWithSizes(referenceDir)
const tgtFiles = readDirWithSizes(targetDir)
console.log(`Comparing ${refFiles.length} reference files with ${tgtFiles.length} target files...`)
const nonDuplicates = tgtFiles.filter(file => !refFiles.find(refFile =>
    refFile.file === file.file &&
        nameOnly ? true :
        fuzzy ?
            (Math.abs(refFile.size - file.size) <= 1200) :
            (refFile.size === file.size)
))
nonDuplicates.forEach(file => fs.renameSync(`${targetDir}/${file.file}`, `${nonDuplicateDestinationDir}/${file.file}`))