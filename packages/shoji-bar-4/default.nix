# A Material 3 Expressive desktop shell, built for ShojiWM. It reads the
# workspaces and windows through ext-workspace-v1 and the foreign toplevel
# protocols, so it also runs on Hyprland.
{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  makeWrapper,
  wayland,
  libxkbcommon,
  libxcb,
  vulkan-loader,
  libGL,
  fontconfig,
  linux-pam,
  pipewire,
  cliphist,
  wl-clipboard,
  zenity,
}:

let
  # wgpu, the GPU drivers and PipeWire are opened at run time.
  runtimeLibraries = [
    wayland
    libxkbcommon
    vulkan-loader
    libGL
    pipewire
  ];

  # The clipboard history and the picture picker run these.
  runtimeTools = [
    cliphist
    wl-clipboard
    zenity
  ];
in
rustPlatform.buildRustPackage {
  pname = "shoji-bar-4";
  version = "0.1.0-unstable-2026-11-11";

  src = fetchFromGitHub {
    owner = "bea4dev";
    repo = "shoji-bar-4";
    rev = "81f0e7204ba25e03938b6fcdc04f41e99d348144";
    hash = "sha256-2sfcxlhNtG/Ov78Ro4GgOJ8PjLzu30hXySg176hhrhs=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes."anti-webui-0.1.0" = "sha256-bSkXbDV3xgxqEyjRQe5fva94xDijsLdZ0scx/o3ites=";
  };

  nativeBuildInputs = [
    pkg-config
    makeWrapper
  ];

  buildInputs = [
    wayland
    libxkbcommon
    # AntiWebUI builds its X11 backend too, so the binary links libxcb.
    libxcb
    fontconfig
    linux-pam
  ];

  postFixup = ''
    wrapProgram $out/bin/shoji-bar-4 \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeLibraries} \
      --prefix PATH : ${lib.makeBinPath runtimeTools}
  '';

  meta = {
    description = "Material 3 Expressive desktop shell";
    homepage = "https://github.com/bea4dev/shoji-bar-4";
    license = lib.licenses.mit;
    mainProgram = "shoji-bar-4";
    platforms = lib.platforms.linux;
  };
}
