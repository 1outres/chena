# chena

An opinionated Hyprland desktop for NixOS, configured in Lua and managed with
Home Manager.

Named after Chena Hot Springs near Fairbanks, Alaska, a well-known place to
watch the aurora.

## Use

Add the flake as an input:

```nix
inputs.chena = {
  url = "github:1outres/chena";
  inputs.nixpkgs.follows = "nixpkgs";
  inputs.home-manager.follows = "home-manager";
};
```

Enable it in the NixOS configuration:

```nix
imports = [ inputs.chena.nixosModules.default ];
chena.enable = true;
```

And in the Home Manager configuration:

```nix
imports = [ inputs.chena.homeModules.default ];
chena = {
  enable = true;
  keyboard.options = [ "ctrl:nocaps" ];
  monitors = [ { output = "eDP-1"; scale = 2; } ];
  extraLua.tweaks = ./tweaks.lua;
};
```

See `modules/home/default.nix` for every option.

## Layout

- `modules/nixos`: system side (Hyprland, greetd).
- `modules/home`: user side. `default.nix` defines the options and
  `lua/` holds the Hyprland config.
- `tests`: checks run by `nix flake check`.

Nix writes every value it decides into `~/.config/hypr/chena/settings.lua`.
The Lua files read it with `require("chena.settings")`.

## Develop

```sh
nix flake check
```

To try a local copy from a consumer flake:

```sh
nixos-rebuild switch --flake . --override-input chena path:/path/to/chena
```
