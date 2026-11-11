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

  # Fails unless every expected line appears as a whole line in the file.
  checkLines =
    name: modules: path: lines:
    let
      home = mkHome modules;
    in
    pkgs.runCommand "chena-${name}" { } ''
      file=${home.config.home-files}/${path}
      ${pkgs.lib.concatMapStrings (line: ''
        grep -qxF ${pkgs.lib.escapeShellArg line} "$file" || { echo "missing in ${path}: ${line}"; exit 1; }
      '') lines}
      touch $out
    '';

  # An option value that fails the type check must stop evaluation.
  rejects =
    name: modules:
    let
      result = builtins.tryEval (mkHome modules).activationPackage.drvPath;
    in
    assert !result.success;
    pkgs.writeText "chena-${name}" "rejected";

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

  theme-unknown = rejects "theme-unknown" [ { chena.theme = "no-such-theme"; } ];

  ghostty-theme = checkLines "ghostty-theme" [ ] ".config/ghostty/config" [
    "background = #282a36"
    "foreground = #f8f8f2"
    "palette = 5=#ff79c6"
    "font-family = JetBrainsMono Nerd Font"
    "font-family = Noto Sans CJK JP"
    "background-opacity = 1"
  ];

  gtk-theme = checkLines "gtk-theme" [ ] ".config/gtk-3.0/settings.ini" [
    "gtk-theme-name=Dracula"
    "gtk-application-prefer-dark-theme=1"
  ];

  nixos-eval = pkgs.writeText "chena-nixos-eval" nixos.config.system.build.toplevel.drvPath;
}
