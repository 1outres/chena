{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.chena;
  sessions = config.services.displayManager.sessionData.desktops;
in
{
  imports = [ ../shared/style.nix ];

  options.chena.enable = lib.mkEnableOption "the chena desktop";

  config = lib.mkIf cfg.enable {
    programs.hyprland.enable = true;

    # Adds the PAM service that hyprlock checks the password with.
    programs.hyprlock.enable = true;

    # Start the session from the files that the Hyprland module registers, so
    # this keeps working when Hyprland changes how it should be launched.
    services.greetd = {
      enable = true;
      settings.default_session.command = lib.concatStringsSep " " [
        (lib.getExe pkgs.tuigreet)
        "--time"
        "--remember"
        "--remember-session"
        "--sessions ${sessions}/share/wayland-sessions"
      ];
    };
  };
}
