{
  config,
  inputs,
  pkgs,
  ...
}:
{
  imports = [ inputs.nix-index-database.nixosModules.default ];

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      nix-your-shell fish | source
    '';
  };
  users.users.fyor.shell = pkgs.fish;

  programs = {
    nh = {
      enable = true;
      flake = "path:/home/fyor/nixos";
      clean = {
        enable = true;
        dates = "weekly";
        extraArgs = "--keep 5 --keep-since 14d";
      };
    };
    command-not-found.enable = false;
    nix-index.enable = true;
    nix-index-database.comma.enable = true;
    zoxide.enable = true;
    fzf.keybindings = true;
    git = {
      enable = true;
      lfs.enable = true;
      config = {
        init.defaultBranch = "main";
        push.autoSetupRemote = true;
        core.hooksPath = ".githooks";
        diff = {
          tool = "difftastic";
          external = "difft";
        };
        difftool = {
          prompt = false;
          difftastic.cmd = ''difft "$LOCAL" "$REMOTE"'';
        };
        pager.difftool = true;
        alias = {
          l = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %C(brightgreen)%s %C(dim blue)(%cr)%C(reset) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
          s = "status";
          f = "fetch";
          a = "add .";
          c = "commit";
          p = "push";
        };
      };
    };
  };

  fonts.packages = with pkgs; [
    nerd-fonts.symbols-only
    nerd-fonts.fira-code
    nerd-fonts.hack
  ];
  fonts.fontconfig.defaultFonts = {
    monospace = [
      "JetBrainsMono Nerd Font"
      "Symbols Nerd Font Mono"
    ];
    sansSerif = [ "Symbols Nerd Font" ];
    serif = [ "Symbols Nerd Font" ];
  };

  environment = {
    localBinInPath = true;
    variables = {
      EDITOR = "nvim";
      GIT_EDITOR = "nvim";
      BROWSER = "firefox";
      FZF_DEFAULT_COMMAND = "fd --type f --hidden --exclude .git";
      FZF_CTRL_T_COMMAND = "fd --type f --hidden --exclude .git";
      FZF_ALT_C_COMMAND = "fd --type d --hidden --exclude .git";
    };
  };

  home-manager.users.fyor = {
    programs = {
      fish = {
        enable = true;
        plugins = [
          {
            name = "bobthefish";
            inherit (pkgs.fishPlugins.bobthefish) src;
          }
        ];
        shellInit = builtins.readFile ../config/fish/config.fish;
      };

      git = {
        enable = true;
        signing = {
          key = "~/.ssh/id_rsa.pub";
          format = "ssh";
          signByDefault = true;
        };
        settings.user = {
          name = "FyorDev";
          email = "uuf@fyor.nl";
        };
      };

      tealdeer = {
        enable = true;
        settings.updates.auto_update = true;
      };
      cava = {
        enable = true;
        settings.output = {
          channels = "mono";
          mono_option = "average";
        };
      };
    };

    xdg.configFile."fastfetch/config.jsonc".source = pkgs.runCommand "fastfetch-config.jsonc" { } ''
      ${pkgs.gnused}/bin/sed \
        -e 's|@LOGO@|${../config/fastfetch/logo.txt}|' \
        -e 's|@HOST_LABEL@|${config.hostLabel}|' \
        ${../config/fastfetch/config.jsonc} > $out
    '';
  };
}
