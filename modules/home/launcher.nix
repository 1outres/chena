{ config, lib, ... }:

let
  inherit (config.chena) style;
  inherit (style) colors;
  border = "${toString style.layout.border}px solid";
in
{
  config = lib.mkIf config.chena.enable {
    # Walker only draws the window. Elephant finds the apps, files and other
    # results, and both stay running so the launcher opens at once.
    services.elephant.enable = true;

    chena.programs.menu = lib.getExe config.services.walker.package;

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
            font-size: ${toString style.font.size}pt;
            color: ${colors.text};
          }

          popover {
            background: ${colors.surface};
            border: ${border} ${colors.border};
            border-radius: 0;
            padding: 6px;
          }

          .normal-icons {
            -gtk-icon-size: 16px;
          }

          .large-icons {
            -gtk-icon-size: 32px;
          }

          scrollbar {
            opacity: 0;
          }

          .box-wrapper {
            background: ${colors.surface};
            border: ${border} ${colors.border};
            border-radius: 0;
            padding: 12px;
          }

          .input {
            background: ${colors.background};
            caret-color: ${colors.accent};
            padding: 8px 10px;
            margin-bottom: 8px;
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
            padding: 6px 10px;
            border-left: ${border} transparent;
          }

          child:selected .item-box,
          row:selected .item-box {
            background: ${colors.selection};
            border-left: ${border} ${colors.accent};
          }

          .item-subtext {
            font-size: ${toString (style.font.size - 2)}pt;
            color: ${colors.muted};
          }

          .item-quick-activation {
            color: ${colors.accent};
            padding: 0 6px;
          }

          .item-image-text {
            font-size: 24px;
          }

          .preview {
            border: ${border} ${colors.border};
            border-radius: 0;
          }

          .calc .item-text {
            font-size: 20px;
          }

          .keybinds {
            padding-top: 8px;
            border-top: ${border} ${colors.border};
            font-size: ${toString (style.font.size - 2)}pt;
            color: ${colors.muted};
          }

          .keybind-label {
            padding: 0 4px;
            border: 1px solid ${colors.muted};
            border-radius: 0;
          }

          .error {
            padding: 8px;
            background: ${colors.error};
            color: ${colors.background};
          }
        '';
      };
    };
  };
}
