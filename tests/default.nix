{
  pkgs,
  nixpkgs,
  home-manager,
  self,
}:

let
  mkHome =
    modules:
    home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        self.homeModules.default
        {
          home = {
            username = "test";
            homeDirectory = "/home/test";
            stateVersion = "26.05";
          };
          chena.enable = true;
        }
      ]
      ++ modules;
    };

  # Runs Hyprland's own parser over the generated config. It loads every
  # required Lua file, so an error in any of them fails the check.
  verifyConfig =
    name: modules:
    let
      home = mkHome modules;
    in
    pkgs.runCommand "chena-${name}" { nativeBuildInputs = [ pkgs.hyprland ]; } ''
      export HOME=$TMPDIR XDG_RUNTIME_DIR=$TMPDIR
      conf=${home.config.home-files}/.config
      XDG_CONFIG_HOME=$conf Hyprland --verify-config -c $conf/hypr/hyprland.lua | tee log
      grep -qx 'config ok' log
      touch $out
    '';

  checkSettings =
    name: modules: script:
    let
      home = mkHome modules;
    in
    pkgs.runCommand "chena-${name}" { nativeBuildInputs = [ pkgs.lua ]; } ''
      lua ${script} ${home.config.home-files}/.config/hypr/chena/settings.lua
      touch $out
    '';

  customized = [
    {
      chena = {
        keyboard.options = [
          "ctrl:nocaps"
          "compose:ralt"
        ];
        monitors = [
          {
            output = "DP-1";
            mode = "2560x1440@144";
            position = "0x0";
            scale = 1.5;
          }
        ];
        touchpad.naturalScroll = false;
        extraLua.tweaks = ''
          hl.config({ general = { gaps_out = 8 } })
        '';
      };
    }
  ];

  nixos = nixpkgs.lib.nixosSystem {
    inherit (pkgs.stdenv.hostPlatform) system;
    modules = [
      self.nixosModules.default
      {
        chena.enable = true;
        boot.loader.grub.enable = false;
        fileSystems."/" = {
          device = "none";
          fsType = "tmpfs";
        };
        system.stateVersion = "26.05";
      }
    ];
  };
in
{
  home-default = verifyConfig "home-default" [ ];

  home-customized = verifyConfig "home-customized" customized;

  home-settings = checkSettings "home-settings" customized ./settings.lua;

  nixos-eval = pkgs.writeText "chena-nixos-eval" nixos.config.system.build.toplevel.drvPath;
}
