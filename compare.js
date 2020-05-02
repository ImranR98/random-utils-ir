// compare.js
// Compare the files, by file name, between a source and comparison directory (and all their respective subdirectories), then list files that exist in the souce but not the comparison directory.

// getAllFiles.js needed to get all the files in a directory and all subdirectories
const getAllFiles = require('./funcs/getAllFiles')

if (process.argv.length <= 3) {
    console.log('This utility compares the files, by file name, between a source and comparison directory (and all their respective subdirectories), then list files that exist in the souce but not the comparison directory.')
    console.log('Please provide the source and comparison paths as arguments.');
} else {
    if (process.argv[2].indexOf('/') == process.argv[2].length - 1) {
        process.argv[2] = process.argv[2].slice(0, process.argv[2].length - 1);
    }
    if (process.argv[3].indexOf('/') == process.argv[3].length - 1) {
        process.argv[3] = process.argv[2].slice(0, process.argv[3].length - 1);
    }
    if (!((process.argv[2][0] == '.' || process.argv[2][0] == '/') && (process.argv[3][0] == '.' || process.argv[3][0] == '/'))) {
        console.log('One or both of the provided paths is not valid.')
    } else {
        let sourceFiles = getAllFiles.getAllFiles(process.argv[2])
        let comparisonFiles = getAllFiles.getAllFiles(process.argv[3])
        let diff = sourceFiles.filter(srcFile => !comparisonFiles.find(cmpFile.fileName == srcFile.fileName))
        diff.forEach(file => console.log(file.filePath))
        console.log(`${diff.length} file names in ${process.argv[2]} were not found in ${process.argv[3]}. Files are listed above.`);
    }
}