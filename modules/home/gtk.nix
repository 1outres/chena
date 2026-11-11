{ config, lib, ... }:

let
  inherit (config.chena) style;
in
{
  config = lib.mkIf config.chena.enable {
    gtk = {
      enable = true;
      theme = style.gtk;
      iconTheme = style.icons;
      font = {
        name = style.font.mono;
        size = style.fontSize.small;
      };
      gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
      gtk4.theme = style.gtk;
    };

    # libadwaita apps ignore the GTK theme and read this instead.
    dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
  };
}
