# catppuccin/nix Catppuccin Mocha Mauve
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  flavor = "mocha";
  accent = "mauve";

  colors = {
    # For niri and slurp
    mauve = "#cba6f7";
    surface1 = "#45475a";
    base = "#1e1e2e";
    crust = "#11111b";
  };
  hex = name: colors.${name};
  hexRaw = name: lib.removePrefix "#" colors.${name};

  gtkTheme = {
    name = "catppuccin-${flavor}-${accent}-standard";
    package = pkgs.catppuccin-gtk.override {
      accents = [ accent ];
      variant = flavor;
    };
  };

  blenderVersion = lib.versions.majorMinor pkgs.blender.version;
in
{
  catppuccin = {
    enable = true;
    autoEnable = true;
    inherit flavor accent;
    cache.enable = true; # ports built with whiskers come prebuilt
  };

  # slurp selection box for screenshots
  environment.sessionVariables.SLURP_ARGS = "-d -b ${hexRaw "base"}99 -c ${hexRaw "mauve"}ff -s 00000000 -w 2";

  home-manager = {
    sharedModules = [ inputs.catppuccin.homeModules.catppuccin ];

    users.${config.user.name} = _: {
      catppuccin = {
        enable = true;
        autoEnable = true;
        inherit flavor accent;
        vscode.profiles.default.enable = false;
        firefox.enable = false;
        gtk.icon.enable = false;
        cursors.enable = false;
        waybar.mode = "createLink";
      };

      # modules that only theme what is enabled through home-manager
      programs = {
        bat.enable = true;
        btop.enable = true;
        eza = {
          enable = true;
          enableFishIntegration = false;
        };
        cava.enable = true;
      };

      # GTK 3 and 4 (libadwaita and gnome apps), icons with Catppuccin folders
      gtk = {
        enable = true;
        theme = gtkTheme;
        gtk4.theme = gtkTheme;
        iconTheme = {
          package = pkgs.papirus-icon-theme;
          name = "Papirus-Dark";
        };
      };
      home.pointerCursor = {
        enable = true;
        package = pkgs.adwaita-icon-theme;
        name = "Adwaita";
        size = 24;
        gtk.enable = true;
      };
      dconf.settings."org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        icon-theme = "Papirus-Dark"; # nautilus and other GTK 4 apps read this
        accent-color = "purple"; # closest to mauve
        monospace-font-name = "JetBrainsMono Nerd Font 11";
      };

      # Qt apps (Krita, KeePassXC, Kdenlive, qBittorrent) through Kvantum
      qt = {
        enable = true;
        platformTheme.name = "kvantum";
        style.name = "kvantum";
      };

      programs.niri.settings = {
        layout = {
          focus-ring = {
            active.color = hex "mauve";
            inactive.color = hex "surface1";
          };
          border = {
            active.color = hex "mauve";
            inactive.color = hex "surface1";
          };
        };
        overview.backdrop-color = hex "crust";
      };

      xdg = {
        # KDE apps read their palette from kdeglobals, Kvantum only does widgets
        configFile = {
          "kdeglobals".source = ../config/kde/catppuccin-mocha-mauve.colors;
          "blender/${blenderVersion}/scripts/presets/interface_theme/Catppuccin_Mocha_Mauve.xml".source =
            ../config/blender/catppuccin-mocha-mauve.xml;
        };
        dataFile = {
          # Krita lists colour schemes found here, pick it in Settings > General > Window
          "color-schemes/CatppuccinMocha.colors".source = ../config/krita/CatppuccinMocha.colors;
          # ImHex, pick it in Extras > Settings > Interface > Color Theme
          "imhex/themes/catppuccin-mocha.json".source = pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/catppuccin/imhex/cbac7a79c9ef707efdcc9acfa65e30ca09a61b39/themes/catppuccin-mocha.json";
            sha256 = "14nrmq0p2bp9s7skhifay2f93ffml0d0ajfxaj12l7p5ihp2pi0a";
          };
        };
      };
    };
  };
}
