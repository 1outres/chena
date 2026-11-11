{ config, lib, ... }:

let
  cfg = config.chena;
in
{
  imports = [ ../shared/wallpaper.nix ];

  config = lib.mkIf (cfg.enable && cfg.shell == "chena" && cfg.wallpaper != null) {
    services.hyprpaper = {
      enable = true;
      settings = {
        ipc = false;
        splash = false;
        wallpaper = [
          {
            monitor = "";
            path = "${cfg.wallpaperImage}";
            fit_mode = "cover";
          }
        ];
      };
    };
  };
}
