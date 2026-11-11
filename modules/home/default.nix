{ lib, ... }:

{
  imports = [
    ./style.nix
    ./fonts.nix
    ./cursor.nix
    ./gtk.nix
    ./terminal.nix
    ./bar.nix
    ./launcher.nix
    ./notifications.nix
    ./osd.nix
    ./hyprland
  ];

  options.chena = {
    enable = lib.mkEnableOption "the chena desktop";

    programs = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
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
