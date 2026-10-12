# shellcheck shell=bash
# Watches the nested output for a size change and asks FL Studio to repaint.
# See pkgs/fl-redraw.c for why a repaint is needed and what else was ruled out.
#
# Polling rather than watching for RandR events: the size only changes when a
# column is resized, twice a second is plenty, and it keeps this to xdotool
# with no X library bindings to carry.
prev=""
misses=0

while :; do
	if ! geometry="$(xdotool getdisplaygeometry 2>/dev/null)"; then
		# labwc is gone. Exit rather than poll a dead display forever: an
		# earlier version of this script assumed the session would reap it and
		# was found still running, on its own, long after FL had quit.
		misses=$((misses + 1))
		[ "$misses" -ge 5 ] && exit 0
		sleep 0.4
		continue
	fi
	misses=0

	if [ -n "$prev" ] && [ "$geometry" != "$prev" ]; then
		# niri reports several sizes while a column settles, so wait for it to
		# stop moving rather than poking FL once per intermediate size.
		while :; do
			sleep 0.3
			settled="$(xdotool getdisplaygeometry 2>/dev/null || true)"
			[ "$settled" = "$geometry" ] && break
			geometry="$settled"
		done
		wine "$FL_REDRAW_EXE" >/dev/null 2>&1 || true
	fi

	prev="$geometry"
	sleep 0.4
done
