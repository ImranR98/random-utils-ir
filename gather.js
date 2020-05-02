// gather.js
// Find all files in a source directory and all it's subdirectories and copy them to a destination path.

// fs module required
const fs = require('fs');

// getAllFiles.js needed to get all the files in a directory and all subdirectories
const getAllFiles = require('./funcs/getAllFiles')

if (process.argv.length <= 3) {
    console.log('This utility finds all files in a source directory and all it\'s subdirectories and copies them to a destination path.')
    console.log('Please provide the source and destinations paths as arguments.');
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
        getAllFiles.getAllFiles(process.argv[2]).forEach((file) => {
        	fs.copyFileSync(file.filePath, `${process.argv[3]}/${file.fileName}`)
    	})
        console.log(`Done - files in ${process.argv[2]} and all it's subdirectories have been gathered in ${process.argv[3]}`);
    }
}