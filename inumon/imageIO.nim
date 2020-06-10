import wrappers/libpng
import wrappers/libjpeg
import coreTypes
import arraymancer
import strutils

## Reads only PNG images given a filename.
proc loadPNG*(fn: string): Image =

    var fp = open(fn)

    # Create image and image info containers
    let png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, nil, nil, nil);
    let info_ptr = png_create_info_struct(png_ptr)

    # Load image and read info
    png_init_io(png_ptr, fp)
    png_read_png(png_ptr, info_ptr, PNG_TRANSFORM_IDENTITY, nil)
    
    # Set result info based on image info
    let width = cast[int](png_get_image_width(png_ptr, info_ptr))
    let height = cast[int](png_get_image_height(png_ptr, info_ptr))
    result.size = (width: width, height: height)

    # Set color type according to header
    var channels = 0
    let color_type = cast[int](png_get_color_type(png_ptr, info_ptr))
    case color_type:
        of 0:
            result.colorType = L
            channels = 1
        of 2:
            result.colorType = RGB
            channels = 3
        of 4:
            result.colorType = LA
            channels = 2
        of 6:
            result.colorType = RGBA
            channels = 4
        else:
            raise newException(IOError, "Unknown color type")
        
    # Set bit depth according to header
    result.bitDepth = cast[int](png_get_bit_depth(png_ptr, info_ptr))

    # Read rows of image
    let rawRows = png_get_rows(png_ptr, info_ptr)
    let rows = cast[ptr UncheckedArray[ptr UncheckedArray[cuchar]]](rawRows)

    # Copy rows into tensor
    result.data = newTensor[int](height, width, channels)
    for y in 0..<height:
        for x in 0..<width:
            for c in 0..<channels:
                result.data[y, x, c] = cast[int](rows[y][(x*channels)+c])

    fp.close()

## Writes an image object to a file.
proc writePNG*(image: Image, fn: string) =
    let fp = open(fn, fmWrite)

    # Create and init
    let png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, nil, nil, nil)
    let info_ptr = png_create_info_struct(png_ptr)
    png_init_io(png_ptr, fp)

    # Convenient casted versions of image size and bitdepth
    let width = cast[png_uint_32](image.size.width)
    let height = cast[png_uint_32](image.size.height)
    let bitDepth = cast[cint](image.bitDepth)

    # Convert color type to int for writing
    var color = 0
    case image.colorType:
        of L:
            color = 0
        of RGB:
            color = 2
        of LA:
            color = 4
        of RGBA:
            color = 6

    # Write PNG header
    png_set_IHDR(png_ptr, info_ptr, width, height,
         bitDepth, cast[cint](color), PNG_INTERLACE_NONE,
         PNG_COMPRESSION_TYPE_BASE, PNG_FILTER_TYPE_BASE)
    
    png_write_info(png_ptr, info_ptr)

    # Write data from tensor to file in rows
    for row in 0..<image.size.height:
        var tmp = cast[ptr UncheckedArray[cuchar]](alloc(image.size.width * image.data.shape[2] * sizeof(cuchar)))
        for col in 0..<image.size.width:
            for c in 0..<image.data.shape[2]:
                tmp[(col*image.data.shape[2]) + c] = cast[cuchar](image.data[row, col, c].uint)

        png_write_row(png_ptr, cast[png_bytep](tmp))
    
    png_write_end(png_ptr, nil)
    fp.close()

## Reads only JPEG images given a filename.
proc loadJPEG*(fn: string): Image =
    let fp = open(fn)

    # Inititalize the decompressor and various info variables
    let jpegDecompressor = tjInitDecompress()
    let fSize = fp.getFileSize()
    let fString = fp.readAll().cstring
    let jpegBuf = cast[ptr cuchar](fstring)

    var width: cint
    var height: cint
    var jpegSubsamp: cint
    var jpegColorspace: cint
    var jpegSize = cast[culong](fSize)

    # Load the header info
    if cast[int](tjDecompressHeader3(jpegDecompressor, jpegBuf, jpegSize, width.addr, height.addr, jpegSubsamp.addr, jpegColorspace.addr)) == -1:
        echo tjGetErrorStr2(jpegDecompressor)

    # Set image size from header info
    result.size = (width: cast[int](width), height: cast[int](height))
    
    # Load and decompress image
    var imgBuf = cast[ptr cuchar](alloc(result.size.width * result.size.height * 3))
    if cast[int](tjDecompress2(jpegDecompressor, jpegBuf, jpegSize, imgBuf, width, cast[cint](0), height, cast[cint](0), TJFLAG_ACCURATEDCT)) == -1:
        echo tjGetErrorStr2(jpegDecompressor)
    
    let vals = cast[ptr UncheckedArray[cuchar]](imgBuf)
    
    # Write image data to tensor
    result.data = newTensor[int](height.int, width.int, 3)
    for y in 0..<height.int:
        for x in 0..<width.int:
            for c in 0..<3:
                result.data[y, x, c] = vals[(width*y*3) + (x*3) + c].int
    
    # Set final info
    result.colorType = RGB
    result.bitDepth = 8

## Writes an image to a JPEG given quality (1-100).
proc writeJPEG*(image: Image, fn: string, quality: int) =

    # Make sure it's a 3 channel (RGB) image
    if image.data.shape[2] != 3:
        raise newException(IOError, "Only RGB images are supported for JPEG write")
    
    # Flatten data into buffer
    var tmp = cast[ptr UncheckedArray[cuchar]](alloc(image.size.width * image.size.height * 3 * sizeof(cuchar)))
    var count = 0
    for y in 0..<image.size.height:
        for x in 0..<image.size.width:
            for c in 0..<3:
                tmp[count] = image.data[y, x, c].cuchar
                count += 1
    
    # Init compressor and useful variables
    let jpegCompressor = tjInitCompress()

    var output: ptr cuchar
    var jpegSize: culong

    # Compress image data
    if tjCompress2(jpegCompressor, cast[ptr cuchar](tmp), image.size.width.cint, 0.cint, image.size.width.cint, 0.cint,
          output.addr, jpegSize.addr, 0.cint, quality.cint, 0.cint).int == -1:
              echo tjGetErrorStr2(jpegCompressor)
    
    # Write to image
    let fp = open(fn, fmWrite)
    discard fp.writeBuffer(output, jpegSize.int)
    fp.close()

## Read an image file (PNG or JPEG) to an Image object. Infers the image format before reading.
proc loadImage*(fn: string): Image =
    let extension = fn.split('.')[^1]
    
    case extension:
        of "png":
            return loadPNG(fn)
        of "jpeg":
            return loadJPEG(fn)
        of "jpg":
            return loadJPEG(fn)
        else:
            raise newException(IOError, "Unsupported filetype")