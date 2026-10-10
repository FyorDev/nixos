# Claude Code user config and MCP servers
{
  config,
  lib,
  pkgs,
  ...
}:
let
  fgj = pkgs.callPackage ../pkgs/fgj.nix { };
  obsPassword = config.age.secrets.obs-websocket.path;
  mcps = pkgs.callPackage ../pkgs/mcp.nix { };
  blenderMcp = mcps.blender;
  blenderVersion = lib.versions.majorMinor pkgs.blender.version;
  # Language server per mcp entry
  lsp =
    server: args:
    toString (
      pkgs.writeShellScript "lsp" ''
        exec ${pkgs.mcp-language-server}/bin/mcp-language-server --workspace "$PWD" --lsp ${server} ${
          lib.optionalString (args != [ ]) "-- ${lib.escapeShellArgs args}"
        }
      ''
    );
in
{
  home-manager.users.${config.user.name} =
    { config, lib, ... }:
    let
      firefox = config.programs.firefox.finalPackage;
      firefoxLauncher = pkgs.writeShellScript "firefox" ''
        exec ${lib.getExe firefox} --marionette --remote-debugging-port --remote-allow-system-access "$@"
      '';
    in
    {
      # Hide firefox being a navigator.webdriver
      programs.firefox.package = pkgs.firefox.override {
        extraAutoConfig = ''pref("general.config.sandbox_enabled", false);'';
        extraPrefs = ''
          Services.obs.addObserver(() => {
            Services.ppmm.loadProcessScript("file://${../config/firefox/hide-webdriver.js}", true);
          }, "final-ui-startup");
        '';
      };

      home = {
        # skip the folder trust prompts
        sessionVariables = {
          CLAUDE_CODE_SANDBOXED = "1";
          COPILOT_ALLOW_ALL = "true";
        };

        packages = [
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

        activation = {
          # copilot rewrites settings.json itself, so the keys are merged into whatever is there
          copilotSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            settings="$HOME/.copilot/settings.json"
            mkdir -p "$(dirname "$settings")"
            [ -s "$settings" ] || echo '{}' > "$settings"
            ${pkgs.jq}/bin/jq '. + { defaultMode: "autopilot", defaultPermissionMode: "allow-all" }' \
              "$settings" > "$settings.new" && mv "$settings.new" "$settings"
          '';

          # Turn on obs websocket using agenix OBS_MC_PASSWORD
          obsWebsocket = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            cfg="$HOME/.config/obs-studio/plugin_config/obs-websocket/config.json"
            if [ -r ${obsPassword} ]; then
              run mkdir -p "$(dirname "$cfg")"
              [ -f "$cfg" ] || echo '{}' > "$cfg"
              ${pkgs.jq}/bin/jq --arg pw "$(cat ${obsPassword})" \
                '. + { server_enabled: true, auth_required: true, server_password: $pw, server_port: 4455, first_load: false }' \
                "$cfg" > "$cfg.new" && run mv "$cfg.new" "$cfg"
              run chmod 600 "$cfg"
            fi
          '';
          # Enable Krita plugin in kritarc
          kritaMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            kritarc="$HOME/.config/kritarc"
            if [ -f "$kritarc" ]; then
              if grep -q '^\[python\]$' "$kritarc"; then
                run ${pkgs.gawk}/bin/awk '
                  BEGIN { in_python = 0; found = 0 }
                  /^\[/ {
                    if (in_python && !found) { print "enable_kritamcp=true"; found = 1 }
                    in_python = ($0 == "[python]")
                  }
                  in_python && /^enable_kritamcp=/ {
                    if (!found) { print "enable_kritamcp=true"; found = 1 }
                    next
                  }
                  { print }
                  END { if (in_python && !found) print "enable_kritamcp=true" }
                ' "$kritarc" > "$kritarc.new" && run mv "$kritarc.new" "$kritarc"
              else
                run printf '\n[python]\nenable_kritamcp=true\n' >> "$kritarc"
              fi
            fi
          '';
        };
      };

      # Enable MCP addons in software
      xdg = {
        configFile = {
          "blender/${blenderVersion}/scripts/addons/blender_mcp.py".source = "${blenderMcp}/addon.py";
          "blender/${blenderVersion}/scripts/startup/enable_addons.py".source = ../config/blender/startup.py;
        };
        dataFile = {
          "krita/pykrita/kritamcp".source = "${mcps.krita}/share/krita-mcp/pykrita/kritamcp";
          "krita/pykrita/kritamcp.desktop".source = "${mcps.krita}/share/krita-mcp/pykrita/kritamcp.desktop";
          "FreeCAD/Mod/FreeCADMCP".source = "${mcps.freecad}/share/freecad-mcp/Mod/FreeCADMCP";
          "burp-mcp/burp-mcp-all.jar".source = pkgs.fetchurl {
            url = "https://github.com/PortSwigger/mcp-server/releases/download/v1.3.0/burp-mcp-all.jar";
            hash = "sha256-xAESRe59oMuQG5wENauj2EWKtbDiB44ah/0CXtk8eJI=";
          };
        };
      };

      programs.claude-code = {
        enable = true;
        package = null;
        settings = {
          theme = "dark";
          permissions.defaultMode = "bypassPermissions";
          # no are you sure screen when starting in bypass mode
          skipDangerousModePermissionPrompt = true;
          # empty strings drop the Co-Authored-By trailer and the Generated with Claude Code line
          attribution = {
            commit = "";
            pr = "";
          };
        };
        context = ''
          # Writing style

          - Never use em dashes. Use a comma, colon, parentheses or a new sentence.

          # Git

          - Never add Co-Authored-By trailers or any other mention of Claude or AI
            to commit messages or pull request descriptions.

          # Symbols

          - Never use emojis or decorative symbols in code, comments, strings,
            log output, commit messages or docs. Typical offenders to avoid:
            check marks and crosses, warning signs, sparkles and rockets,
            arrows, bullets, box-drawing banners, and typographic quotes or
            ellipses. Use plain ASCII.

          # Code comments

          - AI-written code comes out far too heavily commented by default. Do not
            do this. Write fewer comments than feels natural, and match the comment
            density of the surrounding code.
          - Do not narrate what the code does. Comment only the non-obvious why:
            a hidden constraint, a workaround, a surprising choice.
          - Never use comments as a notepad. No running thoughts, reasoning
            trails, "changed X because Y" history, TODO musings, or notes to the
            reader about this edit. That belongs in the commit message or the reply.
          - Remove empty inkspace directories when done taking notes
        '';
        mcpServers = {
          nixos.command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
          git.command = "${pkgs.mcp-server-git}/bin/mcp-server-git";
          godot = {
            command = "${pkgs.godot-mcp}/bin/godot-mcp";
            env.GODOT_PATH = "${pkgs.godot}/bin/godot";
          };
          github.command = toString (
            pkgs.writeShellScript "github-mcp" ''
              export GITHUB_PERSONAL_ACCESS_TOKEN="$(${pkgs.gh}/bin/gh auth token)"
              exec ${pkgs.github-mcp-server}/bin/github-mcp-server stdio --toolsets default,projects,git,labels,actions,notifications
            ''
          );
          forgejo.command = toString (
            pkgs.writeShellScript "forgejo-mcp" ''
              export FORGEJO_URL=https://git.blahajresidence.nl
              export FORGEJO_ACCESS_TOKEN="$(FGJ_HOST=git.blahajresidence.nl ${fgj}/bin/fgj auth token)"
              exec ${pkgs.forgejo-mcp}/bin/forgejo-mcp
            ''
          );
          firefox = {
            command = "${pkgs.firefox-devtools-mcp}/bin/firefox-devtools-mcp";
            args = [
              "--connect-existing"
              "--marionette-port"
              "2828"
              "--enable-script"
            ];
          };
          ghidra.command = toString (
            pkgs.writeShellScript "reva-mcp" ''
              export JAVA_HOME=${pkgs.jdk21}
              export GHIDRA_INSTALL_DIR=${pkgs.ghidra}/lib/ghidra
              export NIX_GHIDRAHOME=${pkgs.ghidra.withExtensions (e: [ e.reva ])}/lib/ghidra/Ghidra
              exec ${pkgs.mcp-reva}/bin/mcp-reva "$@"
            ''
          );
          inkscape.command = "${mcps.inkscape}/bin/inkscape-mcp";
          krita.command = "${mcps.krita}/bin/krita-mcp";
          wireshark.command = "${mcps.wireshark}/bin/wireshark-mcp";
          kicad.command = "${mcps.kicad}/bin/kicad-mcp";
          freecad.command = "${mcps.freecad}/bin/freecad-mcp";
          obs.command = toString (
            pkgs.writeShellScript "obs-mcp" ''
              OBS_MCP_PASSWORD="$(cat ${obsPassword})"
              export OBS_MCP_PASSWORD
              exec ${mcps.obs}/bin/obs-studio-mcp
            ''
          );
          davinci-resolve.command = "${mcps."davinci-resolve"}/bin/davinci-resolve-mcp";
          nmap.command = "${mcps.nmap}/bin/nmap-mcp";
          blender = {
            command = "${blenderMcp}/bin/mcp-for-blender";
            env.DISABLE_TELEMETRY = "true";
          };
          # Load once in burp: Extensions > Add > Java
          burp = {
            type = "sse";
            url = "http://127.0.0.1:9876";
          };
          # Vault info
          obsidian.command = toString (
            pkgs.writeShellScript "obsidian-mcp" ''
              registry="$HOME/.config/obsidian/obsidian.json"
              args=()
              i=0
              if [ -f "$registry" ]; then
                while IFS= read -r vault; do
                  [ -d "$vault/.obsidian" ] || continue
                  i=$((i + 1))
                  args+=(--vault "vault$i=$vault")
                done < <(${pkgs.jq}/bin/jq -r '.vaults[]?.path' "$registry")
              fi
              if [ "$i" -eq 0 ]; then
                echo "obsidian-mcp: no Obsidian vault found, open one in Obsidian first" >&2
                exit 1
              fi
              exec ${mcps.obsidian}/bin/obsidian-mcp serve "''${args[@]}"
            ''
          );
          lsp-csharp.command = lsp "${pkgs.csharp-ls}/bin/csharp-ls" [ ];
          lsp-bash.command = lsp "${pkgs.bash-language-server}/bin/bash-language-server" [ "start" ];
          lsp-svelte.command = lsp "${pkgs.svelte-language-server}/bin/svelteserver" [ "--stdio" ];
          lsp-glsl.command = lsp "${pkgs.glsl_analyzer}/bin/glsl_analyzer" [ ];
          lsp-wgsl.command = lsp "${pkgs.wgsl-analyzer}/bin/wgsl-analyzer" [ ];
          lsp-rust.command = lsp "${pkgs.rustup}/bin/rust-analyzer" [ ];
          lsp-nix.command = lsp "${pkgs.nixd}/bin/nixd" [ ];
          lsp-python.command = lsp "${pkgs.pyright}/bin/pyright-langserver" [ "--stdio" ];
          lsp-cpp.command = lsp "${pkgs.clang-tools}/bin/clangd" [ ]; # c and c++
          lsp-typescript.command = lsp "${pkgs.typescript-language-server}/bin/typescript-language-server" [
            "--stdio"
          ];
        };
      };
    };
}
