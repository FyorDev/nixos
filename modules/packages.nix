{ inputs, pkgs, ... }:
let
  # icons are Nerd Font hex codes
  categories = with pkgs; [
    {
      name = "System";
      icon = "f120";
      packages = [
        alacritty
        fuzzel
        nautilus
      ];
    }
    {
      name = "Dev";
      icon = "f121";
      packages = [
        git
        gh
        just
        deadnix
        nixd
        nixfmt
        statix
        git-cliff
        git-lfs
        rumdl
        shellcheck
        shfmt
      ];
    }
    {
      name = "Gamedev";
      icon = "f1b2";
      packages = [ ];
    }
    {
      name = "Art";
      icon = "f1fc";
      packages = [ ];
    }
    {
      name = "Audio";
      icon = "f001";
      packages = [ ];
    }
    {
      name = "Video";
      icon = "f008";
      packages = [ ];
    }
    {
      name = "CAD";
      icon = "f0ad";
      packages = [ ];
    }
    {
      name = "Browse";
      icon = "f059f";
      packages = [ ];
    }
    {
      name = "Game";
      icon = "f0296";
      packages = [ ];
    }
    {
      name = "Hack";
      icon = "f0825";
      packages = [ ];
    }
    {
      name = "Hardware";
      icon = "e266";
      packages = [ ];
    }
    {
      name = "Util";
      icon = "f0214";
      packages = [ ];
    }
  ];
in
{
  imports = [ inputs.nix-index-database.nixosModules.default ];

  environment.systemPackages = builtins.concatMap (category: category.packages) categories;

  programs = {
    nh = {
      enable = true;
      flake = "path:/home/fyor/nixos";
      clean = {
        enable = true;
        dates = "weekly";
        extraArgs = "--keep 5 --keep-since 14d";
      };
    };
    command-not-found.enable = false;
    nix-index.enable = true;
    nix-index-database.comma.enable = true;
  };
}
