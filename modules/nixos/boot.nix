{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.chena;

  plymouthTheme = pkgs.callPackage ../../packages/plymouth-theme { inherit (cfg) style; };

  fixedBrightness = pkgs.callPackage ../../packages/fixed-brightness {
    level = cfg.brightness.fixed;
  };
in
{
  config = lib.mkIf cfg.enable {
    boot.plymouth = {
      enable = true;
      theme = "chena";
      themePackages = [ plymouthTheme ];
      font = "${pkgs.nerd-fonts.jetbrains-mono}/share/fonts/truetype/NerdFonts/JetBrainsMono/JetBrainsMonoNerdFont-Regular.ttf";
      # The theme picks 1x or 2x images itself.
      extraConfig = "DeviceScale=1";
    };

    # The disk password prompt comes before the saved level is restored, so
    # the panel would keep whatever level the firmware left. Set the level as
    # soon as the backlight shows up in the initrd.
    boot.initrd.services.udev.rules = ''
      ACTION=="add", SUBSYSTEM=="backlight", RUN+="${fixedBrightness} /sys%p"
    '';
    boot.initrd.systemd.storePaths = [ fixedBrightness ];
  };
}
