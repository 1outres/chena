{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (config.chena) style;
  colors = style.hyprColors;

  pidof = lib.getExe' pkgs.procps "pidof";
  loginctl = lib.getExe' pkgs.systemd "loginctl";
  hyprlock = lib.getExe config.programs.hyprlock.package;

  # A bare string such as hl.dsp.dpms("off") is read as "toggle", so the
  # action has to be passed in a table. This keeps that detail in one place.
  screen = pkgs.writeShellApplication {
    name = "chena-screen";
    text = ''
      case "$1" in
        on | off) hyprctl dispatch "hl.dsp.dpms({ action = \"$1\" })" ;;
        *)
          echo "usage: chena-screen on|off" >&2
          exit 2
          ;;
      esac
    '';
  };
  screenCommand = action: "${lib.getExe screen} ${action}";

  label =
    settings:
    {
      monitor = "";
      font_family = style.font.mono;
      halign = "center";
      valign = "center";
    }
    // settings;
in
{
  config = lib.mkIf config.chena.enable {
    # Locking goes through logind, so hypridle's lock_cmd is the one place
    # that starts hyprlock.
    chena.programs.lock = "${loginctl} lock-session";

    programs.hyprlock = {
      enable = true;
      settings = {
        general = {
          hide_cursor = true;
          ignore_empty_input = true;
        };

        background = [
          (
            {
              monitor = "";
              color = colors.desktop;
            }
            // lib.optionalAttrs (config.chena.wallpaper != null) {
              path = "${config.chena.wallpaperImage}";
              # Darker, so the clock can be read on a bright image.
              brightness = 0.6;
            }
          )
        ];

        label = [
          (label {
            text = "cmd[update:1000] date +%H:%M";
            color = colors.text;
            font_size = style.fontSize.display;
            position = "0, 140";
          })
          (label {
            text = "cmd[update:60000] date '+%A %d %B'";
            color = colors.text;
            font_size = style.fontSize.large;
            position = "0, 70";
          })
        ];

        input-field = [
          {
            monitor = "";
            size = "320, 44";
            position = "0, -20";
            halign = "center";
            valign = "center";
            outline_thickness = style.layout.border;
            rounding = style.layout.radius;
            outer_color = colors.border;
            inner_color = style.panel.hypr;
            font_color = colors.text;
            font_family = style.font.mono;
            check_color = colors.accent;
            fail_color = colors.error;
            capslock_color = colors.warning;
            placeholder_text = "password";
            fail_text = "$FAIL";
            fade_on_empty = false;
            dots_size = 0.25;
            dots_spacing = 0.3;
            dots_rounding = style.layout.radius;
          }
        ];
      };
    };

    services.hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd = "${pidof} hyprlock || ${hyprlock}";
          before_sleep_cmd = "${loginctl} lock-session";
          after_sleep_cmd = screenCommand "on";
        };

        listener = [
          {
            timeout = 300;
            on-timeout = "${loginctl} lock-session";
          }
          {
            timeout = 330;
            on-timeout = screenCommand "off";
            on-resume = screenCommand "on";
          }
        ];
      };
    };
  };
}
