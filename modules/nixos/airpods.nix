{ config, lib, ... }:

{
  options.chena.airpods.appleDeviceId = lib.mkEnableOption ''
    telling Bluetooth devices that this machine is made by Apple. AirPods
    allow multipoint and the hearing features only for Apple devices.
    LibrePods notes that this is at your own risk, and other devices may act
    differently once they see it. Pair the AirPods again after turning it on'';

  config = lib.mkIf (config.chena.enable && config.chena.airpods.appleDeviceId) {
    hardware.bluetooth.settings.General.DeviceID = "bluetooth:004C:0000:0000";
  };
}
