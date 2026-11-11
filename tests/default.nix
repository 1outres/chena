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

  # Fails unless every expected string appears somewhere in the file.
  checkContains =
    name: modules: path: strings:
    let
      home = mkHome modules;
    in
    pkgs.runCommand "chena-${name}" { } ''
      file=${home.config.home-files}/${path}
      ${pkgs.lib.concatMapStrings (string: ''
        grep -qF -- ${pkgs.lib.escapeShellArg string} "$file" || { echo "missing in ${path}: ${string}"; exit 1; }
      '') strings}
      touch $out
    '';

  # Runs a jq expression that must print true for the JSON file.
  checkJson =
    name: modules: path: expression:
    let
      home = mkHome modules;
    in
    pkgs.runCommand "chena-${name}" { nativeBuildInputs = [ pkgs.jq ]; } ''
      jq -e ${pkgs.lib.escapeShellArg expression} ${home.config.home-files}/${path}
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

  # chena only colors these tools. Turning them on stays the user's choice.
  withCli = [
    {
      programs = {
        bat.enable = true;
        git.enable = true;
        delta = {
          enable = true;
          enableGitIntegration = true;
        };
        fzf.enable = true;
        lazygit.enable = true;
      };
    }
  ];

  largeImage = pkgs.runCommand "large-image.png" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
    magick -size 6000x4000 xc:'#bd93f9' png:$out
  '';

  withWallpaper = [ { chena.wallpaper = largeImage; } ];

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
        touchpad = {
          naturalScroll = false;
          scrollFactor = 0.5;
        };
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

  binds =
    let
      home = mkHome [ ];
      hypr = "${home.config.home-files}/.config/hypr/chena";
    in
    pkgs.runCommand "chena-binds" { nativeBuildInputs = [ pkgs.lua ]; } ''
      lua ${./binds.lua} ${hypr}/settings.lua ${hypr}/binds.lua
      touch $out
    '';

  workspaces-library = checkContains "workspaces-library" [ ] ".config/hypr/chena/workspaces.lua" [
    "chena.split.split-monitor-workspaces"
    "workspace_count = #settings.workspaces.keys"
    "restore_workspaces_on_monitor_reconnect = true"
  ];

  power-menu =
    let
      power = (mkHome [ ]).config.chena.programs.power;
    in
    pkgs.runCommand "chena-power-menu" { } ''
      for text in '--dmenu' 'lock-session' 'hyprshutdown' "--post-cmd" 'systemctl reboot' 'systemctl poweroff'; do
        grep -qF -- "$text" ${power} || { echo "missing in power menu: $text"; exit 1; }
      done
      touch $out
    '';

  theme-unknown = rejects "theme-unknown" [ { chena.theme = "no-such-theme"; } ];

  # Each workspace also gets a key on the number row, which has ten keys.
  workspaces-too-many = rejects "workspaces-too-many" [
    { chena.workspaces.keys = pkgs.lib.genList toString 11; }
  ];

  ghostty-theme = checkLines "ghostty-theme" [ ] ".config/ghostty/config" [
    "background = #282a36"
    "foreground = #f8f8f2"
    "palette = 5=#ff79c6"
    "font-family = JetBrainsMono Nerd Font"
    "font-family = Noto Sans CJK JP"
    "background-opacity = 1"
  ];

  bar-config = checkJson "bar-config" [ ] ".config/waybar/config" ''
    .[0]
    | .layer == "top"
      and .position == "top"
      and .height == 26
      and .["modules-left"] == ["hyprland/workspaces"]
      and .["modules-center"] == ["clock"]
      and .["modules-right"] == ["tray", "bluetooth", "network", "wireplumber", "battery"]
      and (.network["on-click"] | contains("nmtui"))
      and (.bluetooth["on-click"] | contains("bluetui"))
  '';

  floating-tools = checkContains "floating-tools" [ ] ".config/hypr/chena/rules.lua" [
    "chena\\\\.floating"
  ];

  polkit-agent = checkContains "polkit-agent" [ ] ".config/systemd/user/hyprpolkitagent.service" [
    "libexec/hyprpolkitagent"
  ];

  screenshot-editor = checkContains "screenshot-editor" [ ] ".config/satty/config.toml" [
    "corner-roundness = 0"
    "copy-command = \"wl-copy\""
    "family = \"JetBrainsMono Nerd Font\""
    "#bd93f9"
  ];

  apps-defaults = checkLines "apps-defaults" [ ] ".config/hyprland-mimeapps.list" [
    "[Default Applications]"
    "application/pdf=org.gnome.Papers.desktop"
    "image/png=org.gnome.Loupe.desktop"
    "inode/directory=org.gnome.Nautilus.desktop"
  ];

  # Nautilus, Loupe and Papers are GTK 4 apps.
  gtk4-theme = checkContains "gtk4-theme" [ ] ".config/gtk-4.0/settings.ini" [
    "gtk-theme-name=Dracula"
  ];

  input-method-config = checkLines "input-method-config" [ ] ".config/fcitx5/conf/classicui.conf" [
    "Theme=chena"
    "DarkTheme=chena"
    "UseAccentColor=False"
    "Font=\"JetBrainsMono Nerd Font, Noto Sans CJK JP 11\""
  ];

  input-method-theme =
    checkLines "input-method-theme" [ ] ".local/share/fcitx5/themes/chena/theme.conf"
      [
        "[InputPanel/Background]"
        "Color=#21222c"
        "BorderColor=#44475a"
        "BorderWidth=2"
        "[InputPanel/Highlight]"
        "Color=#bd93f9"
        "HighlightCandidateColor=#282a36"
      ];

  wallpaper-desktop = checkContains "wallpaper-desktop" withWallpaper ".config/hypr/hyprpaper.conf" [
    "path=/nix/store/"
    "fit_mode=cover"
  ];

  wallpaper-lock = checkContains "wallpaper-lock" withWallpaper ".config/hypr/hyprlock.conf" [
    "path=/nix/store/"
    "brightness=0.6"
  ];

  # The image is decoded at full size for each monitor, so a huge one costs
  # hundreds of MB. It is made just big enough to cover a 4K screen.
  wallpaper-size =
    let
      image = (mkHome withWallpaper).config.chena.wallpaperImage;
    in
    pkgs.runCommand "chena-wallpaper-size" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
      size=$(magick identify -format '%wx%h' ${image})
      [ "$size" = 3240x2160 ] || { echo "wallpaper is $size"; exit 1; }
      touch $out
    '';

  wallpaper-off =
    assert !(mkHome [ ]).config.services.hyprpaper.enable;
    pkgs.writeText "chena-wallpaper-off" "ok";

  wallpaper-greeter =
    let
      inherit
        ((nixos.extendModules { modules = withWallpaper; }).config.services.displayManager.regreet.settings)
        background
        ;
    in
    assert pkgs.lib.hasPrefix "/nix/store/" background.path;
    assert background.fit == "Cover";
    pkgs.writeText "chena-wallpaper-greeter" "ok";

  # Nautilus needs gvfs for the trash and for removable disks.
  nixos-file-manager =
    assert nixos.config.services.gvfs.enable;
    pkgs.writeText "chena-nixos-file-manager" "ok";

  # The workspace ids run on through the monitors, but every bar counts from 1.
  bar-workspaces = checkJson "bar-workspaces" [ ] ".config/waybar/config" ''
    .[0]["hyprland/workspaces"]
    | .format == "{icon}"
      and .["format-icons"]["1"] == "1"
      and .["format-icons"]["9"] == "9"
      and .["format-icons"]["10"] == "1"
      and .["format-icons"]["36"] == "9"
      and (.["on-scroll-up"] | contains("m+1"))
      and (.["on-scroll-down"] | contains("m-1"))
  '';

  bar-style = checkContains "bar-style" [ ] ".config/waybar/style.css" [
    "font-family: \"JetBrainsMono Nerd Font\", \"Noto Sans CJK JP\";"
    "background-color: #21222c;"
    "border-bottom: 2px solid #44475a;"
    "border-bottom-color: #bd93f9;"
    "color: #ff5555;"
    "border-radius: 0px;"
  ];

  bar-service = checkContains "bar-service" [ ] ".config/systemd/user/waybar.service" [
    "WantedBy=graphical-session.target"
  ];

  launcher-config = checkLines "launcher-config" [ ] ".config/walker/config.toml" [
    "theme = \"chena\""
    "close_when_open = true"
  ];

  launcher-style = checkContains "launcher-style" [ ] ".config/walker/themes/chena/style.css" [
    "font-family: \"JetBrainsMono Nerd Font\", \"Noto Sans CJK JP\";"
    "background: #21222c;"
    "border: 2px solid #44475a;"
    "border-left: 2px solid #bd93f9;"
    "border-radius: 0px;"
  ];

  launcher-services = checkContains "launcher-services" [ ] ".config/systemd/user/walker.service" [
    "--gapplication-service"
    "elephant.service"
  ];

  notification-config = checkLines "notification-config" [ ] ".config/mako/config" [
    "font=JetBrainsMono Nerd Font, Noto Sans CJK JP 10"
    "background-color=#21222c"
    "text-color=#f8f8f2"
    "border-color=#44475a"
    "border-size=2"
    "border-radius=0"
    "[urgency=critical]"
    "border-color=#ff5555"
    "default-timeout=0"
  ];

  osd-style = checkContains "osd-style" [ ] ".config/swayosd/style.css" [
    "background: #21222c;"
    "border: 2px solid #44475a;"
    "background: #bd93f9;"
    "border-radius: 0px;"
  ];

  osd-service = checkContains "osd-service" [ ] ".config/systemd/user/swayosd.service" [
    "--style"
    "swayosd/style.css"
  ];

  lock-config = checkContains "lock-config" [ ] ".config/hypr/hyprlock.conf" [
    "color=rgb(191a21)"
    "font_family=JetBrainsMono Nerd Font"
    "outer_color=rgb(44475a)"
    "inner_color=rgb(21222c)"
    "check_color=rgb(bd93f9)"
    "fail_color=rgb(ff5555)"
    "capslock_color=rgb(ffb86c)"
    "rounding=0"
    "dots_rounding=0"
  ];

  idle-config = checkContains "idle-config" [ ] ".config/hypr/hypridle.conf" [
    "lock_cmd="
    "before_sleep_cmd="
    "timeout=300"
    "timeout=330"
    "chena-screen off"
    "chena-screen on"
  ];

  gtk-theme = checkLines "gtk-theme" [ ] ".config/gtk-3.0/settings.ini" [
    "gtk-theme-name=Dracula"
    "gtk-icon-theme-name=Papirus-Dark"
    "gtk-application-prefer-dark-theme=1"
  ];

  qt-kvantum = checkLines "qt-kvantum" [ ] ".config/Kvantum/kvantum.kvconfig" [
    "theme=Dracula-Solid"
  ];

  qt-kvantum-theme =
    checkContains "qt-kvantum-theme" [ ] ".config/Kvantum/Dracula-Solid/Dracula-Solid.kvconfig"
      [ "[%General]" ];

  qt-ct = checkLines "qt-ct" [ ] ".config/qt6ct/qt6ct.conf" [
    "style=kvantum"
    "icon_theme=Papirus-Dark"
  ];

  # The folder color comes from the theme, so folders match the accent.
  icon-folders =
    let
      icons = (mkHome [ ]).config.gtk.iconTheme.package;
    in
    pkgs.runCommand "chena-icon-folders" { } ''
      target=$(readlink ${icons}/share/icons/Papirus-Dark/48x48/places/folder.svg)
      case "$target" in
        *violet*) touch $out ;;
        *) echo "folder icon is not violet: $target"; exit 1 ;;
      esac
    '';

  cli-bat = checkContains "cli-bat" withCli ".config/bat/config" [ "--theme=Dracula" ];

  cli-delta = checkContains "cli-delta" withCli ".config/git/config" [ "syntax-theme = \"Dracula\"" ];

  cli-fzf =
    let
      options = (mkHome withCli).config.home.sessionVariables.FZF_DEFAULT_OPTS;
    in
    assert pkgs.lib.hasInfix "bg+:#44475a" options;
    assert pkgs.lib.hasInfix "pointer:#bd93f9" options;
    pkgs.writeText "chena-cli-fzf" "ok";

  cli-lazygit = checkContains "cli-lazygit" withCli ".config/lazygit/config.yml" [
    "activeBorderColor:"
    "'#bd93f9'"
    "selectedLineBgColor:"
    "'#44475a'"
  ];

  cli-btop = checkContains "cli-btop" [ ] ".config/btop/btop.conf" [ "color_theme = \"chena\"" ];

  cli-btop-theme = checkLines "cli-btop-theme" [ ] ".config/btop/themes/chena.theme" [
    "theme[main_bg]=\"#282a36\""
    "theme[main_fg]=\"#f8f8f2\""
    "theme[hi_fg]=\"#bd93f9\""
    "theme[cpu_end]=\"#ff5555\""
  ];

  nixos-eval = pkgs.writeText "chena-nixos-eval" nixos.config.system.build.toplevel.drvPath;

  # The tokens are public so that other modules, on either side, can match
  # the desktop. Both sides must build the same tokens.
  style-public =
    let
      home = (mkHome [ ]).config.chena.style;
      system = nixos.config.chena.style;
    in
    assert home == system;
    assert system.colors.accent == "#bd93f9";
    assert system.spacing.md == 8;
    assert system.fontSize.normal == 11;
    pkgs.writeText "chena-style-public" "ok";

  spacing-used = checkLines "spacing-used" [ ] ".config/mako/config" [
    "padding=12"
    "font=JetBrainsMono Nerd Font, Noto Sans CJK JP 10"
  ];

  terminal-spacing = checkLines "terminal-spacing" [ ] ".config/ghostty/config" [
    "window-padding-x = 8"
    "window-padding-y = 8"
  ];

  # hyprlock checks the password through PAM and cannot unlock without it.
  nixos-lock-pam =
    assert nixos.config.security.pam.services ? hyprlock;
    pkgs.writeText "chena-nixos-lock-pam" "ok";

  boot-splash =
    let
      plymouth = nixos.config.boot.plymouth;
    in
    assert plymouth.enable;
    assert plymouth.theme == "chena";
    assert pkgs.lib.hasInfix "DeviceScale=1" plymouth.extraConfig;
    assert pkgs.lib.hasInfix "JetBrainsMono" plymouth.font;
    pkgs.writeText "chena-boot-splash" "ok";

  boot-splash-theme =
    let
      theme = pkgs.lib.findFirst (
        package: package.pname or "" == "plymouth-theme-chena"
      ) (throw "no chena theme package") nixos.config.boot.plymouth.themePackages;
      dir = "${theme}/share/plymouth/themes/chena";
    in
    pkgs.runCommand "chena-boot-splash-theme" { } ''
      for file in chena.plymouth chena.script field.png field@2x.png bullet.png bullet@2x.png; do
        test -s ${dir}/$file || { echo "missing $file"; exit 1; }
      done
      grep -qF 'ModuleName=script' ${dir}/chena.plymouth
      # The desktop color #191a21 as 0 to 1 floats.
      grep -qF 'Window.SetBackgroundTopColor(0.098039, 0.101961, 0.129412);' ${dir}/chena.script
      grep -qF 'Plymouth.SetDisplayPasswordFunction' ${dir}/chena.script
      touch $out
    '';

  boot-brightness =
    let
      rules = nixos.config.boot.initrd.services.udev.rules;
    in
    assert pkgs.lib.hasInfix ''SUBSYSTEM=="backlight"'' rules;
    assert pkgs.lib.hasInfix "chena-fixed-brightness" rules;
    pkgs.writeText "chena-boot-brightness" "ok";

  greeter =
    let
      inherit (nixos.config.services.displayManager) regreet;
    in
    assert regreet.enable;
    assert regreet.settings.GTK.theme_name == "Dracula";
    assert regreet.settings.GTK.icon_theme_name == "Papirus-Dark";
    assert pkgs.lib.hasInfix "#191a21" nixos.config.environment.etc."greetd/regreet.css".text;
    assert pkgs.lib.any (pkgs.lib.hasInfix "chena-fixed-brightness") (
      pkgs.lib.toList nixos.config.systemd.services.greetd.serviceConfig.ExecStartPre
    );
    pkgs.writeText "chena-greeter" "ok";
}
