{ config, lib, ... }:

let
  inherit (config.chena) style;
  inherit (style) colors;

  # btop reads a theme as one theme[key]="value" line per key.
  btopTheme = lib.concatStrings (
    lib.mapAttrsToList (key: value: "theme[${key}]=\"${value}\"\n") {
      main_bg = colors.background;
      main_fg = colors.text;
      title = colors.text;
      hi_fg = colors.accent;
      selected_bg = colors.selection;
      selected_fg = colors.text;
      inactive_fg = colors.muted;
      graph_text = colors.muted;
      meter_bg = colors.border;
      proc_misc = colors.info;
      cpu_box = colors.border;
      mem_box = colors.border;
      net_box = colors.border;
      proc_box = colors.border;
      div_line = colors.border;

      temp_start = colors.success;
      temp_mid = colors.warning;
      temp_end = colors.error;
      cpu_start = colors.success;
      cpu_mid = colors.warning;
      cpu_end = colors.error;

      free_start = colors.success;
      free_mid = colors.success;
      free_end = colors.success;
      cached_start = colors.info;
      cached_mid = colors.info;
      cached_end = colors.info;
      available_start = colors.accent;
      available_mid = colors.accent;
      available_end = colors.accent;
      used_start = colors.secondary;
      used_mid = colors.secondary;
      used_end = colors.secondary;

      download_start = colors.info;
      download_mid = colors.accent;
      download_end = colors.secondary;
      upload_start = colors.success;
      upload_mid = colors.warning;
      upload_end = colors.error;

      process_start = colors.accent;
      process_mid = colors.secondary;
      process_end = colors.error;
    }
  );
in
{
  # chena only colors these tools. Turning bat, delta, fzf and lazygit on
  # stays the user's choice. btop comes with the desktop as its system monitor.
  config = lib.mkIf config.chena.enable {
    programs.bat.config.theme = style.syntax;

    programs.delta.options.syntax-theme = style.syntax;

    programs.fzf.colors = {
      bg = colors.background;
      "bg+" = colors.selection;
      fg = colors.text;
      "fg+" = colors.text;
      hl = colors.accent;
      "hl+" = colors.accent;
      info = colors.muted;
      prompt = colors.accent;
      pointer = colors.accent;
      marker = colors.secondary;
      spinner = colors.accent;
      header = colors.muted;
      border = colors.border;
      gutter = colors.background;
    };

    programs.lazygit.settings.gui.theme = {
      activeBorderColor = [
        colors.accent
        "bold"
      ];
      inactiveBorderColor = [ colors.border ];
      searchingActiveBorderColor = [
        colors.secondary
        "bold"
      ];
      optionsTextColor = [ colors.info ];
      selectedLineBgColor = [ colors.selection ];
      inactiveViewSelectedLineBgColor = [ colors.surface ];
      cherryPickedCommitFgColor = [ colors.accent ];
      cherryPickedCommitBgColor = [ colors.selection ];
      markedBaseCommitFgColor = [ colors.info ];
      markedBaseCommitBgColor = [ colors.selection ];
      unstagedChangesColor = [ colors.error ];
      defaultFgColor = [ colors.text ];
    };

    programs.btop = {
      enable = true;
      settings = {
        color_theme = "chena";
        theme_background = true;
        rounded_corners = style.layout.radius > 0;
      };
    };

    xdg.configFile."btop/themes/chena.theme".text = btopTheme;
  };
}
