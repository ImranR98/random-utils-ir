/*
    This script merges top level headings and removes trailing data from MD files exported from Notesnook
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
        const fn = segments[segments.length - 1]
        const headingIndices = []
        const lines = fs.readFileSync(path).toString().split('\n')
        for (let i = 0; i < lines.length; i++) {
            if (lines[i].indexOf('# ') == 0) {
                headingIndices.push(i)
            } else if (lines[i].trim().length > 0) {
                break
            }
        }
        headingIndices.forEach(h => {
            if (/^[0-9]+ /.test(fn) && lines[h].slice(2).trim().replace(' - ', ' ').toLowerCase() == fn.slice(0, -3).toLowerCase()) {
                lines[h] = '# ' + lines[h].slice(lines[h].indexOf(' - ') + 3)
            }
        })
        const finalH = headingIndices.length > 0 ? lines[headingIndices[0]] : '# ' + fn.slice(0, -3)
        headingIndices.forEach((h,j) => {
            lines.splice(h-j, 1)
        })
        const finalString = finalH + '\n\n' + lines.slice(0,-5).join('\n').trim()
        fs.writeFileSync(path, finalString)
    }
})