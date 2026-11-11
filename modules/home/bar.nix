{ config, lib, ... }:

let
  inherit (config.chena) style;
  inherit (style) colors;
  inherit (import ../../lib/css.nix) px pt;

  workspaceCount = lib.length config.chena.workspaces.keys;

  # Workspace ids run on through the monitors: the first has 1 to 9, the next
  # 10 to 18. Each bar should count from 1, so every range gets the same labels.
  workspaceLabels = lib.listToAttrs (
    lib.concatMap (
      monitor:
      lib.genList (
        index: lib.nameValuePair (toString (monitor * workspaceCount + index + 1)) (toString (index + 1))
      ) workspaceCount
    ) (lib.range 0 3)
  );
in
{
  config = lib.mkIf (config.chena.enable && config.chena.shell == "chena") {
    chena.blurredLayers = [ "waybar" ];

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
            "bluetooth"
            "network"
            "wireplumber"
            "battery"
          ];

          "hyprland/workspaces" = {
            format = "{icon}";
            format-icons = workspaceLabels;
            on-scroll-up = "hyprctl dispatch 'hl.dsp.focus({ workspace = \"m+1\" })'";
            on-scroll-down = "hyprctl dispatch 'hl.dsp.focus({ workspace = \"m-1\" })'";
          };

          clock = {
            format = "{:%a %d %b  %H:%M}";
            tooltip-format = "<tt>{calendar}</tt>";
          };

          tray = {
            icon-size = style.icon.small;
            spacing = style.spacing.md;
          };

          bluetooth = {
            format = "󰂯";
            format-off = "󰂲";
            format-disabled = "󰂲";
            format-connected = "󰂱  {num_connections}";
            tooltip-format-connected = "{device_enumerate}";
            tooltip-format-enumerate-connected = "{device_alias}";
            on-click = config.chena.programs.bluetooth;
          };

          network = {
            on-click = config.chena.programs.network;
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
          font-size: ${pt style.fontSize.normal};
          border: none;
          border-radius: ${px style.layout.radius};
          min-height: 0;
        }

        window#waybar {
          background-color: ${style.panel.css};
          color: ${colors.text};
          border-bottom: ${px style.layout.border} solid ${colors.border};
        }

        tooltip {
          background-color: ${colors.surface};
          border: ${px style.layout.border} solid ${colors.border};
        }

        tooltip label {
          color: ${colors.text};
        }

        #workspaces button {
          padding: 0 ${px style.spacing.md};
          color: ${colors.muted};
          background: transparent;
          border-bottom: ${px style.layout.border} solid transparent;
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
        #bluetooth,
        #network,
        #wireplumber,
        #battery {
          padding: 0 ${px style.spacing.lg};
        }

        #bluetooth.off,
        #bluetooth.disabled,
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
