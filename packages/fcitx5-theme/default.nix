# The candidate window theme, built from the design tokens. fcitx5 looks for
# images next to theme.conf, so the ones from its dark theme are copied here.
{
  lib,
  runCommand,
  writeText,
  fcitx5,
  style,
}:

let
  inherit (style) colors spacing layout;

  margin = size: {
    Left = size;
    Right = size;
    Top = size;
    Bottom = size;
  };

  background = {
    Color = style.panel.hex;
    BorderColor = colors.border;
    BorderWidth = layout.border;
  };

  conf = writeText "theme.conf" (
    lib.generators.toINI { } {
      Metadata = {
        Name = "chena";
        Version = 1;
        Author = "chena";
        Description = "Theme built from the chena design tokens";
        ScaleWithDPI = "True";
      };

      InputPanel = {
        NormalColor = colors.text;
        HighlightCandidateColor = colors.background;
        HighlightColor = colors.text;
        HighlightBackgroundColor = colors.selection;
        PageButtonAlignment = "Last Candidate";
      };
      "InputPanel/TextMargin" = margin spacing.sm;
      "InputPanel/ContentMargin" = margin layout.border;
      "InputPanel/Background" = background;
      "InputPanel/Background/Margin" = margin layout.border;
      "InputPanel/Highlight".Color = colors.accent;
      "InputPanel/Highlight/Margin" = margin spacing.sm;
      "InputPanel/PrevPage".Image = "prev.svg";
      "InputPanel/PrevPage/ClickMargin" = margin spacing.sm;
      "InputPanel/NextPage".Image = "next.svg";
      "InputPanel/NextPage/ClickMargin" = margin spacing.sm;

      Menu = {
        NormalColor = colors.text;
        HighlightCandidateColor = colors.background;
      };
      "Menu/Background" = background;
      "Menu/Background/Margin" = margin layout.border;
      "Menu/ContentMargin" = margin layout.border;
      "Menu/CheckBox".Image = "radio.svg";
      "Menu/SubMenu".Image = "arrow.svg";
      "Menu/Highlight".Color = colors.accent;
      "Menu/Highlight/Margin" = margin spacing.sm;
      "Menu/Separator".Color = colors.border;
      "Menu/TextMargin" = margin spacing.sm;
    }
  );
in
runCommand "fcitx5-theme-chena" { } ''
  mkdir $out
  cp ${fcitx5}/share/fcitx5/themes/default-dark/*.svg $out/
  cp ${conf} $out/theme.conf
''
