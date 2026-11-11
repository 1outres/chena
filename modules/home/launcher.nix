{ config, lib, ... }:

let
  inherit (config.chena) style;
  inherit (style) colors spacing fontSize;
  inherit (import ../../lib/css.nix) px pt;
  border = "${px style.layout.border} solid";
  radius = px style.layout.radius;
in
{
  config = lib.mkIf config.chena.enable {
    # Walker only draws the window. Elephant finds the apps, files and other
    # results, and both stay running so the launcher opens at once.
    services.elephant.enable = true;

    chena.blurredLayers = [ "walker" ];

    chena.programs = {
      menu = lib.getExe config.services.walker.package;
      clipboard = "${lib.getExe config.services.walker.package} --provider clipboard";
      emoji = "${lib.getExe config.services.walker.package} --provider symbols";
    };

    services.walker = {
      enable = true;
      systemd.enable = true;

      settings = {
        close_when_open = true;
        force_keyboard_focus = true;
      };

      # Layout files that are not given here come from Walker's default theme.
      theme = {
        name = "chena";
        style = ''
          * {
            all: unset;
            font-family: "${style.font.mono}", "${style.font.cjk}";
            font-size: ${pt fontSize.normal};
            color: ${colors.text};
          }

          popover {
            background: ${colors.surface};
            border: ${border} ${colors.border};
            border-radius: ${radius};
            padding: ${px spacing.md};
          }

          .normal-icons {
            -gtk-icon-size: ${px style.icon.small};
          }

          .large-icons {
            -gtk-icon-size: ${px style.icon.large};
          }

          scrollbar {
            opacity: 0;
          }

          .box-wrapper {
            background: ${style.panel.css};
            border: ${border} ${colors.border};
            border-radius: ${radius};
            padding: ${px spacing.lg};
          }

          .input {
            background: ${colors.background};
            caret-color: ${colors.accent};
            padding: ${px spacing.md} ${px spacing.lg};
            margin-bottom: ${px spacing.md};
          }

          .input placeholder,
          .placeholder,
          .elephant-hint {
            color: ${colors.muted};
          }

          .input selection {
            background: ${colors.selection};
          }

          .item-box {
            padding: ${px spacing.sm} ${px spacing.md};
            border-left: ${border} transparent;
          }

          child:selected .item-box,
          row:selected .item-box {
            background: ${colors.selection};
            border-left: ${border} ${colors.accent};
          }

          .item-subtext {
            font-size: ${pt fontSize.small};
            color: ${colors.muted};
          }

          .item-quick-activation {
            color: ${colors.accent};
            padding: 0 ${px spacing.md};
          }

          .item-image-text {
            font-size: ${pt fontSize.xlarge};
          }

          .preview {
            border: ${border} ${colors.border};
            border-radius: ${radius};
          }

          .calc .item-text {
            font-size: ${pt fontSize.large};
          }

          .keybinds {
            padding-top: ${px spacing.md};
            border-top: ${border} ${colors.border};
            font-size: ${pt fontSize.small};
            color: ${colors.muted};
          }

          .keybind-label {
            padding: 0 ${px spacing.sm};
            border: ${px style.layout.hairline} solid ${colors.muted};
            border-radius: ${radius};
          }

          .error {
            padding: ${px spacing.md};
            background: ${colors.error};
            color: ${colors.background};
          }
        '';
      };
    };
  };
}
