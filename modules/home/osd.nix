{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (config.chena) style;
  inherit (style) colors;
  inherit (import ../../lib/css.nix) px;
  border = "${px style.layout.border} solid";
  radius = px style.layout.radius;

  osd = lib.getExe' config.services.swayosd.package "swayosd-client";

  # brightnessctl changes the backlight through logind, which needs no extra
  # permissions. SwayOSD changing it itself would need udev rules and the
  # video group, so it only shows the new level here.
  brightness = pkgs.writeShellApplication {
    name = "chena-brightness";
    runtimeInputs = [
      pkgs.brightnessctl
      pkgs.coreutils
      pkgs.gawk
    ];
    text = ''
      percent=$(brightnessctl -e4 -n2 -m set "$1" | cut -d, -f4 | tr -d '%')
      ${osd} \
        --custom-icon display-brightness-symbolic \
        --custom-progress "$(awk -v p="$percent" 'BEGIN { printf "%.2f", p / 100 }')" \
        --custom-progress-text "$percent%"
    '';
  };
in
{
  config = lib.mkIf config.chena.enable {
    chena.programs = {
      inherit osd;
      brightness = lib.getExe brightness;
    };

    services.swayosd = {
      enable = true;
      stylePath = "${config.xdg.configHome}/swayosd/style.css";
    };

    xdg.configFile."swayosd/style.css".text = ''
      window#osd {
        background: ${colors.surface};
        border: ${border} ${colors.border};
        border-radius: ${radius};
      }

      window#osd #container {
        margin: ${px style.spacing.lg} ${px style.spacing.xl};
      }

      window#osd image,
      window#osd label {
        color: ${colors.text};
      }

      window#osd progressbar:disabled,
      window#osd image:disabled {
        opacity: 0.5;
      }

      window#osd progressbar,
      window#osd segmentedprogress {
        min-height: ${px style.layout.progress};
        border-radius: ${radius};
        background: transparent;
        border: none;
      }

      window#osd trough,
      window#osd segment {
        min-height: inherit;
        border-radius: ${radius};
        border: none;
        background: ${colors.border};
      }

      window#osd progress,
      window#osd segment.active {
        min-height: inherit;
        border-radius: ${radius};
        border: none;
        background: ${colors.accent};
      }

      window#osd segment {
        margin-left: ${px style.spacing.sm};
      }

      window#osd segment:first-child {
        margin-left: 0;
      }
    '';
  };
}
