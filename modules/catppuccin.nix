# catppuccin/nix Catppuccin Mocha Mauve
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  firefoxThemeId = "{76aabc99-c1a8-4c1e-832b-d4f2941d5a7a}";
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};

  flavor = "mocha";
  accent = "mauve";

  colors = {
    # For niri and slurp
    mauve = "#cba6f7";
    surface1 = "#45475a";
    base = "#1e1e2e";
    mantle = "#181825";
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
  godotSettings = "editor_settings-${lib.versions.majorMinor pkgs.godot.version}.tres";
  godotTheme = {
    color_preset = ''"Custom"'';
    base_color = "Color(0.1176, 0.1176, 0.1804, 1)";
    accent_color = "Color(0.7961, 0.651, 0.9686, 1)";
    contrast = "0.2";
    icon_saturation = "0.6";
    follow_system_theme = "false";
    use_system_accent_color = "false";
  };
  ghidraDir = "ghidra/ghidra_${pkgs.ghidra.version}_NIX";
  catppuccinInsomnia = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "insomnia";
    rev = "de5e3643796afaedb4121cebdec39182ed0646ef";
    hash = "sha256-HC+nknnnOhtYU3XP8k2tlC7QwSgX2sViZHRMa5E0XYk=";
  };
  zapzapCss = pkgs.callPackage ../pkgs/zapzap-catppuccin.nix { inherit flavor accent; };
in
{
  # seeded into VSCode settings.json by applications.nix
  _module.args.catppuccinVscodeSettings = {
    "workbench.colorTheme" = "Catppuccin Mocha";
    "workbench.iconTheme" = "catppuccin-mocha";
    "catppuccin.accentColor" = accent;
  };

  programs.spicetify = {
    theme = spicePkgs.themes.catppuccin;
    colorScheme = flavor;
  };

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

    users.${config.user.name} =
      {
        config,
        lib,
        ...
      }:
      {
        catppuccin = {
          enable = true;
          autoEnable = true;
          inherit flavor accent;
          vscode.profiles.default.enable = false;
          firefox.enable = false;
          gtk.icon.enable = false;
          cursors.enable = false;
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

          firefox = {
            policies.ExtensionSettings.${firefoxThemeId} = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/catppuccin-mocha-mauve-git/latest.xpi";
              installation_mode = "normal_installed";
            };
            profiles.default.settings."extensions.activeThemeID" = firefoxThemeId;
          };

          vscode.profiles.default.extensions = with pkgs.vscode-extensions.catppuccin; [
            catppuccin-vsc
            catppuccin-vsc-icons
          ];

          niri.settings = {
            layout = {
              focus-ring = {
                active.color = hex "mauve";
                inactive.color = hex "mantle";
              };
              border = {
                active.color = hex "mauve";
                inactive.color = hex "mantle";
              };
            };
            overview.backdrop-color = hex "crust";
          };
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

        # Settings the apps rewrite themselves, so they are set in place instead
        # of linked. Missing files are created for a fresh install.
        home.activation.catppuccinApps = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          crudini() { run ${lib.getExe pkgs.crudini} --ini-options=nospace "$@"; }
          godotini() { run ${lib.getExe pkgs.crudini} --ini-options=space "$@"; }
          # sectionless key=value files, put first so they stay out of any section
          setkey() {
            file=$1 key=$2 value=$3
            run mkdir -p "$(dirname "$file")"
            touch "$file"
            tmp=$(mktemp)
            { printf '%s=%s\n' "$key" "$value"; K=$key ${pkgs.gawk}/bin/awk -F= '$1 != ENVIRON["K"]' "$file"; } > "$tmp"
            run mv "$tmp" "$file"
          }

          run mkdir -p "$HOME/.config/keepassxc" "$HOME/.config/obs-studio" "$HOME/.config/ZapZap"
          # classic takes the Kvantum palette, auto and dark use KeePassXC's own colors
          crudini --set "$HOME/.config/keepassxc/keepassxc.ini" GUI ApplicationTheme classic
          crudini --set "$HOME/.config/obs-studio/global.ini" Appearance Theme com.obsproject.Catppuccin.Mocha
          crudini --set "$HOME/.config/ZapZap/ZapZap.conf" custom 'global\css\enabled' true

          setkey "$HOME/.config/kritarc" Theme "Catppuccin Mocha"
          setkey "$HOME/.config/${ghidraDir}/preferences" Theme 'File\:'"$HOME/.config/${ghidraDir}/themes/catppuccin-mocha.theme"

          godot="$HOME/.config/godot/${godotSettings}"
          if [ ! -e "$godot" ]; then
            run mkdir -p "$(dirname "$godot")"
            printf '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n' > "$godot"
          fi
          # color_preset has to be Custom or Godot recomputes base and accent on every start
          ${
            lib.concatStrings (
              lib.mapAttrsToList (
                key: value:
                "godotini --set \"$godot\" resource interface/theme/${key} ${lib.escapeShellArg value}\n"
              ) godotTheme
            )
          }godotini --set "$godot" resource text_editor/theme/color_theme '"Catppuccin Mocha"'

          # Insomnium keeps its settings in sqlite and only creates the database on first run
          insomnium="$HOME/.config/Insomnium/insomnia.sqlite"
          if [ -f "$insomnium" ]; then
            run ${lib.getExe pkgs.sqlite} "$insomnium" \
              "UPDATE docs SET json = json_set(json, '$.theme', 'catppuccin-mocha') WHERE type = 'Settings'"
          fi
        '';

        xdg = {
          # KDE apps read their palette from kdeglobals, Kvantum only does widgets
          configFile = {
            "obs-studio/themes/Catppuccin.obt".source = "${config.catppuccin.sources.obs}/Catppuccin.obt";
            "obs-studio/themes/Catppuccin_Mocha.ovt".source =
              "${config.catppuccin.sources.obs}/Catppuccin_Mocha.ovt";
            "${ghidraDir}/themes/catppuccin-mocha.theme".source = ../config/ghidra/catppuccin-mocha.theme;
            "godot/text_editor_themes/Catppuccin Mocha.tet".source = ../config/godot/catppuccin-mocha.tet;
            "Insomnium/plugins/insomnia-plugin-catppuccin".source = catppuccinInsomnia;
            "kdeglobals".source = ../config/kde/catppuccin-mocha-mauve.colors;
            "blender/${blenderVersion}/scripts/presets/interface_theme/Catppuccin_Mocha_Mauve.xml".source =
              ../config/blender/catppuccin-mocha-mauve.xml;
          };
          dataFile = {
            # Krita lists colour schemes found here, pick it in Settings > General > Window
            "color-schemes/CatppuccinMocha.colors".source = ../config/krita/CatppuccinMocha.colors;
            "ZapZap/customizations/global/css/catppuccin-${flavor}-${accent}.css".source = zapzapCss;
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
