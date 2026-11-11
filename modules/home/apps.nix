{
  config,
  lib,
  pkgs,
  ...
}:

let
  imageTypes = [
    "image/avif"
    "image/bmp"
    "image/gif"
    "image/heic"
    "image/jpeg"
    "image/png"
    "image/svg+xml"
    "image/tiff"
    "image/webp"
  ];
in
{
  config = lib.mkIf config.chena.enable {
    home.packages = [
      pkgs.nautilus
      pkgs.loupe
      pkgs.papers
    ];

    # Apps write their own choices to mimeapps.list, so that file stays out of
    # Nix. The list for the current desktop is read first.
    xdg.configFile."hyprland-mimeapps.list".text = lib.generators.toINI { } {
      "Default Applications" = {
        "inode/directory" = "org.gnome.Nautilus.desktop";
        "application/pdf" = "org.gnome.Papers.desktop";
      }
      // lib.genAttrs imageTypes (_: "org.gnome.Loupe.desktop");
    };
  };
}
