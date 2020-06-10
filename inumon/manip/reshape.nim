import ../coreTypes
import arraymancer

# Proc that handles reshaping things down in both axis
proc reshapeDown(image: Image, width, height: int): Image =
    let channels = image.data.shape[2]

    # Get out scaling factor and make sure it works
    let heightScaleRaw = image.size.height / height
    let widthScaleRaw = image.size.width / width

    let heightScale = toInt(floor(heightScaleRaw))
    let widthScale = toInt(floor(widthScaleRaw))

    if toFloat(heightScale) != heightScaleRaw or toFloat(widthScale) != widthScaleRaw:
        raise newException(IOError, "Image cannot be scaled to target size")
    
    # Copy over image data
    result = image
    result.data = newTensor[int](height, width, channels)
    result.size = (width: width, height: height)

    # Iterate over target pixels
    for y in 0..<height:
        for x in 0..<width:

            # Get group of source pixels that average to make target pixel
            let snippet = image.data[(y * heightScale)..<((y+1) * heightScale), 
                (x * widthScale)..<((x+1) * widthScale), _]
            
            var bin = newTensor[int](channels, widthScale*heightScale)

            # Put into nice rows
            var count = 0
            for sY in 0..<heightScale:
                for sX in 0..<widthScale:
                    for c in 0..<channels:
                        bin[c, count] = snippet[sY, sX, c]
                    count += 1
            
            # Average and set target pixel channel for every channel
            for c in 0..<channels:
                result.data[y, x, c] = toInt(sum(bin[c, _]) / (widthScale*heightScale))

# Proc that handles reshaping things up in both axis
proc reshapeUp(image: Image, width, height: int): Image =
    let channels = image.data.shape[2]

    # Get out scaling factor and make sure it works
    let heightScaleRaw = height / image.size.height
    let widthScaleRaw = width / image.size.width

    let heightScale = toInt(floor(heightScaleRaw))
    let widthScale = toInt(floor(widthScaleRaw))

    if toFloat(heightScale) != heightScaleRaw or toFloat(widthScale) != widthScaleRaw:
        raise newException(IOError, "Image cannot be scaled to target size")
    
    # Copy over image data
    result = image
    result.data = newTensor[int](height, width, channels)
    result.size = (width: width, height: height)

    # Set group of target pixels for every source pixel
    for y in 0..<image.size.height:
        for x in 0..<image.size.width:
            for a in 0..<heightScale:
                for b in 0..<widthScale:
                    for c in 0..<channels:
                        result.data[(y*heightScale) + a, (x*widthScale) + b, c] = image.data[y, x, c]

# The only reshape proc to be exported
## Reshape an image to any size using averaging for downscaling, and nearest neighbor for upscaling.
## The target sizes must be a factor or multiple of the original size.
proc reshape*(image: Image, width, height: int): Image =
    let imWidth = image.size.width
    let imHeight = image.size.height

    if width == imWidth and height == imHeight:
        return image
    elif (width < imWidth and height < imHeight) or
        (width < imWidth and height == imHeight) or
        (height < imHeight and width == imWidth):
            return image.reshapeDown(width, height)
    elif (width > imWidth and height > imHeight) or
        (width > imWidth and height == imHeight) or
        (height > imHeight and width == imWidth):
            return image.reshapeUp(width, height)
    
    elif height > imHeight and width < imWidth:
        return image.reshapeUp(imWidth, height).reshapeDown(width, height)
    elif height < imHeight and width > imWidth:
        return image.reshapeUp(width, imHeight).reshapeDown(width, height)