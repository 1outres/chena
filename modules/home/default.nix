{ lib, ... }:

{
  imports = [
    ../shared/style.nix
    ./fonts.nix
    ./cursor.nix
    ./gtk.nix
    ./qt.nix
    ./terminal.nix
    ./cli.nix
    ./bar.nix
    ./launcher.nix
    ./notifications.nix
    ./osd.nix
    ./lock.nix
    ./power.nix
    ./polkit.nix
    ./tools.nix
    ./apps.nix
    ./input-method.nix
    ./wallpaper.nix
    ./screenshot.nix
    ./brightness.nix
    ./shoji.nix
    ./hyprland
  ];

  options.chena = {
    enable = lib.mkEnableOption "the chena desktop";

    shell = lib.mkOption {
      type = lib.types.enum [
        "chena"
        "shoji-bar-4"
      ];
      default = "chena";
      description = ''
        The shell around the windows: the bar, the launcher, the
        notifications, the OSD, the lock screen and the wallpaper. "chena" is
        Waybar, Walker, mako, SwayOSD, hyprlock and hyprpaper, themed from the
        tokens. "shoji-bar-4" is one Material 3 shell for all of them, colored
        from the theme's accent.
      '';
    };

    programs = lib.mkOption {
      # Lazy because a command here can be built from other commands here.
      type = lib.types.lazyAttrsOf lib.types.str;
      default = { };
      internal = true;
      description = ''
        Commands that the key bindings run, keyed by role. Each component
        adds its own, so the bindings never need to know which program
        fills a role.
      '';
    };

    blurredLayers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      internal = true;
      description = ''
        Layer namespaces that the compositor blurs behind. Each translucent
        panel adds its own.
      '';
    };
  };
}
