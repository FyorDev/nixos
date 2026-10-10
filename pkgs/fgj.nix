{
  lib,
  buildGoModule,
  fetchFromGitea,
}:

buildGoModule rec {
  pname = "fgj";
  version = "0.5.0";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "romaintb";
    repo = "fgj";
    rev = "v${version}";
    hash = "sha256-YNR8Efdw4Le85/fJCgWEesq3KVWmIHO/wOvzL8uj8NQ=";
  };

  vendorHash = "sha256-ZBdSSif9YFpFyBQNpZ/XttVw/dgDS54L+0ZA+9ObSSg=";

  doCheck = false;

  meta = {
    description = "gh-style command line client for Forgejo and Codeberg";
    homepage = "https://codeberg.org/romaintb/fgj";
    license = lib.licenses.mit;
    mainProgram = "fgj";
  };
}
