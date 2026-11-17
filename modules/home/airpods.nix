{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.chena.airpods;

  librepods = pkgs.callPackage ../../packages/librepods { };
in
{
  options.chena.airpods.enable = lib.mkEnableOption ''
    AirPods support through LibrePods: pausing when they leave the ears,
    the noise control modes, conversation awareness and the battery levels
    in the tray. Pair them once in the Bluetooth settings first'';

  config = lib.mkIf (config.chena.enable && cfg.enable) {
    systemd.user.services.librepods = {
      Unit = {
        Description = "LibrePods AirPods controls";
        PartOf = [ config.wayland.systemd.target ];
        After = [ config.wayland.systemd.target ];
      };
      Service = {
        ExecStart = "${lib.getExe librepods} --hide";
        Restart = "on-failure";
      };
      Install.WantedBy = [ config.wayland.systemd.target ];
    };

    # Without a player, BlueZ does not take the play and pause commands that
    # pressing the stem sends. LibrePods asks not to run mpris-proxy with this.
    xdg.configFile."wireplumber/wireplumber.conf.d/51-chena-airpods.conf".text = ''
      monitor.bluez.properties = {
        bluez5.dummy-avrcp-player = true
      }
    '';
  };
}
