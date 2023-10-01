// getAllFiles.js
// Get an array of path and file names for all files in a directory and all it's subdirectories

// fs module required
const fs = require('fs');

// Get paths of all Files in a directory and all it's subdirectories
module.exports.getAllFiles = (path) => {
    let results = [];
    fs.readdirSync(path).forEach((fileName) => {
        filePath = path + '/' + fileName;
        var stat = fs.statSync(filePath);
        stat && stat.isDirectory() ? results = results.concat(this.getAllFiles(filePath)) : results.push({ filePath, fileName });
    });
    return results;
}