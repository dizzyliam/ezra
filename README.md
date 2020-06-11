<p align="center">
  <img src="media/banner.png"></img>
</p>

<h3 align="center">
  A high-level image I/O and manipulation library for Nim
  <br>
  - <del>Documentation</del> (soon) | <a href="recipes.md">Recipes</a> -
</h3>

---
## Features
- [x] PNG read/write
- [x] JPEG read/write (only RGB supported)
- [x] High-level pixel manipulation with *arraymancer*
- [X] Image display with *nigui*
- Basic image transforms:
  - [X] Reshape/scale
  - [x] Change between color types
  - [ ] Hue/saturation/value (soon)

## Installation

Install from nimble with:

`nimble install inumon`

### External dependencies
Image read/write currently requires *libpng* and *libjpeg-turbo*. They will likely already be installed on your system, but you can make sure with the following commands.

**Arch based:**
`sudo pacman -Syu libpng libjpeg-turbo`

**Debian based:**
`sudo apt-get install libpng-dev libjpeg-turbo`

*Windows support is untested*
