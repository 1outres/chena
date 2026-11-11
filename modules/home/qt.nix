{ config, lib, ... }:

let
  inherit (config.chena) style;

  font = size: ''"${style.font.mono},${toString size}"'';

  # qt5ct and qt6ct read the same settings, so Qt 5 and Qt 6 apps match.
  ctSettings = {
    Appearance = {
      style = "kvantum";
      icon_theme = style.icons.name;
      standard_dialogs = "xdgdesktopportal";
    };
    Fonts = {
      fixed = font style.fontSize.small;
      general = font style.fontSize.small;
    };
  };
in
{
  config = lib.mkIf config.chena.enable {
    qt = {
      enable = true;
      platformTheme.name = "qtct";
      style.name = "kvantum";
      qt5ctSettings = ctSettings;
      qt6ctSettings = ctSettings;

      kvantum = {
        enable = true;
        themes = [ style.kvantum.package ];
        settings.General.theme = style.kvantum.name;
      };
    };
  };
}
