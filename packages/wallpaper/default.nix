# Each monitor decodes the whole image, so a photo straight from a camera or
# a generator can take hundreds of MB. This shrinks it to the height of a 4K
# screen and leaves smaller images alone. The name ends in .png because some
# readers pick the decoder from the file name.
{ runCommand, imagemagick }:

source:

runCommand "chena-wallpaper.png" { nativeBuildInputs = [ imagemagick ]; } ''
  magick ${source} -resize 'x2160>' png:$out
''
