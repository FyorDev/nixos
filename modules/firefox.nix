# Firefox: add-ons from addons.mozilla.org, policies, privacy settings and
# Stylus styles. The command itself is wrapped for automation in claude.nix.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # one file each in config/firefox/styles, applied through userContent.css and
  # also written to ~/Documents/stylus-backup.json for importing into Stylus
  stylusStyles = [
    {
      name = "github.com";
      urlPrefixes = [ "https://github.com/" ];
    }
    {
      name = "docs.godotengine.org";
      urlPrefixes = [ "https://docs.godotengine.org/" ];
    }
  ];
  styleCode = s: builtins.readFile ../config/firefox/styles/${s.name}.css;
  userContent = lib.concatMapStrings (s: ''
    /* ${s.name} */
    @-moz-document ${lib.concatMapStringsSep ", " (u: ''url-prefix("${u}")'') s.urlPrefixes} {
    ${styleCode s}}

  '') stylusStyles;
  stylusBackup = builtins.toJSON (
    map (s: {
      inherit (s) name;
      enabled = true;
      sections = [
        {
          code = styleCode s;
          inherit (s) urlPrefixes;
        }
      ];
    }) stylusStyles
  );
in
{
  home-manager.users.${config.user.name} =
    { lib, ... }:
    {
      programs.firefox = {
        enable = true;
        nativeMessagingHosts = [ pkgs.keepassxc ]; # for KeePassXC-Browser
        policies = {
          # passwords live in KeePassXC, locked as a policy rather than a pref
          OfferToSaveLogins = false;
          PasswordManagerEnabled = false;
          DisableTelemetry = true;
          DisableFirefoxStudies = true;
          DisableFeedbackCommands = true;
          DisablePocket = true;
          UserMessaging = {
            ExtensionRecommendations = false;
            FeatureRecommendations = false;
            UrlbarInterventions = false;
            SkipOnboarding = true;
            MoreFromMozilla = false;
            Locked = true;
          };

          ExtensionSettings =
            lib.mapAttrs
              (_: slug: {
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi";
                installation_mode = "normal_installed";
              })
              {
                "uBlock0@raymondhill.net" = "ublock-origin";
                "{7a7a4a92-a2a0-41d1-9fd7-1e92480d612d}" = "styl-us";
                "keepassxc-browser@keepassxc.org" = "keepassxc-browser";
                "firefox@tampermonkey.net" = "tampermonkey";
                "{74145f27-f039-47ce-a470-a662b129930a}" = "clearurls";
                "{2766e9f7-7bf2-4c72-81b9-d119eb54c753}" = "remove-youtube-shorts";
                "jid1-SWdspnBEetWxoA@jetpack" = "pinterest-guest";
                "nl-NL@dictionaries.addons.mozilla.org" = "woordenboek-nederlands";
              };
        };

        profiles.default = {
          isDefault = true;
          # force, because Firefox otherwise keeps whatever it decided on first run
          search = {
            default = "ddg";
            privateDefault = "ddg";
            force = true;
            order = [
              "ddg"
              "google"
              "wikipedia"
            ];
          };
          settings = {
            "extensions.autoDisableScopes" = 0; # enable the add-ons above without asking
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true; # load userContent.css
            # restore the previous tabs on start
            "browser.startup.page" = 3;
            # never ask before closing tabs or quitting, the session is restored anyway
            "browser.tabs.warnOnClose" = false;
            "browser.tabs.warnOnCloseOtherTabs" = false;
            "browser.warnOnQuit" = false;
            "browser.sessionstore.warnOnQuit" = false;

            # new tab page: just the search box
            "browser.newtabpage.activity-stream.showSponsored" = false;
            "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
            "browser.newtabpage.activity-stream.showSponsoredCheckboxes" = false;
            "browser.newtabpage.activity-stream.feeds.topsites" = false;
            "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
            "browser.newtabpage.activity-stream.feeds.section.highlights" = false;
            "browser.newtabpage.activity-stream.system.showSponsored" = false;
            "browser.newtabpage.activity-stream.showWeather" = false;
            "browser.newtabpage.activity-stream.discoverystream.enabled" = false;
            "browser.topsites.contile.enabled" = false; # the sponsored tile service

            # address bar: no Firefox Suggest or dropdown widgets
            "browser.urlbar.quicksuggest.enabled" = false;
            "browser.urlbar.suggest.quicksuggest.sponsored" = false;
            "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
            "browser.urlbar.sponsoredTopSites" = false;
            "browser.urlbar.suggest.topsites" = false;
            "browser.urlbar.trending.featureGate" = false;
            "browser.urlbar.suggest.trending" = false;
            "browser.urlbar.addons.featureGate" = false;
            "browser.urlbar.mdn.featureGate" = false;
            "browser.urlbar.weather.featureGate" = false;
            "browser.urlbar.clipboard.featureGate" = false;
            "browser.urlbar.recentsearches.featureGate" = false;

            # no Pocket, VPN or "more from Mozilla" promos
            "extensions.pocket.enabled" = false;
            "browser.vpn_promo.enabled" = false;
            "browser.promo.focus.enabled" = false;

            # passwords live in KeePassXC, the policies above lock this too
            "signon.rememberSignons" = false;
            "signon.autofillForms" = false;
            "signon.generation.enabled" = false;
            "signon.firefoxRelay.feature" = "disabled";
            "signon.management.page.breach-alerts.enabled" = false;
            "browser.contentblocking.report.lockwise.enabled" = false;

            # telemetry, studies and crash reporting
            "datareporting.healthreport.uploadEnabled" = false;
            "datareporting.policy.dataSubmissionEnabled" = false;
            "datareporting.usage.uploadEnabled" = false;
            "toolkit.telemetry.enabled" = false;
            "toolkit.telemetry.unified" = false;
            "toolkit.telemetry.server" = "data:,";
            "toolkit.telemetry.archive.enabled" = false;
            "toolkit.telemetry.newProfilePing.enabled" = false;
            "toolkit.telemetry.firstShutdownPing.enabled" = false;
            "toolkit.telemetry.shutdownPingSender.enabled" = false;
            "toolkit.telemetry.updatePing.enabled" = false;
            "toolkit.telemetry.bhrPing.enabled" = false;
            "toolkit.telemetry.coverage.opt-out" = true;
            "toolkit.coverage.enabled" = false;
            "toolkit.coverage.opt-out" = true;
            "toolkit.crashreporter.include_context" = false;
            "browser.tabs.crashReporting.sendReport" = false;
            "breakpad.reportURL" = "";
            "browser.ping-centre.telemetry" = false;
            "browser.newtabpage.activity-stream.telemetry" = false;
            "browser.newtabpage.activity-stream.feeds.telemetry" = false;
            "app.shield.optoutstudies.enabled" = false;
            "app.normandy.enabled" = false;
            "app.normandy.api_url" = "";
          };

          inherit userContent;
        };
      };

      home = {
        file."Documents/stylus-backup.json".text = stylusBackup;

        # lets KeePassXC-Browser connect without ticking it in the app first
        activation.keepassxcBrowser = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          ini="$HOME/.config/keepassxc/keepassxc.ini"
          mkdir -p "$(dirname "$ini")"
          touch "$ini"
          ${pkgs.crudini}/bin/crudini --set "$ini" Browser Enabled true
        '';
      };
    };
}
