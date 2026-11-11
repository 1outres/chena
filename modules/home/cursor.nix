{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.chena.cursor;
in
{
  options.chena.cursor = {
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.adwaita-icon-theme;
      defaultText = lib.literalExpression "pkgs.adwaita-icon-theme";
      description = "Package that provides the cursor theme.";
    };
    name = lib.mkOption {
      type = lib.types.str;
      default = "Adwaita";
      description = "Cursor theme name.";
    };
    size = lib.mkOption {
      type = lib.types.int;
      default = 24;
      description = "Cursor size.";
    };
  };

  # Without a cursor theme Hyprland draws its own built-in fallback cursor.
  config.home.pointerCursor = lib.mkIf config.chena.enable {
    enable = true;
    inherit (cfg) package name size;
  };
}
