{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.chena;

  inherit (lib) mkOption types;
  inherit (cfg) style;

  toLua = lib.generators.toLua { };

  toLuaModule = value: "return ${toLua value}\n";

  # The Lua files read every value that Nix decides from this one module, so
  # commands come from the Nix store and options reach Lua unchanged.
  settings = {
    inherit (cfg) programs;
    cursor = {
      inherit (cfg.cursor) name size;
    };
    keyboard = {
      inherit (cfg.keyboard) layout options;
    };
    inherit (cfg) monitors;
    touchpad.natural_scroll = cfg.touchpad.naturalScroll;
    style = {
      gaps_in = style.layout.gapsIn;
      gaps_out = style.layout.gapsOut;
      border_size = style.layout.border;
      rounding = style.layout.radius;
      colors = {
        active_border = style.hyprColors.accent;
        inactive_border = style.hyprColors.border;
        desktop = style.hyprColors.desktop;
      };
    };
  };

  # Load order of the core files. Later files can override earlier ones.
  coreModules = [
    "monitors"
    "environment"
    "appearance"
    "layouts"
    "misc"
    "input"
    "binds"
    "rules"
  ];

  extraModules = lib.attrNames cfg.extraLua;

  init = lib.concatMapStrings (name: "require(${toLua name})\n") (
    map (name: "chena.${name}") coreModules ++ map (name: "chena.extra.${name}") extraModules
  );

  notAutoLoaded = content: {
    inherit content;
    autoLoad = false;
  };

  monitorType = types.submodule {
    options = {
      output = mkOption {
        type = types.str;
        description = "Output name such as `eDP-1`. An empty string matches every output.";
      };
      mode = mkOption {
        type = types.str;
        default = "preferred";
        description = "Resolution and refresh rate, such as `2560x1440@144`.";
      };
      position = mkOption {
        type = types.str;
        default = "auto";
        description = "Position in the layout, such as `0x0`.";
      };
      scale = mkOption {
        type = types.either types.str types.number;
        default = "auto";
        description = "Scale factor, or `\"auto\"`.";
      };
    };
  };
in
{
  options.chena = {
    keyboard = {
      layout = mkOption {
        type = types.str;
        default = "us";
        description = "XKB layout.";
      };
      options = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "ctrl:nocaps" ];
        description = "XKB options.";
      };
    };

    monitors = mkOption {
      type = types.listOf monitorType;
      default = [ { output = ""; } ];
      description = "Monitor rules, applied in order.";
    };

    touchpad.naturalScroll = mkOption {
      type = types.bool;
      default = true;
      description = "Whether the content follows the fingers when scrolling.";
    };

    extraLua = mkOption {
      type = types.attrsOf (types.either types.path types.lines);
      default = { };
      example = lib.literalExpression "{ tweaks = ./tweaks.lua; }";
      description = ''
        Extra Lua files for this machine. They load after the chena files,
        in name order, so they can override any chena setting.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    chena.programs.shutdown = lib.getExe pkgs.hyprshutdown;

    wayland.windowManager.hyprland = {
      enable = true;

      # The NixOS module installs the compositor and the portal. Setting them
      # here too would add a second build of each.
      package = null;
      portalPackage = null;

      # The default follows home.stateVersion and is "hyprlang" before 26.05.
      configType = "lua";

      extraLuaFiles = {
        "chena.init".content = init;
        "chena.settings" = notAutoLoaded (toLuaModule settings);
      }
      // lib.genAttrs' coreModules (
        name: lib.nameValuePair "chena.${name}" (notAutoLoaded ./lua/${name}.lua)
      )
      // lib.mapAttrs' (
        name: content: lib.nameValuePair "chena.extra.${name}" (notAutoLoaded content)
      ) cfg.extraLua;
    };
  };
}
