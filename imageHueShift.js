// Changes the hue of the specified image
const Jimp = require('jimp')

const imageChangeHue = (image, hue, outputFile) => {
    return new Promise((resolve, reject) => {
        image
            .color([{ apply: 'hue', params: [hue] }])
            .write(outputFile, () => {
                resolve()
            })
    })
}

const run = async () => {
    if (process.argv.length <= 3)
        throw 'Provide the image path and hue in degrees (between -360 and 360) as arguments, in that order.'
    image = await Jimp.read(process.argv[2])
    let hue;
    try {
        hue = Number.parseInt(process.argv[3])
    } catch (err) {
        throw 'Error - please ensure the second argument is a number.'
    }
    if (hue < -360 || hue > 360)
        throw 'Please pick a number between -360 and 360.'

    await imageChangeHue(image, hue, process.argv[2])
}

run()