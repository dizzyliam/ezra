import nigui
import os
import random
import strutils

import imageIO
import coreTypes

# Generate a unique identifyer to save the temp image under
proc generateUUID(): string =
    randomize()
    return intToStr(rand(999999999))

## Shows an image to the user, scaled for window size and zoom
proc showImage*(image: coreTypes.Image) =
    app.init()
    let uuid = generateUUID()

    # Make the subdir of /tmp if it doesn't exist already
    if not existsDir("/tmp/ezra"):
        createDir("/tmp/ezra")
    
    # Write temp image
    image.writePNG("/tmp/ezra" / uuid & ".png")

    # Make window, image, etc.
    var window = newWindow("Image")
    var control = newControl()
    window.add(control)
    var tmp = newImage()
    tmp.loadFromFile("/tmp/ezra" / uuid & ".png")

    # Draw image according to scale
    var scale = 0.75
    control.onDraw = proc (event: DrawEvent) =
        let canvas = event.control.canvas

        var scalar = 0.0
        if window.width <= window.height:
            scalar = (window.width / image.size.width) * scale
        else:
            scalar = (window.height / image.size.height) * scale

        let width = toInt(toFloat(image.size.width) * scalar)
        let height = toInt(toFloat(image.size.height) * scalar)

        let xOffset = toInt((window.width-width)/2)
        let yOffset = toInt((window.height-height)/2)

        canvas.drawImage(tmp, xOffset, yOffset, width, height)
    
    # Scale with mouseclick
    control.onMouseButtonDown = proc (event: MouseEvent) =
        case event.button:
            of MouseButton_Left:
                scale += 0.05
            of MouseButton_Right:
                scale -= 0.05
            else:
                discard
        
        if scale < 0.05:
            scale = 0.05
        
        control.forceRedraw()

    window.show()
    app.run()