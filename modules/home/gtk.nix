{ config, lib, ... }:

let
  inherit (config.chena) style;
in
{
  config = lib.mkIf config.chena.enable {
    gtk = {
      enable = true;
      theme = style.gtk;
      font = {
        name = style.font.mono;
        size = style.font.size - 1;
      };
      gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    };

    # libadwaita apps ignore the GTK theme and read this instead.
    dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
  };
}
