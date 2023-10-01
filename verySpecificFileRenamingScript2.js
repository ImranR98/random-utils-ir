/*
    This script renames all files in a directory and all its subdirectories
    It replaces hyphens with spaces and capitalizes the first letter of each word longer than 1 characters
    Some special cases excepted
*/

const fs = require('fs')

const dir = process.argv[2] || '.'

const processAllFilesInDirRecursive = (path, func) => {
    fs.readdirSync(path).forEach((fileName) => {
        filePath = path + '/' + fileName
        var stat = fs.statSync(filePath)
        stat && stat.isDirectory() ? processAllFilesInDirRecursive(filePath, func) : func(filePath)
    })
}

processAllFilesInDirRecursive(dir, (path) => {
    if (path.toLowerCase().endsWith('.md')) {
        const segments = path.split('/')
        const dir = segments.slice(0, segments.length - 1).join('/')
        const fn = segments[segments.length - 1].split('-').join(' ').split(' ').map(w => {
            if (w.length > 1 && !['to', 'of', 'for'].includes(w)) {
                w = w.slice(0, 1).toUpperCase() + w.slice(1)
            }
            if (/[0-9]+(a|A|p|P)(m|M)/.test(w) || ['nuc', 'pc', 'foss', 'todo'].includes(w.toLowerCase())) {
                w = w.toUpperCase()
            }
            return w
        }).join(' ').replace('to do', 'To Do')
        fs.renameSync(path, dir + '/' + fn)
    }
})