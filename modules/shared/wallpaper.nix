{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.chena;

  shrink = pkgs.callPackage ../../packages/wallpaper { };
in
{
  options.chena = {
    wallpaper = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = lib.literalExpression "./wallpaper.png";
      description = ''
        Image for the desktop, the lock screen and the login screen. Null shows
        the theme's desktop color. The NixOS and the Home Manager modules each
        read their own copy of this option, so set it on both.
      '';
    };

    wallpaperImage = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      readOnly = true;
      internal = true;
      default = if cfg.wallpaper == null then null else shrink cfg.wallpaper;
      description = "The wallpaper as the screens load it.";
    };
  };
}
