{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.chena;

  systemctl = lib.getExe' pkgs.systemd "systemctl";

  # Reboot and shutdown go through the same exit as logout, so apps close
  # cleanly and the session saves its brightness first.
  power = pkgs.writeShellApplication {
    name = "chena-power";
    text = ''
      choice=$(printf '%s\n' Lock Logout Reboot Shutdown | ${cfg.programs.menu} --dmenu --placeholder Power)
      case "$choice" in
        Lock) ${cfg.programs.lock} ;;
        Logout) ${cfg.programs.shutdown} ;;
        Reboot) ${cfg.programs.shutdown} --post-cmd '${systemctl} reboot' ;;
        Shutdown) ${cfg.programs.shutdown} --post-cmd '${systemctl} poweroff' ;;
      esac
    '';
  };
in
{
  config = lib.mkIf cfg.enable {
    chena.programs.power = lib.getExe power;
  };
}
