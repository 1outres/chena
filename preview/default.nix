{
  pkgs,
  home-manager,
  self,
  modules ? [ ],
}:

let
  inherit (pkgs) lib;

  home = home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      self.homeModules.default
      ./home.nix
    ]
    ++ modules;
  };

  inherit (home) config;

  sessionTarget = config.wayland.systemd.target;

  # The services that a systemd user manager would start with the session.
  sessionServices = lib.filterAttrs (
    _: service: lib.elem sessionTarget (service.Install.WantedBy or [ ])
  ) config.systemd.user.services;

  startsBefore = a: b: lib.elem "${a}.service" (sessionServices.${b}.Unit.After or [ ]);

  serviceOrder =
    let
      sorted = lib.toposort startsBefore (lib.attrNames sessionServices);
    in
    if sorted ? result then
      sorted.result
    else
      throw "chena-preview: the session services depend on each other in a cycle";

  serviceLauncher =
    name:
    let
      service = sessionServices.${name}.Service;
      execStart = lib.toList service.ExecStart;
      environment = lib.toList (service.Environment or [ ]);
    in
    assert lib.assertMsg (
      lib.length execStart == 1
    ) "chena-preview: ${name}.service must have exactly one ExecStart";
    pkgs.writeShellScript "chena-preview-${name}" ''
      ${lib.concatMapStrings (assignment: "export ${lib.escapeShellArg assignment}\n") environment}
      exec ${lib.head execStart}
    '';

  services = pkgs.linkFarm "chena-preview-services" (
    lib.imap0 (index: name: {
      name = "${lib.fixedWidthNumber 2 index}-${name}";
      path = serviceLauncher name;
    }) serviceOrder
  );

  dconfSettings = pkgs.writeText "chena-preview-dconf.ini" (
    lib.generators.toINI {
      mkKeyValue = key: value: "${key}=${toString (home-manager.lib.hm.gvariant.mkValue value)}";
    } config.dconf.settings
  );

  sessionEnv = pkgs.writeShellScript "chena-preview-session-env" (builtins.readFile ./session-env.sh);

  pointerPython = pkgs.python3.withPackages (python: [ python.pywayland ]);

  pointerProtocols =
    pkgs.runCommand "chena-preview-pointer-protocols" { nativeBuildInputs = [ pointerPython ]; }
      ''
        mkdir -p $out/chena_preview_protocols
        touch $out/chena_preview_protocols/__init__.py
        # The scanner asks pkg-config for wayland.xml even when it is given.
        PKG_CONFIG=false python3 -m pywayland.scanner \
          -o $out/chena_preview_protocols \
          -i ${pkgs.wayland-scanner}/share/wayland/wayland.xml \
             ${pkgs.wlr-protocols}/share/wlr-protocols/unstable/wlr-virtual-pointer-unstable-v1.xml
      '';

  pointer = pkgs.writeShellScriptBin "chena-preview-pointer" ''
    PYTHONPATH=${pointerProtocols} exec ${lib.getExe pointerPython} ${./pointer.py} "$@"
  '';

  mocks = pkgs.python3.withPackages (python: [
    python.python-dbusmock
    python.pygobject3
  ]);

  tools = [
    pkgs.coreutils
    pkgs.dbus
    pkgs.dconf
    pkgs.glib
    pkgs.grim
    pkgs.hyprland
    pkgs.kdePackages.kwin
    pkgs.procps
    pkgs.util-linux
    pkgs.wtype
    mocks
    pointer
  ];
in
pkgs.writeShellApplication {
  name = "chena-preview";
  runtimeInputs = tools;
  text = ''
    home_dir=${lib.escapeShellArg config.home.homeDirectory}
    home_files=${config.home-files}
    home_path=${config.home.path}
    services=${services}
    dconf_settings=${dconfSettings}
    session_env_script=${sessionEnv}
    tools_path=${lib.makeBinPath tools}
  ''
  + builtins.readFile ./preview.sh;
}
