# Fonts, icons and wallpaper
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
  fonts = {
    packages = [
      fonts.monospace.package
      fonts.sansSerif.package
      fonts.emoji.package
      fonts.symbols.package
      fonts.cjkMonospace.package
      fonts.cjkSerif.package
    ];
    fontconfig.defaultFonts = {
      monospace = [
        fonts.monospace.name
        fonts.symbols.name
        fonts.cjkMonospace.name
      ];
      sansSerif = [
        fonts.sansSerif.name
        fonts.cjkSansSerif.name
      ];
      serif = [
        fonts.serif.name
        fonts.cjkSerif.name
      ];
      emoji = [ fonts.emoji.name ];
    };
  };

  home-manager.users.${config.user.name} = {
    gtk = {
      enable = true;
      iconTheme = {
        package = pkgs.papirus-icon-theme;
        name = "Papirus-Dark";
      };
    };
    dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

    systemd.user.services.swaybg = lib.mkIf (background != null) {
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
  };
}
