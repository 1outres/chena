{ config, lib, ... }:

{
  config = lib.mkIf config.chena.enable {
    # Without an agent, an app that asks for admin rights has nothing to show
    # the password prompt.
    services.hyprpolkitagent.enable = true;
  };
}
