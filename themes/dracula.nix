# https://draculatheme.com/spec
{ pkgs }:

{
  colors = {
    desktop = "#191a21";
    surface = "#21222c";
    background = "#282a36";
    border = "#44475a";
    selection = "#44475a";
    muted = "#6272a4";
    text = "#f8f8f2";
    accent = "#bd93f9";
    secondary = "#ff79c6";
    info = "#8be9fd";
    success = "#50fa7b";
    warning = "#ffb86c";
    error = "#ff5555";
    highlight = "#f1fa8c";
  };

  # ANSI colors 0 to 15.
  terminal = [
    "#21222c"
    "#ff5555"
    "#50fa7b"
    "#f1fa8c"
    "#bd93f9"
    "#ff79c6"
    "#8be9fd"
    "#f8f8f2"
    "#6272a4"
    "#ff6e6e"
    "#69ff94"
    "#ffffa5"
    "#d6acff"
    "#ff92df"
    "#a4ffff"
    "#ffffff"
  ];

  gtk = {
    name = "Dracula";
    package = pkgs.dracula-theme;
  };
}
