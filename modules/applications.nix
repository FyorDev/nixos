# Application user settings
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    overwriteBackup = true;
    extraSpecialArgs = { inherit inputs; };

    users.${config.user.name} =
      { config, ... }:
      let
        firefox = config.programs.firefox.finalPackage;
        firefoxLauncher = pkgs.writeShellScript "firefox" ''
          exec ${lib.getExe firefox} --marionette --remote-debugging-port --remote-allow-system-access "$@"
        '';
      in
      {
        home.stateVersion = "26.05";

        stylix.targets.firefox.profileNames = [ "default" ];

        programs = {
          fuzzel.enable = true;
          alacritty.enable = true;
          swaylock.enable = true;
          mpv.enable = true;
          zathura.enable = true;
          imv.enable = true;
          firefox = {
            enable = true;
            # hide firefox navigator.webdriver
            package = pkgs.firefox.override {
              extraAutoConfig = ''pref("general.config.sandbox_enabled", false);'';
              extraPrefs = ''
                Services.obs.addObserver(() => {
                  Services.ppmm.loadProcessScript("file://${../config/firefox/hide-webdriver.js}", true);
                }, "final-ui-startup");
              '';
            };
          };
          waybar = {
            enable = true;
            systemd.enable = true;
          };
        };

        home.packages = [
          (lib.hiPrio (
            pkgs.symlinkJoin {
              name = "firefox-hidden-webdriver";
              paths = [ firefox ];
              postBuild = ''
                rm $out/bin/firefox
                ln -s ${firefoxLauncher} $out/bin/firefox
              '';
              inherit (firefox) meta;
            }
          ))
        ];

        services = {
          swayosd.enable = true;
          cliphist.enable = true;
          mako.enable = true;
          blueman-applet.enable = true;
          network-manager-applet.enable = true;
          swayidle = {
            enable = true;
            timeouts = [
              {
                timeout = 900;
                command = "${pkgs.swaylock}/bin/swaylock -f";
              }
            ];
          };
        };
      };
  };
}
