{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.chena.displays;
in
{
  options.chena.displays = {
    enable = lib.mkEnableOption ''
      remembered display layouts. Arrange the displays in the Displays app
      (wdisplays) and the resolution, position, scale and rotation are kept
      for each set of connected displays, then come back whenever that set is
      connected again'';

    state = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.stateHome}/chena/displays.lua";
      defaultText = lib.literalExpression ''"''${config.xdg.stateHome}/chena/displays.lua"'';
      readOnly = true;
      description = "The file that keeps the saved layouts.";
    };
  };

  config = lib.mkIf (config.chena.enable && cfg.enable) {
    home.packages = [ pkgs.wdisplays ];

    home.activation.chenaDisplays = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p ${lib.escapeShellArg (dirOf cfg.state)}
    '';
  };
}
