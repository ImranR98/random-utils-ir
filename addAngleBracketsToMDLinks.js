// addAngleBracketsToMDLinks.js
// Markdown links of the form [...](...) may not be interpreted correctly my some apps if the URI has spaces
// This is fixed by wrapping the URI in angled brackets
// This script goes over all links in all MD files in a directory and its subdirectories recursively and makes this change where needed

const fs = require('fs')

const DEBUG = false

const getChangesForFile = (filePath) => {
    var res = fs.readFileSync(filePath).toString().split('\n').map((e, i) => { return { line: i, res: /\[[^\[]*\]\([^<][^\(]*\)/.exec(e) } }).filter(e => e.res != null)
    res = res.map(e => {
        const firstIndex = e.res['input'].indexOf('](') + 2
        const secondIndex = e.res['index'] + e.res[0].length
        const chars = [...e.res['input']]
        chars.splice(firstIndex, 0, '<')
        chars.splice(secondIndex, 0, '>')
        return { line: e.line, res: chars.join('') }
    })
    return res
}

const applyChangesToFile = (filePath, changes) => {
    if (DEBUG) {
        console.log(changes)
    } else {
        let lines = fs.readFileSync(filePath).toString().split('\n')
        changes.forEach(change => {
            lines[change.line] = change.res
        })
        fs.writeFileSync(filePath, lines.join('\n'))
    }
}

const runFuncOverAllFilesRecursive = (path, func) => {
    fs.readdirSync(path).forEach((fileName) => {
        filePath = path + '/' + fileName
        var stat = fs.statSync(filePath)
        stat && stat.isDirectory() ? results = runFuncOverAllFilesRecursive(filePath, func) : func(filePath)
    })
}

const addAngleBracketsToMDLinks = (mdDir) => {
    runFuncOverAllFilesRecursive(mdDir, (filePath) => {
        if (filePath.toLowerCase().endsWith('.md')) {
            const changes = getChangesForFile(filePath)
            if (changes.length > 0) {
                applyChangesToFile(filePath, changes)
            }
        }
    })
}

if (!process.argv[2]) {
    throw 'Provide path to MD dir'
}

addAngleBracketsToMDLinks(process.argv[2])