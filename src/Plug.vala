/*
 * Copyright (c) 2011-2015 elementary Developers
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street - Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

public class NotificationsPlug : Switchboard.Plug {
    public static GLib.Settings notify_settings;

    private static Granite.Widgets.AlertView create_alert_view () {
        var title = _("Nothing to do here");

        var description = _("Notifications preferences are for configuring which apps make use of notifications, for changing how an app's notifications appear,\nand for setting when you do not want to be disturbed by notifications.");
        description += "\n\n";
        description += _("When apps are installed that have notification options they will automatically appear here.");

        var icon_name = "dialog-information";

        return new Granite.Widgets.AlertView (title, description, icon_name);
    }

    private Gtk.Stack stack;

    private Widgets.MainView main_view;
    private Granite.Widgets.AlertView alert_view;

    public NotificationsPlug () {
        var settings = new Gee.TreeMap<string, string?> (null, null);
        settings.set ("notifications", null);
        Object (category: Category.PERSONAL,
                code_name: "io.elementary.switchboard.notifications",
                display_name: _("Notifications"),
                description: _("Configure notification bubbles, sounds, and notification center"),
                icon: "preferences-system-notifications",
                supported_settings: settings);
    }

    static construct {
        if (GLib.SettingsSchemaSource.get_default ().lookup ("io.elementary.notifications", true) != null) {
            debug ("Using io.elementary.notifications server");
            notify_settings = new GLib.Settings ("io.elementary.notifications");
        } else {
            debug ("Using notifications in gala");
            notify_settings = new GLib.Settings ("org.pantheon.desktop.gala.notifications");
        }
    }

    public override Gtk.Widget get_widget () {
        if (stack != null) {
            return stack;
        }

        build_ui ();
        update_view ();

        return stack;
    }

    public override void shown () {
    }

    public override void hidden () {
    }

    public override void search_callback (string location) {
    }

    public override async Gee.TreeMap<string, string> search (string search) {
        var search_results = new Gee.TreeMap<string, string> ((GLib.CompareDataFunc<string>)strcmp, (Gee.EqualDataFunc<string>)str_equal);
        search_results.set ("%s → %s".printf (display_name, _("Do Not Disturb")), "");
        search_results.set ("%s → %s".printf (display_name, _("Notifications Center")), "");
        search_results.set ("%s → %s".printf (display_name, _("Sound")), "");
        search_results.set ("%s → %s".printf (display_name, _("Bubbles")), "");
        return search_results;
    }

    private void build_ui () {
        stack = new Gtk.Stack ();

        main_view = new Widgets.MainView ();
        alert_view = create_alert_view ();

        main_view.show_all ();
        alert_view.show_all ();

        stack.add_named (main_view, "main-view");
        stack.add_named (alert_view, "alert-view");

        stack.show_all ();
    }

    private void update_view () {
        stack.set_visible_child_name (Backend.NotifyManager.get_default ().apps.size > 0 ? "main-view" : "alert-view");
    }
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating Notifications plug");
    var plug = new NotificationsPlug ();

    return plug;
}
