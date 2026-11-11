{ config, lib, ... }:

let
  inherit (config.chena) style;
  inherit (style) colors;
in
{
  config = lib.mkIf config.chena.enable {
    services.mako = {
      enable = true;
      settings = {
        font = "${style.font.mono}, ${style.font.cjk} ${toString (style.font.size - 1)}";
        background-color = colors.surface;
        text-color = colors.text;
        border-color = colors.border;
        progress-color = "over ${colors.selection}";
        border-size = style.layout.border;
        border-radius = style.layout.radius;

        anchor = "top-right";
        layer = "overlay";
        margin = style.layout.gapsOut;
        padding = 10;
        width = 360;
        max-icon-size = 32;
        default-timeout = 5000;

        "urgency=low".text-color = colors.muted;

        "urgency=critical" = {
          border-color = colors.error;
          default-timeout = 0;
        };
      };
    };
  };
}
