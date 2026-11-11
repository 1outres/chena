{ lib, ... }:

{
  options.chena.brightness.fixed = lib.mkOption {
    type = lib.types.ints.between 1 100;
    default = 70;
    description = ''
      Backlight level in percent for the disk password prompt and the login
      screen, whatever level the last session used. The session gets its own
      level back after login. Set the same value in the NixOS and the Home
      Manager configuration.
    '';
  };
}
