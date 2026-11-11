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
    ./hyprland
  ];

  options.chena.enable = lib.mkEnableOption "the chena desktop";
}
