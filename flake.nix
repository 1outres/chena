{
  description = "An opinionated Hyprland desktop for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Only the checks use this. Consumers bring their own Home Manager.
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
    }:
    let
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      nixosModules.default = ./modules/nixos;

      homeModules.default = ./modules/home;

      packages = forAllSystems (pkgs: {
        preview = import ./preview { inherit pkgs home-manager self; };
      });

      checks = forAllSystems (
        pkgs:
        import ./tests {
          inherit
            pkgs
            nixpkgs
            home-manager
            self
            ;
        }
        // {
          # Building it runs shellcheck over the script.
          inherit (self.packages.${pkgs.stdenv.hostPlatform.system}) preview;
        }
      );

      formatter = forAllSystems (pkgs: pkgs.nixfmt);
    };
}
