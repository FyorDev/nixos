# Default applications per file type
{
  config,
  lib,
  pkgs,
  ...
}:
let
  apps = [
    {
      pkg = pkgs.loupe;
      file = "org.gnome.Loupe.desktop";
    }
    {
      pkg = pkgs.imv;
      file = "imv.desktop";
    }
    {
      pkg = pkgs.showtime;
      file = "org.gnome.Showtime.desktop";
    }
    {
      pkg = pkgs.decibels;
      file = "org.gnome.Decibels.desktop";
    }
    {
      pkg = pkgs.mpv;
      file = "mpv.desktop";
    }
    {
      pkg = pkgs.papers;
      file = "org.gnome.Papers.desktop";
    }
    {
      pkg = pkgs.zathura;
      file = "org.pwmt.zathura-pdf-mupdf.desktop";
    }
    {
      pkg = pkgs.gnome-text-editor;
      file = "org.gnome.TextEditor.desktop";
    }
    {
      pkg = pkgs.neovim;
      file = "nvim.desktop";
    }
    {
      pkg = pkgs.file-roller;
      file = "org.gnome.FileRoller.desktop";
    }
    {
      pkg = pkgs.nautilus;
      file = "org.gnome.Nautilus.desktop";
    }
    {
      pkg = pkgs.firefox;
      file = "firefox.desktop";
    }
    {
      pkg = pkgs.qbittorrent;
      file = "org.qbittorrent.qBittorrent.desktop";
    }
  ];

  # Extra types not listed in .desktop files
  extras = [
    {
      files = [
        "org.gnome.TextEditor.desktop"
        "nvim.desktop"
      ];
      types = [
        "text/markdown"
        "text/x-python"
        "text/x-python3"
        "text/rust"
        "text/x-nix"
        "text/x-shellscript"
        "application/x-shellscript"
        "text/x-csrc"
        "text/x-chdr"
        "text/x-c++src"
        "text/x-makefile"
        "application/json"
        "application/xml"
        "text/xml"
        "application/toml"
      ];
    }
    {
      files = [
        "org.gnome.Decibels.desktop"
        "mpv.desktop"
      ];
      types = [
        "audio/flac"
        "audio/x-flac"
        "audio/ogg"
        "audio/opus"
        "audio/aac"
        "audio/mp4"
        "audio/x-wav"
      ];
    }
    {
      files = [
        "org.gnome.Loupe.desktop"
        "imv.desktop"
      ];
      types = [ "image/heif" ];
    }
    {
      files = [ "org.gnome.FileRoller.desktop" ];
      types = [ "application/x-bzip2-compressed-tar" ];
    }
    {
      files = [
        "org.gnome.Papers.desktop"
        "org.pwmt.zathura-pdf-mupdf.desktop"
      ];
      types = [ "application/epub+zip" ];
    }
  ];

  typesOf =
    { pkg, file }:
    let
      desktop = builtins.readFile "${pkg}/share/applications/${file}";
      line = lib.findFirst (lib.hasPrefix "MimeType=") "MimeType=" (lib.splitString "\n" desktop);
    in
    lib.filter (type: type != "") (lib.splitString ";" (lib.removePrefix "MimeType=" line));
in
{
  home-manager.users.${config.user.name}.xdg.mimeApps = {
    enable = true;
    defaultApplications = lib.mapAttrs (_: lib.unique) (
      lib.zipAttrsWith (_: lib.concatLists) (
        map ({ files, types }: lib.genAttrs types (_: files)) extras
        ++ map (app: lib.genAttrs (typesOf app) (_: [ app.file ])) apps
      )
    );
  };
}
