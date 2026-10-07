{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
    niri.url = "github:sodiboo/niri-flake";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      hosts = [
        "asus"
        "legion"
      ];

      mkHost =
        name:
        inputs.nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            { disabledModules = [ "programs/wayland/niri.nix" ]; }
            inputs.niri.nixosModules.niri
            inputs.home-manager.nixosModules.home-manager
            ./modules/common.nix
            ./modules/home.nix
            ./modules/shell.nix
            ./modules/packages.nix
            ./hosts/${name}/configuration.nix
            { networking.hostName = name; }
          ];
        };
    in
    {
      nixosConfigurations = inputs.nixpkgs.lib.genAttrs hosts mkHost;
    };
}
