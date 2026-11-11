{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.chena.enable {
    chena.programs.screenshot = "${lib.getExe pkgs.hyprshot} --freeze --clipboard-only --mode";

    home.packages = [ pkgs.wl-clipboard ];
  };
}
