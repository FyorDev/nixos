# Stylix and theme config
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # gitignored, optional
  background = lib.findFirst builtins.pathExists null [
    ../background.png
    ../background.jpg
  ];

  fonts = {
    monospace = {
      package = pkgs.nerd-fonts.jetbrains-mono;
      name = "JetBrainsMono Nerd Font";
    };
    sansSerif = {
      package = pkgs.noto-fonts;
      name = "Noto Sans";
    };
    serif = {
      package = pkgs.noto-fonts;
      name = "Noto Serif";
    };
    emoji = {
      package = pkgs.noto-fonts-color-emoji;
      name = "Noto Color Emoji";
    };
    symbols = {
      package = pkgs.nerd-fonts.symbols-only;
      name = "Symbols Nerd Font Mono";
    };
    cjkMonospace = {
      # Chinese, Japanese, Korean
      package = pkgs.noto-fonts-cjk-sans;
      name = "Noto Sans Mono CJK JP";
    };
    cjkSansSerif = {
      package = pkgs.noto-fonts-cjk-sans;
      name = "Noto Sans CJK JP";
    };
    cjkSerif = {
      package = pkgs.noto-fonts-cjk-serif;
      name = "Noto Serif CJK JP";
    };
  };
in
{
  stylix = {
    enable = true;
    polarity = "dark";
    image = lib.mkIf (background != null) background;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    override.base0D = "cba6f7"; # mauve accent

    icons = {
      enable = true;
      package = pkgs.papirus-icon-theme;
      dark = "Papirus-Dark";
      light = "Papirus";
    };

    fonts = {
      inherit (fonts)
        monospace
        sansSerif
        serif
        emoji
        ;
      sizes = {
        terminal = 11;
        applications = 11;
        desktop = 11;
        popups = 11;
      };
    };
  };

  fonts = {
    packages = [
      fonts.symbols.package
      fonts.cjkMonospace.package
      fonts.cjkSerif.package
    ];
    fontconfig.defaultFonts = {
      monospace = [
        fonts.symbols.name
        fonts.cjkMonospace.name
      ];
      sansSerif = [ fonts.cjkSansSerif.name ];
      serif = [ fonts.cjkSerif.name ];
    };
  };

  home-manager.users.${config.user.name}.systemd.user.services.swaybg =
    lib.mkIf (background != null)
      {
        Unit = {
          # swap the wallpaper live
          Description = "Wallpaper";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${lib.getExe pkgs.swaybg} -m fill -i ${background}";
          Restart = "on-failure";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
}
