/**
 * Markdown files may contain images embedded as base64 encoded strings
 * This script extracts all such images in all .md files in a specified directory
 * Images are saved in an 'assets/' directory and the markdown files are modified accordingly
 * Used for Notesnook export
 */

const fs = require('fs')

const processAllFilesInDirRecursive = (path, func) => {
    fs.readdirSync(path).forEach((fileName) => {
        filePath = path + '/' + fileName
        var stat = fs.statSync(filePath)
        stat && stat.isDirectory() ? processAllFilesInDirRecursive(filePath, func) : func(filePath)
    })
}

const extractBase64ImagesFromMD = (filePath, imageDir) => {
    const imageStartChars = '!['
    const imageMidAndDataStartChars = '](<data:image/'
    const base64Chars = ';base64,'
    const imageDataLastChars = '>'
    const imageData = fs.readFileSync(filePath).toString().split('\n').map((e, i) => { return { line: e, index: i } })
        .filter(e => e.line.includes(imageStartChars) && e.line.includes(imageMidAndDataStartChars))
        .map(e => { e.line = e.line.trim(); return e })
        .map(e => {
            e.line = e.line.slice(e.line.indexOf(imageStartChars));
            e.originalLine = e.line; e.line = e.line.slice(0, e.line.lastIndexOf(imageDataLastChars));
            return e
        })
        .map(e => {
            let filename = e.line.slice(2, e.line.indexOf(imageMidAndDataStartChars))
            const fileext = e.line.slice(e.line.indexOf(imageMidAndDataStartChars) + imageMidAndDataStartChars.length, e.line.indexOf(base64Chars))
            if (filename.toLowerCase().endsWith('.' + fileext)) {
                filename = filename.slice(0, -4)
            }
            filename += Math.floor(Math.random() * 1000).toString() + '.' + fileext
            return {
                index: e.index,
                filename,
                filedata: e.line.slice(
                    e.line.indexOf(imageMidAndDataStartChars) + imageMidAndDataStartChars.length + fileext.length + base64Chars.length,
                    e.line.lastIndexOf(imageDataLastChars)
                ),
                originalLine: e.originalLine,
                replacementLine: imageStartChars + filename + '](' + imageDir + '/' + filename + ')'
            }
        })
    imageData.forEach(e => {
        fs.writeFileSync(filePath, fs.readFileSync(filePath).toString().replace(e.originalLine, e.replacementLine))
        fs.writeFileSync(imageDir + '/' + e.filename, Buffer.from(e.filedata, 'base64'))
    })
}


extractBase64ImagesFromMDsInDir = (mdDir) => {
    const pngDir = mdDir + '/assets'
    if (!fs.existsSync(pngDir)) {
        fs.mkdirSync(pngDir)
    }
    processAllFilesInDirRecursive(mdDir, (path) => {
        if (path.toLowerCase().endsWith('.md')) {
            extractBase64ImagesFromMD(path, pngDir)
        }
    })
}

extractBase64ImagesFromMDsInDir(process.argv[2] || '.')