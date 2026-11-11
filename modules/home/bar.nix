{ config, lib, ... }:

let
  inherit (config.chena) style;
  inherit (style) colors;
in
{
  config = lib.mkIf config.chena.enable {
    programs.waybar = {
      enable = true;
      systemd.enable = true;

      settings = [
        {
          layer = "top";
          position = "top";
          height = 26;
          spacing = 0;

          modules-left = [ "hyprland/workspaces" ];
          modules-center = [ "clock" ];
          modules-right = [
            "tray"
            "network"
            "wireplumber"
            "battery"
          ];

          "hyprland/workspaces" = {
            format = "{id}";
            on-scroll-up = "hyprctl dispatch 'hl.dsp.focus({ workspace = \"e+1\" })'";
            on-scroll-down = "hyprctl dispatch 'hl.dsp.focus({ workspace = \"e-1\" })'";
          };

          clock = {
            format = "{:%a %d %b  %H:%M}";
            tooltip-format = "<tt>{calendar}</tt>";
          };

          tray = {
            icon-size = 14;
            spacing = 8;
          };

          network = {
            format-wifi = "󰤨  {essid}";
            format-ethernet = "󰈀  wired";
            format-disconnected = "󰤭  offline";
            tooltip-format = "{ifname}  {ipaddr}";
          };

          wireplumber = {
            format = "󰕾  {volume}%";
            format-muted = "󰝟  muted";
          };

          battery = {
            format = "{icon}  {capacity}%";
            format-charging = "󰂄  {capacity}%";
            format-icons = [
              "󰂎"
              "󰁺"
              "󰁻"
              "󰁼"
              "󰁽"
              "󰁾"
              "󰁿"
              "󰂀"
              "󰂁"
              "󰂂"
              "󰁹"
            ];
            states = {
              warning = 25;
              critical = 10;
            };
          };
        }
      ];

      style = ''
        * {
          font-family: "${style.font.mono}", "${style.font.cjk}";
          font-size: ${toString style.font.size}pt;
          border: none;
          border-radius: 0;
          min-height: 0;
        }

        window#waybar {
          background-color: ${colors.surface};
          color: ${colors.text};
          border-bottom: ${toString style.layout.border}px solid ${colors.border};
        }

        tooltip {
          background-color: ${colors.surface};
          border: ${toString style.layout.border}px solid ${colors.border};
        }

        tooltip label {
          color: ${colors.text};
        }

        #workspaces button {
          padding: 0 8px;
          color: ${colors.muted};
          background: transparent;
          border-bottom: ${toString style.layout.border}px solid transparent;
          box-shadow: none;
          text-shadow: none;
        }

        #workspaces button:hover {
          background: ${colors.selection};
        }

        #workspaces button.active {
          color: ${colors.text};
          border-bottom-color: ${colors.accent};
        }

        #workspaces button.urgent {
          color: ${colors.error};
        }

        #clock,
        #tray,
        #network,
        #wireplumber,
        #battery {
          padding: 0 10px;
        }

        #network.disconnected,
        #wireplumber.muted {
          color: ${colors.muted};
        }

        #battery.charging {
          color: ${colors.success};
        }

        #battery.warning:not(.charging) {
          color: ${colors.warning};
        }

        #battery.critical:not(.charging) {
          color: ${colors.error};
        }
      '';
    };
  };
}
