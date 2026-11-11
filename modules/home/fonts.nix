{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.chena.enable {
    home.packages = [
      pkgs.nerd-fonts.jetbrains-mono
      pkgs.noto-fonts-cjk-sans
    ];

    fonts.fontconfig.enable = true;
  };
}
