"""
Enable add-ons at start-up.
"""

import bpy

# addon module names to switch on
ADDONS = ["blender_mcp"]


def apply():
    prefs = bpy.context.preferences
    for addon in ADDONS:
        if addon in prefs.addons:
            continue
        try:
            bpy.ops.preferences.addon_enable(module=addon)
        except Exception as e:  # modules may get renamed
            print("startup: could not enable %s: %s" % (addon, e))
    return None


def register():
    if not bpy.app.background:
        bpy.app.timers.register(apply, first_interval=0.1)


def unregister():
    if bpy.app.timers.is_registered(apply):
        bpy.app.timers.unregister(apply)
