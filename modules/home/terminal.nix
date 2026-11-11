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
    chena.programs.terminal = lib.getExe config.programs.ghostty.package;

    programs.ghostty = {
      enable = true;
      package = pkgs.ghostty;
      settings = {
        font-family = [
          style.font.mono
          style.font.cjk
        ];
        font-size = style.fontSize.normal;

        background = style.colors.background;
        foreground = style.colors.text;
        cursor-color = style.colors.text;
        selection-background = style.colors.selection;
        selection-foreground = style.colors.text;
        palette = lib.imap0 (index: color: "${toString index}=${color}") style.terminal;

        # Hyprland draws the blur, so Ghostty does not ask for its own.
        background-opacity = style.translucency.window.opacity;
        background-blur = false;
        window-padding-x = style.spacing.md;
        window-padding-y = style.spacing.md;
      };
    };
  };
}
