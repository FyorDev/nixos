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
        xwayland-satellite # x11 apps under niri
        appimage-run # run AppImages

        fuzzel # launcher
        swaylock # lockscreen
        swaybg # wallpaper
        playerctl # media keys
        hyprpicker # colour picker
        tesseract # ocr
        libnotify # notify-send
        xdg-utils # xdg-open and xdg-mime
        nwg-displays # monitor layout gui
        pavucontrol # volume mixer

        wl-clipboard # wl-copy and wl-paste
        cliphist # clipboard history

        grim # screenshots
        slurp # region selection
        swappy
        # screenshot annotation
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
        nix-your-shell # nix shell starts fish
        fishPlugins.bobthefish # fish prompt
        fzf # fuzzy finder
        eza # ls replacement
        zoxide # smarter cd

        fastfetch
        bat # cat with syntax highlight
        htop # process viewer
        btop
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
        ffmpegthumbnailer # video and audio cover thumbnails
        glycin-thumbnailer # HEIF/AVIF, JPEG XL, SVG
        glycin-loaders # loaders
        webp-pixbuf-loader # webp
        gnome-epub-thumbnailer # epub

        file-roller # archive manager
        gnome-disk-utility # disks, smart and disk images
        baobab # disk usage analyzer
        gparted # partition editor
        impression # usb flasher

        gnome-text-editor # text editor
        gnome-decoder # qr scanner and generator
        hieroglyphic # latex symbol finder

        virt-manager # virtual machines
        openrgb # rgb lighting

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
      packages = [
        kdePackages.kdenlive
      ];
    }
    {
      name = "CAD";
      icon = "f0ad";
      packages = [ ];
    }
    {
      name = "Browse";
      icon = "f059f";
      packages = [
        firefox
        qbittorrent
      ];
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
