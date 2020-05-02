// Required Node module to interact with file system
const fs = require('fs')
// Description and usage strings
const description = 'Convert Google Keep Notes (from Google Takeout) into MarkDown format.'
const usage = `Usage: ${process.argv[0].split('/').reverse()[0]} ${process.argv[1].split('/').reverse()[0]} <path to Google Keep Takeout directory> <path to empty destination directory for MD files>`

// Function to escape MarkDown special characters
const escapeMarkDownCharacters = str => str.split('\\').join('\\\\').split('`').join('\\`').split('*').join('\\*')
    .split('_').join('\\_').split('{').join('\\{').split('}').join('\\}').split('[').join('\\[').split(']').join('\\]').split('(').join('\\(')
    .split(')').join('\\)').split('#').join('\\#').split('+').join('\\+').split('-').join('\\-').split('.').join('\\.').split('!').join('\\!')

// Validate arguments
if (process.argv.length < 4) {
    console.log(description)
    console.log(usage)
    process.exit(-1)
} else {
    process.argv.forEach(arg => {
        if (arg.toLowerCase() == '-h' || arg.toLowerCase() == '--help') {
            console.log(description)
            console.log(usage)
            console.log('Remove the help option (-h or --help) to run the command.')
            process.exit(-1)
        }
    })
    let valid1 = fs.existsSync(process.argv[2])
    let valid2 = fs.existsSync(process.argv[3])
    if (valid1) valid1 = fs.statSync(process.argv[2]).isDirectory()
    if (valid2) valid2 = fs.statSync(process.argv[3]).isDirectory()
    if (!valid1 || !valid2) {
        console.log('One or both arguments are not paths to valid directories.')
        process.exit(-2)
    }
    if (fs.readdirSync(process.argv[3]).length > 0) {
        console.log('Destination directory is not empty. Please provide an empty directory.')
        process.exit(-3)
    }
}

// Load all valid JSON files from the target directory that have valid Google Keep format
let keepFiles = fs.readdirSync(process.argv[2]).filter(file => file.endsWith('.json'))
console.log(`${keepFiles.length} JSON file${keepFiles.length == 1 ? '' : 's'} found in ${process.argv[2]}.`)
keepFiles = keepFiles.map(file => {
    try {
        let jsonData = JSON.parse(fs.readFileSync(process.argv[2] + file).toString())
        jsonData.finalFileName = file.split('.')
        jsonData.finalFileName.pop()
        jsonData.finalFileName = jsonData.finalFileName.join('.') + '.md'
        let valid = (jsonData.color != undefined && jsonData.isTrashed != undefined &&
            jsonData.isPinned != undefined && jsonData.isArchived != undefined &&
            jsonData.title != undefined && jsonData.userEditedTimestampUsec != undefined)
        if (valid) {
            if (jsonData.listContent) {
                jsonData.listContent.forEach(listItem => {
                    if (listItem.text == undefined || listItem.isChecked == undefined) valid = false
                });
            }
            if (jsonData.attachments) {
                jsonData.attachments.forEach(attachment => {
                    if (attachment.filePath == undefined) valid = false
                });
            }
            if (jsonData.labels) {
                jsonData.labels.forEach(label => {
                    if (label.name == undefined) valid = false
                });
            }
        }
        jsonData.modifiedDate = new Date(jsonData.userEditedTimestampUsec / 1000)
        if (!valid) console.log(`Error parsing file: ${file} - the JSON does not match Google Keep format and will be ignored.`)
        return valid ? jsonData : null
    } catch (err) {
        console.log(`Error parsing file: ${file} - it is not valid JSON and will be ignored.`)
        return null
    }
}).filter(file => !!file)
console.log(`${keepFiles.length} Google Keep note${keepFiles.length == 1 ? '' : 's'} loaded.`)

// Create subdirectories to store pinned, archived, and trashed notes
if (!fs.existsSync(`${process.argv[3]}/pinned`)) fs.mkdirSync(`${process.argv[3]}/pinned`)
else if (!fs.statSync(`${process.argv[3]}/pinned`).isDirectory()) fs.mkdirSync(`${process.argv[3]}/pinned`)
if (!fs.existsSync(`${process.argv[3]}/archived`)) fs.mkdirSync(`${process.argv[3]}/archived`)
else if (!fs.statSync(`${process.argv[3]}/archived`).isDirectory()) fs.mkdirSync(`${process.argv[3]}/archived`)
if (!fs.existsSync(`${process.argv[3]}/trashed`)) fs.mkdirSync(`${process.argv[3]}/trashed`)
else if (!fs.statSync(`${process.argv[3]}/trashed`).isDirectory()) fs.mkdirSync(`${process.argv[3]}/trashed`)

// Grab data from every note to build an .md file and save it
console.log('Converting to MD...')
keepFiles.forEach(file => {
    try {
        let finalMDText = ''
        if (file.title) finalMDText += `# ${escapeMarkDownCharacters(file.title)}\n`
        finalMDText += `\`\`\`\nImported from Google Keep on ${new Date().toString()}\nColor: ${file.color}\nLast Modified: ${file.modifiedDate.toString()}\n`
        if (file.attachments) {
            file.attachments.forEach(attachment => {
                finalMDText += `Attachment: ${attachment.filePath}\n`
            })
        }
        if (file.labels) {
            file.labels.forEach(label => {
                finalMDText += `Label: ${label.name}\n`
            })
        }
        finalMDText += `\`\`\`\n`
        if (file.textContent) finalMDText += `${escapeMarkDownCharacters(file.textContent.split('\n').join('\n\n'))}\n\n`
        if (file.listContent) {
            file.listContent.forEach(listItem => finalMDText += `- ${listItem.isChecked ? '☑' : '☐'} ${escapeMarkDownCharacters(listItem.text)}\n`)
            finalMDText += '\n'
        }

        if (file.isPinned) {
            fs.writeFileSync(`${process.argv[3]}/pinned/${file.finalFileName}`, finalMDText)
            fs.utimesSync(`${process.argv[3]}/pinned/${file.finalFileName}`, file.modifiedDate, file.modifiedDate)
        } else if (file.isArchived) {
            fs.writeFileSync(`${process.argv[3]}/archived/${file.finalFileName}`, finalMDText)
            fs.utimesSync(`${process.argv[3]}/archived/${file.finalFileName}`, file.modifiedDate, file.modifiedDate)
        } else if (file.isTrashed) {
            fs.writeFileSync(`${process.argv[3]}/trashed/${file.finalFileName}`, finalMDText)
            fs.utimesSync(`${process.argv[3]}/trashed/${file.finalFileName}`, file.modifiedDate, file.modifiedDate)
        } else {
            fs.writeFileSync(`${process.argv[3]}/${file.finalFileName}`, finalMDText)
            fs.utimesSync(`${process.argv[3]}/${file.finalFileName}`, file.modifiedDate, file.modifiedDate)
        }
    } catch (err) {
        console.log(`Error converting file: ${file.finalFileName}.`)
    }
})

console.log('Done!')