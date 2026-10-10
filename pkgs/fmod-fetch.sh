# shellcheck shell=bash
# usage: fmod-fetch <dir> [--dry-run]
# needs FMOD_USERNAME and FMOD_PASSWORD

base=https://www.fmod.com
# the default curl agent gets a 403
agent="Mozilla/5.0 (X11; Linux x86_64) fmod-fetch"

[ $# -ge 1 ] || {
	echo "usage: fmod-fetch <dir> [--dry-run]" >&2
	exit 2
}
dir=$1
dry_run=false
[ "${2:-}" = --dry-run ] && dry_run=true

: "${FMOD_USERNAME:?FMOD_USERNAME is not set}"
: "${FMOD_PASSWORD:?FMOD_PASSWORD is not set}"
export FMOD_USERNAME FMOD_PASSWORD

# headers go through stdin so the password never shows up in ps
login=$(jq -rn '[(env.FMOD_USERNAME | ascii_downcase | @uri), (env.FMOD_PASSWORD | @uri)] | join(":")' | base64 -w0)
answer=$(curl -fsS -A "$agent" -X POST -K - "$base/api-login" <<<"header = \"Authorization: Basic $login\"") ||
	{
		echo "fmod.com sign-in failed, check FMOD_USERNAME and FMOD_PASSWORD" >&2
		exit 1
	}
token=$(jq -r .token <<<"$answer")
user=$(jq -r .user <<<"$answer")

get() {
	curl -fsS -A "$agent" -K - "$@" <<<"header = \"Authorization: FMOD $token\""
}

pick=$(get "$base/api-downloads" | jq -r '
    .downloads.categories[] | select(.title == "FMOD Studio")
    | .products[].versions[]
    | .version as $v | .platforms[]
    | select((.title | ascii_downcase | contains(".appimage")) and .dl1filename)
    | [$v, .dl1Path, .dl1filename] | @tsv' | sort -t"$(printf '\t')" -k1,1 -V -r | head -n1)
[ -n "$pick" ] || {
	echo "no Linux AppImage for FMOD Studio on fmod.com" >&2
	exit 1
}
IFS=$'\t' read -r version path name <<<"$pick"
url=$(get -G --data-urlencode "path=$path" --data-urlencode "filename=$name" \
	--data-urlencode "user_id=$user" "$base/api-get-download-link" | jq -r .url)
echo "FMOD Studio $version: $name" >&2

if $dry_run; then
	echo "$url"
	exit 0
fi

dest=$dir/$name
if [ -e "$dest" ]; then
	echo "already there: $dest" >&2
	exit 0
fi

mkdir -p "$dir"
tmp=$(mktemp -p "$dir" .fmod-XXXXXX.part)
trap 'rm -f "$tmp"' EXIT

get -L -o "$tmp" "$url"

# a login or error page would otherwise get kept as the AppImage
[[ $(head -c4 "$tmp") == $'\x7f'ELF ]] || {
	echo "download is not an AppImage, the link may have expired" >&2
	exit 1
}
chmod 700 "$tmp"
mv "$tmp" "$dest"
echo "$dest"
