{ config, lib, ... }:

{
  imports = [
    ../shared/style.nix
    ../shared/brightness.nix
    ../shared/wallpaper.nix
    ./boot.nix
    ./greeter.nix
  ];

  options.chena.enable = lib.mkEnableOption "the chena desktop";

  config = lib.mkIf config.chena.enable {
    programs.hyprland.enable = true;

    # Adds the PAM service that hyprlock checks the password with.
    programs.hyprlock.enable = true;

    # Nautilus needs this for the trash and for removable disks.
    services.gvfs.enable = true;
  };
}
