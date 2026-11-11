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

  isChena = config.chena.shell == "chena";

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
  config = lib.mkIf config.chena.enable (
    lib.mkMerge [
      {
        # optionalAttrs and not mkIf, since chena.programs is lazy and keeps a
        # name that mkIf turns off.
        chena.programs = lib.optionalAttrs isChena {
          volume_up = "${osd} --output-volume raise --max-volume 100";
          volume_down = "${osd} --output-volume lower";
          volume_mute = "${osd} --output-volume mute-toggle";
          mic_mute = "${osd} --input-volume mute-toggle";
          media_next = "${osd} --playerctl next";
          media_play_pause = "${osd} --playerctl play-pause";
          media_previous = "${osd} --playerctl prev";
          brightness = lib.getExe brightness;
        };
      }

      (lib.mkIf isChena {
        chena.blurredLayers = [ "swayosd" ];

        services.swayosd = {
          enable = true;
          stylePath = "${config.xdg.configHome}/swayosd/style.css";
        };

        xdg.configFile."swayosd/style.css".text = ''
          window#osd {
            background: ${style.panel.css};
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
      })
    ]
  );
}
