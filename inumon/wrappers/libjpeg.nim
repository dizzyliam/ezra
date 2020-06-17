import nimterop/[build, cimport]

{.passl: gorge("pkg-config libturbojpeg --cflags --libs").}

setDefines(@["turbojpegStd"])

const
  baseDir = getProjectCacheDir("libjpeg") 

cPlugin:
  import strutils

  proc onSymbol*(sym: var Symbol) {.exportc, dynlib.} =
    sym.name = sym.name.strip(chars = {'_'}).replace("__", "_")

    if sym.name in ["tjtransform"]:
        sym.name = "l_" & sym.name

getHeader("turbojpeg.h", giturl="https://github.com/libjpeg-turbo/libjpeg-turbo", outdir=baseDir)

cImport(turbojpegPath, recurse=true, flags="-c -s")