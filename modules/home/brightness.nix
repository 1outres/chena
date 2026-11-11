{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.chena;

  # The login screen and the disk password prompt use a fixed level. The
  # session saves its own level when it ends and sets the fixed one for the
  # login screen, then gets its level back when it starts again.
  session = pkgs.writeShellApplication {
    name = "chena-session-brightness";
    runtimeInputs = [
      pkgs.brightnessctl
      pkgs.coreutils
    ];
    text = ''
      state="''${XDG_STATE_HOME:-$HOME/.local/state}/chena/brightness"
      case "$1" in
        save)
          mkdir -p "$(dirname "$state")"
          brightnessctl -c backlight -m info | cut -d, -f4 | tr -d '%' > "$state"
          brightnessctl -c backlight -q set ${toString cfg.brightness.fixed}%
          ;;
        restore)
          # Nothing is saved before the first session ends.
          [ -s "$state" ] || exit 0
          brightnessctl -c backlight -q set "$(cat "$state")%"
          ;;
        *)
          echo "usage: chena-session-brightness save|restore" >&2
          exit 2
          ;;
      esac
    '';
  };
in
{
  imports = [ ../shared/brightness.nix ];

  config = lib.mkIf cfg.enable {
    chena.programs = {
      session_start = "${lib.getExe session} restore";
      session_end = "${lib.getExe session} save";
    };
  };
}
