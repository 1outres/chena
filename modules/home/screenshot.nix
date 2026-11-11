{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (config.chena) style;
  inherit (style) colors;

  hyprshot = lib.getExe pkgs.hyprshot;

  edit = pkgs.writeShellApplication {
    name = "chena-screenshot-edit";
    runtimeInputs = [ pkgs.satty ];
    text = ''
      ${hyprshot} --freeze --raw --mode region | satty --filename -
    '';
  };
in
{
  config = lib.mkIf config.chena.enable {
    chena.programs = {
      screenshot = "${hyprshot} --freeze --clipboard-only --mode";
      screenshot_edit = lib.getExe edit;
    };

    home.packages = [ pkgs.wl-clipboard ];

    xdg.configFile."satty/config.toml".source = (pkgs.formats.toml { }).generate "satty-config" {
      general = {
        copy-command = "wl-copy";
        corner-roundness = style.layout.radius;
        early-exit = true;
        actions-on-enter = [ "save-to-clipboard" ];
      };
      font.family = style.font.mono;
      color-palette.palette = [
        colors.accent
        colors.secondary
        colors.info
        colors.success
        colors.warning
        colors.error
      ];
    };
  };
}
