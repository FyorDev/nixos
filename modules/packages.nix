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
        fuzzel # launcher
        swaylock # lockscreen
        swaybg # wallpaper
        wl-clipboard # wl-copy and wl-paste
        cliphist # clipboard history
        grim # screenshots
        slurp # region selection
        swappy # screenshot annotation
        playerctl # media keys
        xwayland-satellite # x11 apps under niri
        appimage-run # run AppImages
        # Networking
        wget # file downloading
        # Archives
        zip # zip creation
        unzip # zip extraction
        p7zip # 7z support
        unrar # rar extraction
        # Images
        imagemagick # image operations
        exiftool # image metadata
        # Search
        ripgrep # fuzzy grep
        fd # find
        # Hardware
        clinfo # OpenCL devices
        smartmontools # disk health
        pciutils # lspci
        brightnessctl # backlight
        bluez # bluetoothctl
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
      name = "Desktop";
      icon = "f108";
      packages = [
        # Apps
        alacritty # terminal
        nautilus # files
        file-roller # archive manager
        virt-manager # virtual machines
        openrgb # rgb lighting
        baobab # disk usage analyzer
        gparted # partition editor
        gnome-disk-utility # disks, smart and disk images
        gnome-text-editor # text editor
        impression # usb flasher
        gnome-decoder # qr scanner and generator
        hieroglyphic # latex symbol finder
        # Media
        imv # image viewer
        loupe # gnome image viewer
        mpv # video player
        showtime # gnome video player
        decibels # gnome audio player
        zathura # minimal document viewer
        papers # gnome document viewer
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
