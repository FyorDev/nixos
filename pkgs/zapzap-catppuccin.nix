# Catppuccin WhatsApp Web userstyle as plain CSS for ZapZap's custom stylesheet.
# The userstyle is LESS inside a @-moz-document block, ZapZap injects plain CSS.
{
  runCommand,
  fetchurl,
  lessc,
  flavor ? "mocha",
  accent ? "mauve",
}:

let
  userstyle = fetchurl {
    url = "https://raw.githubusercontent.com/catppuccin/userstyles/main/styles/whatsapp-web/catppuccin.user.less";
    hash = "sha256-ZDDp27g+IGhdgO9Ryi8PYaFTyCJoW6QWCIfg+pQm+4M=";
  };
  # the userstyle imports this over the network, which a build cannot do
  stdlib = fetchurl {
    url = "https://userstyles.catppuccin.com/lib/std/v1.less";
    hash = "sha256-XK9Oqan7Kz81DNyE3+ryl5sPi/OpvV+EkgL7WuLoGfM=";
  };
in
runCommand "zapzap-catppuccin-${flavor}-${accent}.css"
  {
    nativeBuildInputs = [ lessc ];
  }
  ''
    cp ${userstyle} style.less
    cp ${stdlib} v1.less
    substituteInPlace style.less \
      --replace-fail 'https://userstyles.catppuccin.com/lib/std/v1.less' 'v1.less'

    lessc \
      --modify-var=lightFlavor=${flavor} \
      --modify-var=darkFlavor=${flavor} \
      --modify-var=accentColor=${accent} \
      --modify-var=lighterMessages=0 \
      style.less compiled.css

    # drop the @-moz-document line and the brace that closed it
    awk 'NR == FNR { last = FNR; next }
         FNR == last && $0 == "}" { next }
         /^@-moz-document/ { next }
         { print }' compiled.css compiled.css > $out

    grep -q 'progress-background-rgb' $out
  ''
