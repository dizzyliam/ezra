import arraymancer

type

    ## All supported color types.
    colorTypes* = enum
        L, RGB, LA, RGBA

    ## General image object that can hold any color type or size.
    ## Bit depth is just for convenience.
    Image* = object
        size*: tuple[width, height: int]
        bitDepth*: int
        colorType*: colorTypes
        data*: Tensor[int]