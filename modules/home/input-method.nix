{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (config.chena) style;

  theme = pkgs.callPackage ../../packages/fcitx5-theme { inherit style; };

  font = "${style.font.mono}, ${style.font.cjk} ${toString style.fontSize.normal}";
in
{
  config = lib.mkIf config.chena.enable {
    xdg.dataFile."fcitx5/themes/chena".source = theme;

    # fcitx5 writes this file from memory when it exits, so a link has to
    # replace whatever it left behind.
    xdg.configFile."fcitx5/conf/classicui.conf" = {
      force = true;
      text = ''
        Theme=chena
        DarkTheme=chena
        UseAccentColor=False
        Font="${font}"
        MenuFont="${font}"
      '';
    };
  };
}
