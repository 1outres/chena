{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.chena;

  # The window rules float this class, so these open as small panels.
  floating = command: "${cfg.programs.terminal} --class=chena.floating -e ${command}";
in
{
  config = lib.mkIf cfg.enable {
    chena.programs = {
      network = floating (lib.getExe' pkgs.networkmanager "nmtui");
      bluetooth = floating (lib.getExe pkgs.bluetui);
    };
  };
}
