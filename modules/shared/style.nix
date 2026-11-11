{
  config,
  lib,
  pkgs,
  ...
}:

let
  themes = lib.mapAttrs' (
    file: _:
    lib.nameValuePair (lib.removeSuffix ".nix" file) (import ../../themes/${file} { inherit pkgs; })
  ) (builtins.readDir ../../themes);

  theme = themes.${config.chena.theme};

  color = import ../../lib/color.nix { inherit lib; };

  translucency = {
    panel = 50;
    window = 80;
  };
in
{
  options.chena = {
    theme = lib.mkOption {
      type = lib.types.enum (lib.attrNames themes);
      default = "dracula";
      description = ''
        Color theme. Each file in `themes/` is one theme. Set the same theme
        in the NixOS and the Home Manager configuration.
      '';
    };

    style = lib.mkOption {
      type = lib.types.attrs;
      readOnly = true;
      description = ''
        Design tokens that every component reads, so they all share the same
        colors, fonts, sizes and shapes. Other modules can read them too, to
        match the desktop. Colors come from the theme. Everything else is the
        same for every theme.
      '';
    };
  };

  config.chena.style = {
    inherit (theme)
      colors
      terminal
      gtk
      icons
      kvantum
      syntax
      ;

    # The same colors as rgb(RRGGBB), the form that Hyprland and its tools read.
    hyprColors = lib.mapAttrs (_: color: "rgb(${lib.removePrefix "#" color})") theme.colors;

    font = {
      mono = "JetBrainsMono Nerd Font";
      cjk = "Noto Sans CJK JP";
    };

    # Points.
    fontSize = {
      small = 10;
      normal = 11;
      large = 14;
      xlarge = 20;
      display = 64;
    };

    # Pixels, on a 4 pixel grid.
    spacing = {
      xs = 2;
      sm = 4;
      md = 8;
      lg = 12;
      xl = 16;
    };

    # Pixels.
    icon = {
      small = 16;
      large = 32;
    };

    layout = {
      gapsIn = 2;
      gapsOut = 4;
      border = 2;
      hairline = 1;
      radius = 0;
      progress = 6;
    };

    # How much of each kind of surface is opaque, in percent. The wallpaper
    # shows through the rest, and the compositor blurs what is behind it.
    # Panels float over the desktop for a moment, such as the bar and the
    # launcher. Windows are read for a long time, such as the terminal, so
    # they stay darker. Apps such as the browser stay solid.
    translucency =
      lib.mapAttrs (_: percent: {
        inherit percent;
        opacity = color.fraction percent;
      }) translucency
      // {
        blur = {
          size = 6;
          passes = 2;
        };
      };

    # The panel color at the panel opacity, in each form the components read.
    panel = {
      css = color.css theme.colors.surface translucency.panel;
      hex = color.hex theme.colors.surface translucency.panel;
      hypr = color.hypr theme.colors.surface translucency.panel;
    };
  };
}
