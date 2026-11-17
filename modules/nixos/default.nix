{ config, lib, ... }:

{
  imports = [
    ../shared/style.nix
    ../shared/brightness.nix
    ../shared/wallpaper.nix
    ./boot.nix
    ./greeter.nix
    ./bluetooth.nix
  ];

  options.chena.enable = lib.mkEnableOption "the chena desktop";

  config = lib.mkIf config.chena.enable {
    programs.hyprland.enable = true;

    # Adds the PAM service that hyprlock checks the password with.
    programs.hyprlock.enable = true;

    # Nautilus needs this for the trash and for removable disks.
    services.gvfs.enable = true;

    # The Secret Service. Without it, 1Password forgets the 2FA of the device
    # and asks for it again on every new session.
    services.gnome.gnome-keyring.enable = true;
    # gnome-keyring turns this on, but chena does not pick the SSH agent.
    services.gnome.gcr-ssh-agent.enable = lib.mkDefault false;
  };
}
