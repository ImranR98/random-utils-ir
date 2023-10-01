const fs = require('fs')

const filesDir = './files'
const destinationPath = './KeepExport.md'

let files

// Get list of files
files = fs.readdirSync(filesDir)

// Filter out non markdown files
files = files.filter(file => file.endsWith('.md'))

// Read file content
files = files.map(file => {
    return {
        path: filesDir + '/' + file,
        content: fs.readFileSync(filesDir + '/' + file).toString()
    }
})

// Find file date if it was a Google Keep export, and use the date as the title if it has no title
files = files.map(file => {
    let lines = file.content.split('\n')
    let dateIndex = -1
    if (lines.length > 5) {
        if (lines[0].startsWith('#')) {
            if (lines[1].startsWith('```')) {
                if (lines[2].startsWith('Imported from Google Keep on ') && lines[4].startsWith('Last Modified: ')) {
                    dateIndex = 4
                }
            }
        } else if (lines[0].startsWith('```')) {
            if (lines[1].startsWith('Imported from Google Keep on ') && lines[3].startsWith('Last Modified: ')) {
                dateIndex = 3
            }
        }
    }
    if (dateIndex > -1) {
        file.date = new Date(lines[dateIndex].slice(14))
    } else {
        file.date = null
    }
    if (dateIndex == 3) {
        file.content = `# ${file.date.toUTCString()}\n` + file.content
    }
    return file
})

// Filter out non Google Keep exports
files = files.filter(file => {
    if (file.date == null) console.log(file.path)
    return file.date != null
})

// Sort files based on date
files = files.sort((a, b) => b.date - a.date)

// Combine the files and save
let combined = `# Google Keep Export
From ${files[files.length - 1].date.toUTCString()} to ${files[0].date.toUTCString()} - descending.




`
files.forEach(file => {
    combined += file.content.trim() + '\n\n\n\n\n'
})
fs.writeFileSync(destinationPath, combined)