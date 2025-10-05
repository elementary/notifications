/*
 * Copyright 2022 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

/* code adapted from libcanberra */

namespace CanberraGtk4 {
    private Canberra.Context? context = null;

    public unowned Canberra.Context? context_get () {
        Canberra.Proplist proplist;

        if (context != null) {
            return context;
        } if (Canberra.Context.create (out context) != Canberra.SUCCESS) {
            return null;
        } if (Canberra.Proplist.create (out proplist) != Canberra.SUCCESS) {
            return null;
        }

        proplist.sets (Canberra.PROP_CANBERRA_XDG_THEME_NAME, Gtk.Settings.get_default ().gtk_sound_theme_name);

        unowned var name = GLib.Environment.get_application_name ();
        if (name != null) {
            proplist.sets (Canberra.PROP_APPLICATION_NAME, name);
        } else {
            proplist.sets (Canberra.PROP_APPLICATION_NAME, "libcanberra-gtk");
            proplist.sets (Canberra.PROP_APPLICATION_VERSION, "%i.%i".printf (Canberra.MAJOR, Canberra.MINOR));
            proplist.sets (Canberra.PROP_APPLICATION_ID, "org.freedesktop.libcanberra.gtk");
        }

        unowned var icon = Gtk.Window.get_default_icon_name ();
        if (icon != null) {
            proplist.sets (Canberra.PROP_APPLICATION_ICON_NAME, icon);
        }

        unowned var display = Gdk.Display.get_default ();
        if (display is Gdk.X11.Display) {
            unowned var display_name = display.get_name ();
            if (display_name != null) {
                proplist.sets (Canberra.PROP_WINDOW_X11_SCREEN, display_name);
            }

            var screen = "%i".printf (((Gdk.X11.Display) display).get_screen ().get_screen_number ());
            proplist.sets (Canberra.PROP_WINDOW_X11_SCREEN, screen);
        }

        context.change_props_full (proplist);

        var val = Value (typeof (string));
        if (display.get_setting ("gtk-sound-theme-name", val)) {
            context.change_props (Canberra.PROP_CANBERRA_XDG_THEME_NAME, val.get_string ());
        }

        val = Value (typeof (bool));
        if (display.get_setting ("gtk-enable-event-sounds", val)) {
            unowned var env = GLib.Environment.get_variable ("CANBERRA_FORCE_EVENT_SOUNDS");
            context.change_props (Canberra.PROP_CANBERRA_ENABLE, env != null ? true : val.get_boolean ());
        }

        display.setting_changed.connect ((setting) => {
            Value new_val;
            if (setting == "gtk-sound-theme-name") {
                new_val = Value (typeof (string));
                display.get_setting ("gtk-sound-theme-name", new_val);
                context.change_props (Canberra.PROP_CANBERRA_ENABLE, new_val.get_string ());
            } else if (setting == "gtk-enable-event-sounds") {
                new_val = Value (typeof (bool));
                unowned var env = GLib.Environment.get_variable ("CANBERRA_FORCE_EVENT_SOUNDS");
                display.get_setting ("gtk-enable-event-sounds", new_val);
                context.change_props (Canberra.PROP_CANBERRA_ENABLE, env != null ? true : new_val.get_boolean ());
            }
        });

        return context;
    }
}
