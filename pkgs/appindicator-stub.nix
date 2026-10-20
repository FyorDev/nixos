# Stands in for libayatana-appindicator so an app that links it starts but never shows a
# tray icon. Spotify only calls these three functions.
{
  runCommandCC,
  pkg-config,
  glib,
}:
runCommandCC "appindicator-stub"
  {
    nativeBuildInputs = [ pkg-config ];
    buildInputs = [ glib ];
  }
  ''
    cat > stub.c <<'EOF'
    #include <glib-object.h>
    gpointer app_indicator_new_with_path(const char *id, const char *icon, int category, const char *path)
    {
      return g_object_new(G_TYPE_OBJECT, NULL);
    }
    void app_indicator_set_menu(gpointer self, gpointer menu) {}
    void app_indicator_set_status(gpointer self, int status) {}
    EOF
    mkdir -p $out/lib
    $CC -shared -fPIC stub.c -o $out/lib/libayatana-appindicator3.so.1 \
      -Wl,-soname,libayatana-appindicator3.so.1 $(pkg-config --cflags --libs gobject-2.0)
  ''
