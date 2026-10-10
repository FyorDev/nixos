{ pkgs, ... }:
let
  # icons are Nerd Font hex codes
  categories = with pkgs; [
    {
      name = "System";
      icon = "f120";
      packages = [
        # Desktop
        niri-unstable # compositor
        appimage-run # run AppImages
        fuzzel # launcher
        swaylock # lockscreen
        swaybg # wallpaper
        wl-clipboard # wl-copy and wl-paste
        cliphist # clipboard history
        grim # screenshots
        slurp # region selection
        swappy # screenshot annotation
        playerctl # media keys
        # Apps
        alacritty # terminal
        nautilus # files
        virt-manager # virtual machines
        # Networking
        wget # file downloading
        # Images
        imagemagick # image operations
        exiftool # image metadata
        # Search
        xwayland-satellite # x11 apps under niri
        ripgrep # fuzzy grep
        fd # find
        # Hardware
        clinfo # OpenCL devices
        smartmontools # disk health
        pciutils # lspci
        brightnessctl # backlight
        bluez # bluetoothctl
        openrgb # rgb lighting
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
        direnv # per-folder environments
        nix-direnv # fast direnv for nix
        nix-index # file search for nixpkgs
        comma # run any package with ,
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
