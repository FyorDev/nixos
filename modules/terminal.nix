# Commandline packages and settings
{
  config,
  inputs,
  pkgs,
  ...
}:
{
  imports = [ inputs.nix-index-database.nixosModules.default ];

  users.users.${config.user.name}.shell = pkgs.fish;

  programs = {
    fish = {
      enable = true;
      interactiveShellInit = ''
        nix-your-shell fish | source
      '';
    };
    ssh.extraConfig = ''
      Host git.blahajresidence.nl
        Port 2222
        User git

      Host fyornl
        ProxyCommand ssh fyor.nl -p2 -l fyor nc -w 600 lxc-fyornl 22

      Host up.science.uu.nl
        ForwardAgent yes

      Host blahaj
        HostName 192.168.178.15
        User fyor
    '';
    nh = {
      enable = true;
      flake = "path:${config.users.users.${config.user.name}.home}/nixos";
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

  environment = {
    localBinInPath = true;
    variables = {
      EDITOR = "nvim";
      GIT_EDITOR = "nvim";
      BROWSER = "firefox";
      FGJ_HOST = "git.blahajresidence.nl";
    };
  };

  home-manager.users.${config.user.name} =
    { lib, ... }:
    {
      programs = {
        direnv = {
          enable = true;
          nix-direnv.enable = true;
        };
        bat.enable = true;
        btop.enable = true;
        vim.enable = true;
        fzf = {
          enable = true;
          defaultCommand = "fd --type f --hidden --exclude .git";
          fileWidget.command = "fd --type f --hidden --exclude .git";
          changeDirWidget.command = "fd --type d --hidden --exclude .git";
        };

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
            key = config.user.git.signingKey;
            format = "ssh";
            signByDefault = true;
          };
          settings.user = {
            name = config.user.git.name;
            email = config.user.git.email;
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

      home = {
        # Rust shared target dir
        file.".cargo/config.toml".text = ''
          [build]
          target-dir = "${config.users.users.${config.user.name}.home}/.cache/cargo/target"
          rustc-wrapper = "${pkgs.sccache}/bin/sccache"
          incremental = false

          [target.x86_64-unknown-linux-gnu]
          linker = "${pkgs.clang}/bin/clang"
          rustflags = ["-C", "link-arg=-fuse-ld=${pkgs.mold}/bin/mold"]
        '';
        # fgj keeps its token in this file and rewrites it, so only the protocol is set
        activation.fgjProtocol = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          cfg="$HOME/.config/fgj/config.yaml"
          if [ -f "$cfg" ]; then
            run ${pkgs.yq-go}/bin/yq -i '.hosts."git.blahajresidence.nl".git_protocol = "ssh"' "$cfg"
          fi
        '';
        # lazy.nvim
        activation.nvimConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          dir="$HOME/.config/nvim"
          if [ ! -e "$dir" ]; then
            PATH="${pkgs.openssh}/bin:$PATH" run ${pkgs.git}/bin/git clone \
              git@github.com:FyorDev/kickstart.nvim.git "$dir" || true
          fi
        '';
        sessionVariables.SCCACHE_CACHE_SIZE = "20G";
      };

      xdg.configFile."fastfetch/config.jsonc".source = pkgs.runCommand "fastfetch-config.jsonc" { } ''
        ${pkgs.gnused}/bin/sed \
          -e 's|@LOGO@|${../config/fastfetch/logo.txt}|' \
          -e 's|@HOST_LABEL@|${config.hostLabel}|' \
          ${../config/fastfetch/config.jsonc} > $out
      '';
    };
}
