{ pkgs, ... }:
let
  # icons are Nerd Font hex codes
  categories = with pkgs; [
    {
      name = "System";
      icon = "f120";
      packages = [
        # Apps
        alacritty # terminal
        nautilus # files
        # Networking
        wget # file downloading
        # Images
        imagemagick # image operations
        exiftool # image metadata
        # Search
        fuzzel # launcher
        xwayland-satellite # x11 apps under niri
        ripgrep # fuzzy grep
        fd # find
        # Hardware
        clinfo # OpenCL devices
        smartmontools # disk health
        pciutils # lspci
        # Shell
        fish # shell
        fzf # fuzzy finder
        eza # ls replacement
        zoxide # smarter cd
        bat # cat with syntax highlight
        htop # process viewer
        btop
        fastfetch
        nix-your-shell # keep fish inside nix shell
        fishPlugins.bobthefish # fish prompt
        cava # audio visualiser
        tealdeer # tldr pages
        # Nix
        nh # nix helper
      ];
    }
    {
      name = "Dev";
      icon = "f121";
      packages = [
        vim
        neovim
        just

        git # Git
        gh
        git-cliff
        git-lfs
        difftastic
        rumdl # Markdown
        glow
        shellcheck # Bash
        shfmt
        deadnix # Nix
        nixd
        nixfmt
        statix
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
      packages = [ firefox ];
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
      packages = [
      ];
    }
    {
      name = "Util";
      icon = "f0214";
      packages = [
      ];
    }
  ];
in
{
  environment.systemPackages = builtins.concatMap (category: category.packages) categories;
}
