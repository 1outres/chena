{ lib, pkgs, ... }:

let
  noop = lib.getExe' pkgs.coreutils "true";
in
{
  home = {
    username = "preview";
    # The preview runs as the real user with this as HOME. Paths here end up
    # in the generated configs, so the preview script must use the same one.
    homeDirectory = "/tmp/chena-preview/home";
    stateVersion = "26.05";
  };

  chena = {
    enable = true;
    shell = "chena";

    # preview.lua sets the one monitor from the size the script asks for.
    monitors = [ ];
    extraLua.preview = ./preview.lua;

    # These set the brightness of the real screen.
    programs = {
      session_start = lib.mkForce noop;
      session_end = lib.mkForce noop;
    };
  };

  # This would stop and start hyprland-session.target in a systemd user
  # manager. The preview script starts the services itself.
  wayland.windowManager.hyprland.systemd.enable = false;
}
