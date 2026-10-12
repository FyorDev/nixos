{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  insomnium = pkgs.callPackage ../pkgs/insomnium.nix { };
  claude-desktop = pkgs.callPackage ../pkgs/claude-desktop.nix { };
  inky = pkgs.callPackage ../pkgs/inky.nix { };
  fgj = pkgs.callPackage ../pkgs/fgj.nix { };
  curseforge = pkgs.callPackage ../pkgs/curseforge.nix { };
  zotify = pkgs.callPackage ../pkgs/zotify.nix { };
  # wine with the fix for FL Studio 26.1.4+ refusing to start (wine MR 11824,
  # TODO: drop the patch once it reaches a release)
  wine-signedattrs-fix = pkgs.wineWow64Packages.stable.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ../pkgs/patches/wine-crypt32-preserve-signedattrs-order.patch
    ];
  });
  fl-studio = pkgs.callPackage ../pkgs/fl-studio.nix {
    wine = wine-signedattrs-fix;
    nestedCompositor = true; # labwc in niri, fixes black space on resize
  };
  spicetify = config.programs.spicetify.spicedSpotify;
  fmod-studio = pkgs.callPackage ../pkgs/fmod-studio.nix {
    credentials = config.age.secrets.fmod.path;
  };

  # stock firefox, no marionette
  firefox-plain = pkgs.symlinkJoin {
    name = "firefox-plain";
    paths = [
      (pkgs.writeShellScriptBin "firefox-plain" ''
        exec ${lib.getExe pkgs.firefox} --no-remote --profile "$HOME/.config/mozilla/firefox/default" "$@"
      '')
      (pkgs.makeDesktopItem {
        name = "firefox-plain";
        desktopName = "Firefox (plain)";
        exec = "firefox-plain %U";
        icon = "firefox";
        categories = [
          "Network"
          "WebBrowser"
        ];
      })
    ];
  };

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
        swayidle # lock
        waybar # top bar
        mako # notifications
        swayosd # volume and brightness popup
        blueman # bluetooth applet
        networkmanagerapplet # wifi applet
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
        ethtool # network card settings (wake-on-lan)

        # Archives
        zip # zip creation
        unzip # zip extraction
        p7zip # 7z support
        unrar # rar extraction

        # Images
        imagemagick # image operations
        exiftool # image metadata
        # Video
        ffmpeg # video and audio conversion
        yt-dlp # youtube downloader
        zotify # spotify downloader

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
        nushell

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
        term # my own terminal yippee :D

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
        vscode
        just
        tokei # lines of code per language
        tree-sitter # neovim parser builds
        claude-code
        claude-desktop
        github-copilot-cli

        git # Git
        gh
        fgj # forgejo cli
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
        rustup # Rust, also manages rust-analyzer
        sccache # shared compiler cache
        mold # fast linker
        gcc # C and C++
        clang
        clang-tools # clangd, clang-format, clang-tidy
        cppcheck
        gnumake
        dotnetCorePackages.sdk_10_0 # C#, includes the runtime
        nodejs # Javascript/Typescript
        typescript-language-server
        python3 # Python
        python3Packages.pip
        pyright # LSP
        gdtoolkit_4 # GDScript lint and format
        qmk # keyboard firmware
        faust # audio DSP language
      ];
    }
    {
      name = "Gamedev";
      icon = "f1b2";
      packages = [
        godot
        unityhub
        aseprite
        ldtk # levels
        fmod-studio
        inklecate
        inky
      ];
    }
    {
      name = "Art";
      icon = "f1fc";
      packages = [
        blender
        krita
        inkscape
        darktable
        pureref
        goxel
        config.programs.xppen.package # XP Pen Artist 22R Pro
      ];
    }
    {
      name = "Audio";
      icon = "f001";
      packages = [
        vcv-rack
        fl-studio # windows version under wine
      ];
    }
    {
      name = "Video";
      icon = "f008";
      packages = [
        kdePackages.kdenlive
        davinci-resolve # run with nvidia-offload on legion
        obs-studio
      ];
    }
    {
      name = "CAD";
      icon = "f0ad";
      packages = [
        # TODO: re-enable once vtk builds in nixpkgs
        # freecad
        kicad
        prusa-slicer
        qidi-studio
      ];
    }
    {
      name = "Browse";
      icon = "f059f";
      packages = [
        firefox
        firefox-plain # without marionette
        chromium
        signal-desktop
        vesktop # discord
        zapzap # whatsapp
        qbittorrent
        spicetify # spotify
      ];
    }
    {
      name = "Game";
      icon = "f0296";
      packages = [
        config.programs.steam.package
        protontricks
        gamemode
        gamescope
        ckan
        prismlauncher
        curseforge
        wineWow64Packages.stable
        winetricks
      ];
    }
    {
      name = "Hack";
      icon = "f0825";
      packages = [
        nmap # scan ports
        xh # http client
        burpsuite # sniff traffic
        insomnium # test api
        ghidra # decompiling
        imhex # hex editor
        wireshark # packet capture
      ];
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
        obsidian
        keepassxc
        syncthing
        lan-mouse # share mouse and keyboard between machines

        cowsay
        cbonsai
        figlet
        lolcat
        pipes
        sl
      ];
    }
  ];

  # .desktop files to Super+S app-menu
  desktopEntries =
    let
      hidden = [
        # I do not want command-only apps except for neovim
        "btop.desktop"
        "htop.desktop"
        "vim.desktop"
        "gvim.desktop"
        "wine.desktop"
        "winetricks.desktop"
      ];
      rename = {
        "vesktop.desktop" = "Discord";
        "com.rtosta.zapzap.desktop" = "WhatsApp";
      };
    in
    pkgs.runCommand "desktop-entries" { } ''
      mkdir -p $out/share/applications
      cd $out/share/applications

      ${lib.concatMapStrings (
        category:
        lib.concatMapStrings (pkg: ''
          for f in ${pkg}/share/applications/*.desktop; do
            [ -e "$f" ] || continue
            name=$(basename "$f")
            [ -e "$name" ] && continue
            if grep -q '^Keywords=' "$f"; then
              sed 's/^Keywords=/Keywords=${category.name};/' "$f" > "$name"
            else
              sed '0,/^\[Desktop Entry\]/s//&\nKeywords=${category.name};/' "$f" > "$name"
            fi
          done
        '') category.packages
      ) categories}

      # Hidden=true deleting entries
      ${lib.concatMapStrings (name: ''
        printf '[Desktop Entry]\nType=Application\nName=hidden\nNoDisplay=true\nHidden=true\n' > ${name}
      '') hidden}

      ${lib.concatStrings (
        lib.mapAttrsToList (file: newName: ''
          if [ -e ${lib.escapeShellArg file} ]; then
            old=$(sed -n 's/^Name=//p' ${lib.escapeShellArg file} | head -1)
            sed -i -e 's/^Name=.*/Name=${newName}/' -e "s/^Keywords=.*/&$old;/" ${lib.escapeShellArg file}
          fi
        '') rename
      )}
    '';

  app-menu = pkgs.callPackage ../pkgs/app-menu.nix {
    inherit desktopEntries;
    categoryOrder = map (c: { inherit (c) name icon; }) categories;
  };
in
{
  programs.spicetify =
    let
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      enable = true;
      theme = spicePkgs.themes.catppuccin;
      colorScheme = "mocha";
      enabledExtensions = with spicePkgs.extensions; [
        adblockify
        keyboardShortcut
        history
        volumePercentage
      ];
    };

  environment.systemPackages = builtins.concatMap (category: category.packages) categories ++ [
    app-menu
  ];

  home-manager.users.${config.user.name}.xdg.dataFile."applications" = {
    recursive = true;
    source = "${desktopEntries}/share/applications";
  };
}
