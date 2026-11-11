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
in
{
  options.chena = {
    theme = lib.mkOption {
      type = lib.types.enum (lib.attrNames themes);
      default = "dracula";
      description = "Color theme. Each file in `themes/` is one theme.";
    };

    style = lib.mkOption {
      type = lib.types.attrs;
      readOnly = true;
      internal = true;
      description = ''
        Design tokens that every component reads, so they all share the same
        colors, fonts and shapes. Colors come from the theme. Fonts and
        layout are the same for every theme.
      '';
    };
  };

  config.chena.style = {
    inherit (theme) colors terminal gtk;

    # The same colors as rgb(RRGGBB), the form that Hyprland and its tools read.
    hyprColors = lib.mapAttrs (_: color: "rgb(${lib.removePrefix "#" color})") theme.colors;

    font = {
      mono = "JetBrainsMono Nerd Font";
      cjk = "Noto Sans CJK JP";
      size = 11;
    };

    layout = {
      gapsIn = 2;
      gapsOut = 4;
      border = 2;
      radius = 0;
    };
  };
}
