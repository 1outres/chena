# Helpers that add an opacity to a theme color. Theme colors are #rrggbb and
# an opacity is a whole percent.
{ lib }:

let
  channel =
    color: offset: lib.fromHexString (builtins.substring offset 2 (lib.removePrefix "#" color));

  # Rounded to the nearest of 0 to 255.
  alphaHex =
    percent: lib.toLower (lib.fixedWidthString 2 "0" (lib.toHexString ((percent * 255 + 50) / 100)));

  # A decimal string such as "0.9", since Nix prints floats as "0.900000".
  fraction =
    percent:
    if percent == 100 then
      "1"
    else if lib.mod percent 10 == 0 then
      "0.${toString (percent / 10)}"
    else
      "0.${lib.fixedWidthNumber 2 percent}";
in
{
  inherit fraction;

  # rgba(33, 34, 44, 0.9), for CSS.
  css =
    color: percent:
    "rgba(${toString (channel color 0)}, ${toString (channel color 2)}, ${toString (channel color 4)}, ${fraction percent})";

  # #21222ce6, for mako and fcitx5.
  hex = color: percent: "${color}${alphaHex percent}";

  # rgba(21222ce6), for Hyprland and its tools.
  hypr = color: percent: "rgba(${lib.removePrefix "#" color}${alphaHex percent})";
}
