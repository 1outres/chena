{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (config.chena) style;
  inherit (style) colors;
  border = "${toString style.layout.border}px solid";

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
        border-radius: 0;
      }

      window#osd #container {
        margin: 12px 16px;
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
        min-height: 6px;
        border-radius: 0;
        background: transparent;
        border: none;
      }

      window#osd trough,
      window#osd segment {
        min-height: inherit;
        border-radius: 0;
        border: none;
        background: ${colors.border};
      }

      window#osd progress,
      window#osd segment.active {
        min-height: inherit;
        border-radius: 0;
        border: none;
        background: ${colors.accent};
      }

      window#osd segment {
        margin-left: 4px;
      }

      window#osd segment:first-child {
        margin-left: 0;
      }
    '';
  };
}
