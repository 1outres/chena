{ config, lib, ... }:

{
  config = lib.mkIf config.chena.enable {
    # The pair button in the shell only asks BlueZ to pair, and BlueZ does not
    # keep a pairing it makes while it is not pairable. With no agent, BlueZ
    # still turns down pairing that another device starts.
    hardware.bluetooth.settings.General.AlwaysPairable = true;
  };
}
