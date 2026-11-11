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
    clamshell = lib.mapNullable (clamshell: {
      inherit (clamshell) switch output;
      lid_state = "${lib.getExe' pkgs.systemd "busctl"} get-property org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager LidClosed";
    }) cfg.clamshell;
    workspaces = {
      inherit (cfg.workspaces) keys;
    };
    touchpad = {
      natural_scroll = cfg.touchpad.naturalScroll;
      scroll_factor = cfg.touchpad.scrollFactor;
    };
    devices = lib.mapAttrs (_: device: { natural_scroll = device.naturalScroll; }) cfg.devices;
    style = {
      gaps_in = style.layout.gapsIn;
      gaps_out = style.layout.gapsOut;
      border_size = style.layout.border;
      rounding = style.layout.radius;
      inherit (style.translucency) blur;
      blurred_layers = cfg.blurredLayers;
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
    "clamshell"
    "environment"
    "appearance"
    "layouts"
    "misc"
    "input"
    "workspaces"
    "binds"
    "rules"
    "session"
  ];

  extraModules = lib.attrNames cfg.extraLua;

  splitWorkspaces = pkgs.callPackage ../../../packages/split-monitor-workspaces { };

  splitModules = [
    "split-monitor-workspaces"
    "globals"
    "helpers"
    "monitors"
    "dispatchers"
  ];

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

    clamshell = mkOption {
      type = types.nullOr (
        types.submodule {
          options = {
            switch = mkOption {
              type = types.str;
              example = "Lid Switch";
              description = "Name of the lid switch, as `hyprctl devices` shows it.";
            };
            output = mkOption {
              type = types.str;
              example = "eDP-1";
              description = "Output name of the built-in screen.";
            };
          };
        }
      );
      default = null;
      description = ''
        Turns the built-in screen off when the lid closes while another
        monitor is on, and back on when the lid opens. Without another
        monitor, logind suspends as usual.
      '';
    };

    workspaces.keys = mkOption {
      type = types.addCheck (types.nonEmptyListOf types.str) (keys: lib.length keys <= 10);
      default = [
        "Z"
        "X"
        "C"
        "S"
        "D"
        "F"
        "W"
        "E"
        "R"
      ];
      description = ''
        Keys for the workspaces of the focused monitor, from the first
        workspace to the last. The default reads like a number pad under the
        left hand: Z X C are 1 to 3, S D F are 4 to 6, W E R are 7 to 9.
        The number row works too, so the list can hold at most ten keys.
      '';
    };

    touchpad = {
      naturalScroll = mkOption {
        type = types.bool;
        default = true;
        description = "Whether the content follows the fingers when scrolling.";
      };
      scrollFactor = mkOption {
        type = types.numbers.positive;
        default = 1;
        example = 0.5;
        description = "Multiplier for the scroll speed. Smaller is slower.";
      };
    };

    devices = mkOption {
      type = types.attrsOf (
        types.submodule {
          options.naturalScroll = mkOption {
            type = types.bool;
            description = ''
              Whether the content follows the fingers when scrolling with
              this device. Mice scroll the other way by default.
            '';
          };
        }
      );
      default = { };
      example = lib.literalExpression ''{ "zmk-project-roba-mouse".naturalScroll = true; }'';
      description = ''
        Settings for one input device, keyed by the name that
        `hyprctl devices` shows.
      '';
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
      // lib.genAttrs' splitModules (
        name: lib.nameValuePair "chena.split.${name}" (notAutoLoaded "${splitWorkspaces}/lua/${name}.lua")
      )
      // lib.mapAttrs' (
        name: content: lib.nameValuePair "chena.extra.${name}" (notAutoLoaded content)
      ) cfg.extraLua;
    };
  };
}
