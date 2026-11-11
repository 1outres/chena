{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (config.chena) style;
in
{
  config = lib.mkIf config.chena.enable {
    programs.ghostty = {
      enable = true;
      package = pkgs.ghostty;
      settings = {
        font-family = [
          style.font.mono
          style.font.cjk
        ];
        font-size = style.font.size;

        background = style.colors.background;
        foreground = style.colors.text;
        cursor-color = style.colors.text;
        selection-background = style.colors.selection;
        selection-foreground = style.colors.text;
        palette = lib.imap0 (index: color: "${toString index}=${color}") style.terminal;

        background-opacity = 1;
        background-blur = false;
        window-padding-x = 6;
        window-padding-y = 6;
      };
    };
  };
}
