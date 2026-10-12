# FL Studio (Windows) under Wine. The first launch downloads the installer from
# Image-Line, prepares the default Wine prefix (~/.wine) and opens the installer
# once (click through it). Unlock it from inside FL Studio with your Image-Line
# account; updates come from FL Studio itself.
#
# The prefix is prepared the way FL Studio wants it: the MS runtimes and fonts
# it links against, the X11 driver instead of Wine's Wayland one, subpixel font
# smoothing, and WineASIO for low latency audio through PipeWire's JACK layer.
{
  lib,
  writeShellApplication,
  writeText,
  makeDesktopItem,
  symlinkJoin,
  runCommand,
  wine,
  wineasio,
  winetricks,
  curl,
  coreutils,
  findutils,
  libnotify,
  labwc,
  xwayland,
  xdotool,
  zig,
  # Run FL inside a nested labwc compositor rather than as a bare Xwayland
  # window. FL leaves black space behind when niri resizes it: it repaints but
  # never re-lays-out, so whatever was added is never painted. niri's own
  # Xwayland notes say X11 apps that position their own windows "will need a
  # nested compositor to run".
  #
  # A Wine virtual desktop (`wine explorer /desktop=`) also fixes the black, but
  # only by being a fixed-size canvas -- measured here at 1600x900, shrinking the
  # niri column clipped the canvas instead of re-laying-out FL. labwc is a real
  # window manager: niri tiles labwc's window, labwc resizes its nested output to
  # match, and FL (maximized inside) gets a genuine X11 resize it does re-lay-out
  # for. So FL tiles like anything else.
  nestedCompositor ? true,
}:

let
  # Always the current release. FL Studio 26.1.4 and later would refuse to start
  # with "The validity of the program could not be verified", which the patched
  # `wine` passed in here fixes -- see pkgs/patches and packages.nix.
  installerUrl = "https://support.image-line.com/redirect/flstudio_win_installer";

  # Wine derives the name of a builtin's unix library from the PE stub's
  # internal name, which here is "wineasio.dll" -- but nixpkgs ships the pair as
  # wineasio64.dll / wineasio64.dll.so, so Wine looks for "wineasio.dll.so",
  # doesn't find it, and registration fails with "cannot find builtin library".
  # This is just the unix half under the name Wine asks for.
  wineasioUnix = runCommand "wineasio-unix-dlldir" { } ''
    mkdir -p $out
    ln -s ${wineasio}/lib/wine/x86_64-unix/wineasio64.dll.so $out/wineasio.dll.so
  '';

  # winetricks packages to install into the prefix, then its settings verbs
  # tahoma because FL's UI asks for that font by name and corefonts lacks it.
  verbs = [
    "corefonts"
    "tahoma"
    "gdiplus"
    "vcrun2022"
    "vcrun6sp6"
    "dxvk"
  ];
  settings = [
    "fontsmooth=rgb"
    "renderer=vulkan"
  ];

  # labwc's whole job here is to be invisible: no titlebars, no gaps, and FL's
  # main window maximized to fill the nested output. That output is labwc's own
  # window in niri, so "maximized" tracks whatever size niri hands labwc -- which
  # is the point of the exercise.
  #
  # The maximize has to be scoped by title, not just by identifier. FL Studio
  # puts up 41 top-level X11 windows and every one of them has WM_CLASS
  # "fl64.exe": the main window, its dialogs, and about thirty 1x1 helpers.
  # Maximizing all of them stretched the "Welcome to FL Studio" dialog across the
  # output, and that dialog is exactly the kind of window that repaints without
  # re-laying-out -- so it went black, which looked like the original bug but was
  # this rule causing it. Only the main window, "FL Studio <year>", should grow.
  labwcConfig = runCommand "fl-studio-labwc-config" { } ''
    mkdir -p $out
    cp ${writeText "rc.xml" ''
      <?xml version="1.0"?>
      <labwc_config>
        <core>
          <decoration>none</decoration>
          <gap>0</gap>
        </core>
        <windowRules>
          <windowRule identifier="*" serverDecoration="no" skipTaskbar="yes"/>
          <windowRule identifier="fl64.exe" title="FL Studio *">
            <action name="Maximize"/>
          </windowRule>
        </windowRules>
      </labwc_config>
    ''} $out/rc.xml
  '';

  # A Windows binary, because the call that fixes this is a Win32 one and there
  # is no way to reach it from the X side -- see pkgs/fl-redraw.c. zig rather
  # than pkgsCross.mingwW64 only because zig is in the binary cache and the
  # mingw cross toolchain is not; it bundles the mingw headers either way.
  redrawExe = runCommand "fl-redraw.exe" { nativeBuildInputs = [ zig ]; } ''
    mkdir -p "$out"
    export HOME="$TMPDIR" XDG_CACHE_HOME="$TMPDIR/zig"
    zig cc -target x86_64-windows-gnu -O2 \
      -o "$out/fl-redraw.exe" ${./fl-redraw.c} -luser32
  '';

  # See the top of fl-repaint.sh for what this is working around.
  repaint = writeShellApplication {
    name = "fl-repaint";
    runtimeInputs = [
      xdotool
      wine
    ];
    text = ''
      FL_REDRAW_EXE="${redrawExe}/fl-redraw.exe"
      export FL_REDRAW_EXE
    ''
    + builtins.readFile ./fl-repaint.sh;
  };

  # Runs inside the nested compositor, so DISPLAY points at labwc's Xwayland and
  # the WINE* exports below are inherited from the launcher. `wine` returns as
  # soon as it has handed off, so the wait is what actually tracks FL's life --
  # and labwc's --session takes this script exiting as the cue to shut down.
  nestedRunner = writeShellApplication {
    name = "fl-studio-nested";
    runtimeInputs = [
      wine
      repaint
    ];
    text = ''
      # Runs alongside FL in the same nested session, so DISPLAY already points
      # at labwc's Xwayland. It ends itself once that display goes away: the
      # assumption that --session would reap it was wrong, and a stray watcher
      # was found still polling well after FL had quit.
      fl-repaint &

      wine "$@" || true
      wineserver --wait || true
    '';
  };

  launcher = writeShellApplication {
    name = "fl-studio";
    runtimeInputs = [
      wine
      winetricks
      curl
      coreutils
      findutils
      libnotify
    ]
    ++ lib.optionals nestedCompositor [
      labwc
      xwayland
    ];
    text = ''
      # The default prefix, ~/.wine, on request. Note this means the winetricks
      # verbs below, DXVK and the X11/Vulkan settings apply to every Windows app
      # you run under Wine, not just FL Studio.
      export WINEPREFIX="''${WINEPREFIX:-$HOME/.wine}"
      export WINEDEBUG=-all
      # WineASIO ships as a PE/unix pair, this is where Wine finds both halves
      export WINEDLLPATH="${wineasioUnix}''${WINEDLLPATH:+:$WINEDLLPATH}"
      # No winemenubuilder, so Wine stops scattering .desktop files into
      # ~/.local. d2d1 and dwrite stay on Wine's builtins: FL's installer drops
      # its own copies into system32 and forcing those changed nothing either
      # way, so the simpler setting wins.
      export WINEDLLOVERRIDES="d2d1,dwrite=n,b;winemenubuilder.exe=d"

      find_fl() {
          find "$WINEPREFIX/drive_c/Program Files/Image-Line" -maxdepth 2 -name FL64.exe 2>/dev/null | sort | tail -n1
      }

      # Marks a prefix as provisioned. Without this the setup below was gated on
      # FL Studio not being installed yet, so an existing prefix never got the
      # runtimes, DXVK, WineASIO or the registry settings at all.
      prepared="$WINEPREFIX/.nix-prefix-ready"

      # Everything in here runs once, on a fresh prefix.
      prepare_prefix() {
          notify-send "FL Studio" "Preparing the Wine prefix, this takes a while..." || true
          winetricks -q -f ${lib.concatStringsSep " " verbs}
          winetricks -q ${lib.concatStringsSep " " settings}

          # Wine's Wayland driver can't do what FL Studio's UI needs yet
          wine reg add 'HKCU\Software\Wine\Drivers' /v Graphics /d x11 /f

          # ALSA rather than Wine's PulseAudio backend. With winepulse, FL's main
          # thread blocked forever inside mmdevapi enumerating audio devices --
          # a backtrace showed ntdll <- kernelbase <- mmdevapi <- winmm x4 <-
          # flengine_x64 -- so the splash sat there and the main window was never
          # created. PipeWire serves ALSA clients too, so nothing is lost.
          wine reg add 'HKCU\Software\Wine\Drivers' /v Audio /d alsa /f

          # WineASIO. The PE stub goes in the prefix under the name its own
          # internals use; the unix half is on WINEDLLPATH above under the
          # matching name. Both have to be "wineasio.dll" or the builtin loader
          # can't pair them up.
          install -Dm644 ${wineasio}/lib/wine/x86_64-windows/wineasio64.dll \
              "$WINEPREFIX/drive_c/windows/system32/wineasio.dll"
          wine regsvr32 wineasio.dll || \
              echo "wineasio: registration failed, FL Studio can still use its own FL Studio ASIO" >&2

          wineserver --wait
      }

      # Provision the prefix once, whether or not FL Studio is already in it
      if [ ! -e "$prepared" ]; then
          # A wineserver outliving a deleted prefix can answer for the new one
          # (the socket is named after the directory's inode), so wineboot
          # skips creating dosdevices. Without a z: drive wine can't map unix
          # paths and the installer segfaults in init_startup_info.
          mkdir -p "$WINEPREFIX"
          wineserver -k 2>/dev/null || true
          wineboot --init
          wineserver --wait
          if [ ! -L "$WINEPREFIX/dosdevices/c:" ] || [ ! -e "$WINEPREFIX/dosdevices/z:" ]; then
              echo "broken Wine prefix at $WINEPREFIX (no c: symlink or z: drive), delete it and retry" >&2
              exit 1
          fi
          prepare_prefix
          touch "$prepared"
      fi

      if [ -z "$(find_fl)" ]; then
          installer="''${XDG_CACHE_HOME:-$HOME/.cache}/fl-studio-installer.exe"
          notify-send "FL Studio" "Downloading the installer (about 1 GB)..." || true
          if [ ! -s "$installer" ]; then
              curl -fL --retry 3 -o "$installer.part" "${installerUrl}"
              mv "$installer.part" "$installer"
          fi
          wine "$installer"
          wineserver --wait
          rm -f "$installer"
          [ -n "$(find_fl)" ] || { echo "FL Studio installer did not finish" >&2; exit 1; }
      fi

      ${
        if nestedCompositor then
          ''
            # A nested compositor, see nestedCompositor at the top of this file.
            # labwc takes its startup command as one string, hence the requoting.
            start="$(printf '%q ' ${nestedRunner}/bin/fl-studio-nested "$(find_fl)" "$@")"

            # Keeping labwc's frame loop alive. Nested in niri it uses wlroots'
            # Wayland backend, whose swapchain is four buffers deep; when niri holds
            # all four, wlr_swapchain_acquire fails with "No free output buffer
            # slot", labwc aborts the commit, and because the backend only re-arms
            # wl_surface_frame on a *successful* commit the frame loop stops dead.
            # labwc 0.9.7 doesn't reschedule after a failed commit, so nothing
            # restarts it until new damage arrives -- moving the mouse over the
            # window. Meanwhile Xwayland, given no frame callbacks, drops its
            # present timer to 1Hz. That is the "FL is blank until I hover it".
            #
            # Both of these keep buffers moving: no hardware cursor (cursor motion
            # is what exhausts the slots on this backend) and no direct scanout, so
            # labwc composites its own frame instead of handing FL's buffer to niri
            # and waiting to get it back. See also ALWAYS_OPAQUE in
            # config/niri/window-opacity.py -- an opacity rule on this window would
            # put it on niri's 1s offscreen timer and undo all of it.
            export WLR_NO_HARDWARE_CURSORS=1
            export WLR_SCENE_DISABLE_DIRECT_SCANOUT=1
            # Takes DXVK off the FIFO/flip path, where it blocks waiting on exactly
            # the frame callbacks above, and lets it present as soon as it has a
            # frame ready.
            export MESA_VK_WSI_PRESENT_MODE=immediate

            # --session, not --startup: labwc exits when that command exits, so
            # closing FL closes the compositor with it. This used to be a `kill`
            # from inside the runner, which is how it once managed to SIGTERM
            # `systemd --user` and log the whole session out. Letting labwc own its
            # own lifetime deletes that entire class of mistake.
            exec labwc -C ${labwcConfig} -S "$start"
          ''
        else
          ''
            exec wine "$(find_fl)" "$@"
          ''
      }
    '';
  };

  desktopItem = makeDesktopItem {
    name = "fl-studio";
    desktopName = "FL Studio";
    exec = "fl-studio %f";
    icon = "fl-studio";
    categories = [
      "AudioVideo"
      "Audio"
    ];
    mimeTypes = [ "application/x-flp" ];
  };
in
symlinkJoin {
  name = "fl-studio";
  paths = [
    launcher
    desktopItem
  ];

  meta = {
    description = "FL Studio digital audio workstation, running under Wine";
    homepage = "https://www.image-line.com/fl-studio";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "fl-studio";
  };
}
