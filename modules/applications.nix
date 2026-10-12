# Application user settings
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  vscodeSettings = pkgs.writeText "vscode-settings.json" (
    builtins.toJSON {
      "workbench.colorTheme" = "Catppuccin Mocha";
      "workbench.iconTheme" = "catppuccin-mocha";
      "catppuccin.accentColor" = "mauve";
      "editor.fontFamily" = "'JetBrainsMono Nerd Font'";
      "terminal.integrated.fontFamily" = "'JetBrainsMono Nerd Font'";
      "window.titleBarStyle" = "custom";
    }
  );

  wl-uinput-proxy = pkgs.callPackage ../pkgs/wl-uinput-proxy.nix { };

  obsProfile = "Untitled";
  obsSettings = {
    "user.ini" = {
      General.FirstRun = "true";
      Basic = {
        Profile = obsProfile;
        ProfileDir = obsProfile;
      };
    };
    "basic/profiles/${obsProfile}/basic.ini" = {
      General.Name = obsProfile;
      Output.Mode = "Simple";
      SimpleOutput = {
        FilePath = "${config.users.users.${config.user.name}.home}/Videos/obs";
        RecFormat2 = "hybrid_mp4";
        RecQuality = "Small";
      };
      Video = {
        BaseCX = "3840";
        BaseCY = "2160";
        OutputCX = "3840";
        OutputCY = "2160";
        FPSType = "0";
        FPSCommon = "60";
      };
    };
  };

  obsSetIni =
    file: sections:
    lib.concatStringsSep "\n" (
      lib.concatLists (
        lib.mapAttrsToList (
          section: keys:
          lib.mapAttrsToList (
            key: value:
            "${lib.getExe pkgs.crudini} --set \"$dir/${file}\" ${section} ${key} ${lib.escapeShellArg value}"
          ) keys
        ) sections
      )
    );
in
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    overwriteBackup = true;
    extraSpecialArgs = { inherit inputs; };

    users.${config.user.name} =
      { lib, ... }:
      {
        home.stateVersion = "26.05";

        home.activation = {
          obsDefaults = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            dir="$HOME/.config/obs-studio"
            run mkdir -p "$HOME/Videos/obs" "$dir/basic/profiles/${obsProfile}"
            ${lib.concatStringsSep "\n" (lib.mapAttrsToList obsSetIni obsSettings)}
          '';

          vscodeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            settings="$HOME/.config/Code/User/settings.json"
            if [ ! -e "$settings" ]; then
              run install -Dm644 ${vscodeSettings} "$settings"
            fi
          '';

          # activate VSCode keyring, it does not detect one and suggests
          # to weaken encryption
          vscodeKeyring = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            argv="$HOME/.vscode/argv.json"
            if [ ! -e "$argv" ]; then
              run mkdir -p "$(dirname "$argv")"
              run sh -c "printf '{\n\t\"password-store\": \"gnome-libsecret\"\n}\n' > \"$argv\""
            elif grep -qE '^[[:space:]]*"password-store"' "$argv"; then
              run sed -i -E 's/^([[:space:]]*"password-store"[[:space:]]*:[[:space:]]*)"[^"]*"/\1"gnome-libsecret"/' "$argv"
            else
              run sed -i '0,/{/s//{\n\t"password-store": "gnome-libsecret",/' "$argv"
            fi
          '';
        };

        programs = {
          fuzzel = {
            enable = true;
            settings.main = {
              font = "JetBrainsMono Nerd Font:size=12";
              icon-theme = "Papirus-Dark";
              terminal = "alacritty -e";
              width = 45;
              lines = 15;
            };
          };
          alacritty.enable = true;
          swaylock.enable = true;
          mpv.enable = true;
          zathura.enable = true;
          imv.enable = true;
          waybar = {
            enable = true;
            systemd.enable = true;
          };
          vesktop = {
            enable = true;
            settings = {
              minimizeToTray = false;
              discordBranch = "stable";
            };
            vencord.settings = {
              autoUpdate = false;
              plugins = {
                ClearURLs.enabled = true;
                FakeNitro.enabled = true;
                MessageLogger.enabled = true;
              };
            };
          };

          vscode = {
            enable = true;
            profiles.default.extensions =
              let
                nixpkgs = pkgs.vscode-extensions;
                marketplace = (pkgs.nix-vscode-extensions.forVSCodeVersion pkgs.vscode.version).vscode-marketplace;
              in
              [
                nixpkgs.catppuccin.catppuccin-vsc
                nixpkgs.catppuccin.catppuccin-vsc-icons
                nixpkgs.anthropic.claude-code
                nixpkgs.fill-labs.dependi
                nixpkgs.geequlim.godot-tools
                nixpkgs.ms-dotnettools.csdevkit
                nixpkgs.ms-dotnettools.csharp
                nixpkgs.ms-dotnettools.vscode-dotnet-runtime
                nixpkgs.ms-python.debugpy
                nixpkgs.ms-python.python
                nixpkgs.ms-python.vscode-pylance
                nixpkgs.ms-python.vscode-python-envs
                nixpkgs.ms-vscode.cpptools
                nixpkgs.rust-lang.rust-analyzer
                nixpkgs.svelte.svelte-vscode
                marketplace."1yib".rust-bundle
                marketplace."1yib".svelte-bundle
                marketplace.ardenivanov.svelte-intellisense
                marketplace.bdrisc.agda2-vscode
                marketplace.dbcode.dbcode
                marketplace.dtoplak.vscode-glsllint
                marketplace.dustypomerleau.rust-syntax
                marketplace.fivethree.vscode-svelte-snippets
                marketplace.glen-anderson.vscode-faust
                marketplace.j-mueller.agda
                marketplace.jeronimoekerdt.color-picker-universal
                marketplace.orbenozio.claude-code-nonstop
                marketplace.platformio.platformio-ide
                marketplace.slevesque.shader
                marketplace.visualstudiotoolsforunity.vstuc
              ];
          };
        };

        services = {
          polkit-gnome.enable = true; # password prompt for mounting etc
          swayosd.enable = true;
          cliphist.enable = true;
          mako = {
            enable = true;
            settings = {
              anchor = "top-center";
              default-timeout = 3000;
            };
          };
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

        systemd.user.services.lan-mouse = {
          Unit = {
            Description = "Lan Mouse";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session.target" ];
          };
          Service = {
            ExecStart = "${lib.getExe wl-uinput-proxy} ${lib.getExe pkgs.lan-mouse} daemon";
            Restart = "on-failure";
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };
      };
  };
}
