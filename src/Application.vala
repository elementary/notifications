/*
* Copyright 2019-2022 elementary, Inc. (https://elementary.io)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
*/

public class Notifications.Application : Gtk.Application {
    private static Granite.Settings granite_settings;
    private static Gtk.Settings gtk_settings;

    public Application () {
        Object (
            application_id: "io.elementary.notifications",
            flags: ApplicationFlags.IS_SERVICE
        );
    }

    protected override bool dbus_register (DBusConnection connection, string object_path) throws Error {
        var server = new Notifications.Server ();

        try {
            connection.register_object ("/org/freedesktop/Notifications", server);
        } catch (Error e) {
            warning ("Registring notification server failed: %s", e.message);
            throw e;
        }

        Bus.own_name_on_connection (
            connection, "org.freedesktop.Notifications", BusNameOwnerFlags.DO_NOT_QUEUE,
            () => hold (),
            (conn, name) => {
                critical ("Could not aquire bus: %s", name);
                name_lost ();
            }
        );

        return base.dbus_register (connection, object_path);
    }

    protected override void startup () {
        base.startup ();

        granite_settings = Granite.Settings.get_default ();
        gtk_settings = Gtk.Settings.get_default ();
        gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        });

        var css_provider = new Gtk.CssProvider ();
        css_provider.load_from_resource (resource_base_path + "/application.css");
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        unowned var context = CanberraGtk.context_get ();
        context.change_props (
            Canberra.PROP_APPLICATION_NAME, "Notifications",
            Canberra.PROP_APPLICATION_ID, application_id,
            null
        );

        context.open ();
    }

    public static int main (string[] args) {
        var app = new Application ();
        return app.run (args);
    }
}
