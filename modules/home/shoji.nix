{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.chena;

  isShoji = cfg.shell == "shoji-bar-4";

  package = pkgs.callPackage ../../packages/shoji-bar-4 { };
  shell = lib.getExe package;
  wpctl = lib.getExe' pkgs.wireplumber "wpctl";
  playerctl = lib.getExe pkgs.playerctl;

  # The shell saves these to its own settings file too, so they are merged
  # into the file on each switch and the rest stays the shell's to change.
  managed = {
    mode = "dark";
    seed = cfg.style.colors.accent;
    seed_from_wallpaper = false;
    wallpaper = if cfg.wallpaperImage == null then null else "${cfg.wallpaperImage}";
  };
  managedJson = builtins.toJSON managed;
in
{
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        # optionalAttrs and not mkIf, since chena.programs is lazy and keeps
        # a name that mkIf turns off.
        chena.programs = lib.optionalAttrs isShoji {
          menu = "${shell} msg toggle launcher";
          clipboard = "${shell} msg toggle clipboard";
          quick_settings = "${shell} msg toggle quick-settings";
          locker = "${shell} msg lock";

          # The shell shows its OSD whenever the volume or the brightness
          # changes, so the keys only change them.
          volume_up = "${wpctl} set-volume --limit 1 @DEFAULT_AUDIO_SINK@ 5%+";
          volume_down = "${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%-";
          volume_mute = "${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle";
          mic_mute = "${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
          media_next = "${playerctl} next";
          media_play_pause = "${playerctl} play-pause";
          media_previous = "${playerctl} previous";
          brightness = "${lib.getExe pkgs.brightnessctl} -e4 -n2 set";
        };
      }

      (lib.mkIf isShoji {
        systemd.user.services.shoji-bar-4 = {
          Unit = {
            Description = "shoji-bar-4 desktop shell";
            PartOf = [ config.wayland.systemd.target ];
            After = [ config.wayland.systemd.target ];
            X-Restart-Triggers = [ managedJson ];
          };
          Service = {
            ExecStart = shell;
            Restart = "on-failure";
          };
          Install.WantedBy = [ config.wayland.systemd.target ];
        };

        # The clipboard history reads what cliphist stores.
        services.cliphist.enable = true;

        home.activation.shojiBar4Settings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          settings="${config.xdg.stateHome}/shoji-bar-4/settings.json"
          run mkdir -p "$(dirname "$settings")"
          # The shell writes this file the first time it saves a setting.
          if [ -s "$settings" ]; then
            current=$(cat "$settings")
          else
            current='{}'
          fi
          printf '%s' "$current" \
            | ${lib.getExe pkgs.jq} --argjson chena ${lib.escapeShellArg managedJson} '. + $chena' \
            > "$settings.new"
          run mv "$settings.new" "$settings"
        '';
      })
    ]
  );
}
