# Recipes

This document contains various examples of what you can do with Inumon, and serves as a tutorial of sorts.

## Load an image, echo info, and display it
```Nim
import inumon

let img = loadImage("image.png")

echo img.size
echo img.bitDepth
echo img.colorType

img.showImage()
```
*Use left and right click to zoom in and out*

## Get a specific pixel of an image
```Nim
import inumon

let img = loadImage("image.png")
echo img.data[1, 2, _]
```

## Load a JPEG and save it as a PNG
```Nim
import inumon

let img = loadImage("input.jpg")
img.writePNG("output.png")
```

## Load an image and reshape it to half the width
```Nim
import inumon

let img = loadImage("image.png")
img.reshape(toInt(img.size.width/2), img.size.height).showImage()
```
*This only works if the target dimensions are factors of the source dimensions*

## Convert an RGB image to grayscale
```Nim

let img = loadImage("image.png")
img.RGBtoL().showImage()
```