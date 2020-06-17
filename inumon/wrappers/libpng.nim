import nimterop/[build, cimport]

{.passl: gorge("pkg-config libpng --cflags --libs").}

setDefines(@["pngStd"])

const
  baseDir = getProjectCacheDir("libpng") 

static:
  cSkipSymbol(@["png_struct", "png_info"])
  cDebug()

cPlugin:
  import strutils

  proc onSymbol*(sym: var Symbol) {.exportc, dynlib.} =
    sym.name = sym.name.strip(chars = {'_'}).replace("__", "_")

getHeader("png.h", giturl="https://github.com/glennrp/libpng", outdir=baseDir)

cImport(pngPath, recurse=true, flags="-c -s")