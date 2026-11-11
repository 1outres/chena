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
    ./hyprland
  ];

  options.chena = {
    enable = lib.mkEnableOption "the chena desktop";

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
  };
}
