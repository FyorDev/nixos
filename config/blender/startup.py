"""
Enable add-ons and the Catppuccin theme at start-up.
"""

import os

import bpy

# addon module names to switch on
ADDONS = ["blender_mcp"]
THEME = os.path.normpath(
    os.path.join(
        os.path.dirname(__file__),
        "..",
        "presets",
        "interface_theme",
        "Catppuccin_Mocha_Mauve.xml",
    )
)


def apply():
    prefs = bpy.context.preferences
    for addon in ADDONS:
        if addon in prefs.addons:
            continue
        try:
            bpy.ops.preferences.addon_enable(module=addon)
        except Exception as e:  # modules may get renamed
            print("startup: could not enable %s: %s" % (addon, e))
    if os.path.exists(THEME):
        try:
            bpy.ops.script.execute_preset(
                filepath=THEME,
                menu_idname="USERPREF_MT_interface_theme_presets",
            )
        except Exception as e:
            print("startup: could not apply the theme: %s" % e)

    return None


def register():
    if not bpy.app.background:
        bpy.app.timers.register(apply, first_interval=0.1)


def unregister():
    if bpy.app.timers.is_registered(apply):
        bpy.app.timers.unregister(apply)
