{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.chena;
  inherit (cfg) style;
  inherit (style) colors spacing;
  inherit (import ../../lib/css.nix) px;

  border = "${px style.layout.border} solid";
  radius = px style.layout.radius;

  fixedBrightness = pkgs.callPackage ../../packages/fixed-brightness {
    level = cfg.brightness.fixed;
  };
in
{
  config = lib.mkIf cfg.enable {
    services.displayManager.regreet = {
      enable = true;

      theme = style.gtk;
      iconTheme = style.icons;
      font = {
        name = style.font.mono;
        package = pkgs.nerd-fonts.jetbrains-mono;
        size = style.fontSize.normal;
      };

      settings = {
        GTK.application_prefer_dark_theme = true;
        widget.clock.format = "%a %d %b  %H:%M";
      };

      extraCss = ''
        window {
          background-color: ${colors.desktop};
        }

        frame,
        .background {
          background-color: ${colors.surface};
          border: ${border} ${colors.border};
          border-radius: ${radius};
        }

        entry,
        combobox button,
        dropdown button,
        button {
          background: ${colors.background};
          color: ${colors.text};
          border: ${border} ${colors.border};
          border-radius: ${radius};
          box-shadow: none;
          padding: ${px spacing.sm} ${px spacing.md};
        }

        entry:focus-within,
        button:focus {
          border-color: ${colors.accent};
        }

        button.suggested-action {
          background: ${colors.accent};
          color: ${colors.background};
          border-color: ${colors.accent};
        }

        button.destructive-action {
          background: ${colors.error};
          color: ${colors.background};
          border-color: ${colors.error};
        }

        label.dim-label,
        .caption {
          color: ${colors.muted};
        }
      '';
    };

    # The login screen comes after systemd restored the last saved level, and
    # the last session may have left it dim.
    systemd.services.greetd.serviceConfig.ExecStartPre = [ "${fixedBrightness}" ];
  };
}
