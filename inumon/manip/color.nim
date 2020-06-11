import ../coreTypes
import arraymancer

## Impliments colorimetric (perceptual luminance-preserving) conversion to grayscale
proc RGBtoL*(image: Image): Image =

    if image.colorType != RGB:
        raise newException(IOError, "Input image not RGB")

    result = image
    result.colorType = L
    result.data = newTensor[int](image.size.height, image.size.width, 1)

    for y in 0..<image.size.height:
        for x in 0..<image.size.width:
            result.data[y, x, 0] = toInt(0.21*image.data[y, x, 0].float) + toInt(0.21*image.data[y, x, 1].float) + toInt(0.07*image.data[y, x, 2].float)

## Impliments colorimetric (perceptual luminance-preserving) conversion to grayscale, preserving alpha
proc RGBAtoLA*(image: Image): Image =

    if image.colorType != RGBA:
        raise newException(IOError, "Input image not RGBA")

    result = image
    result.colorType = LA
    result.data = newTensor[int](image.size.height, image.size.width, 2)

    for y in 0..<image.size.height:
        for x in 0..<image.size.width:
            result.data[y, x, 0] = toInt(0.21*image.data[y, x, 0].float) + toInt(0.21*image.data[y, x, 1].float) + toInt(0.07*image.data[y, x, 2].float)
            result.data[y, x, 1] = image.data[y, x, 3]