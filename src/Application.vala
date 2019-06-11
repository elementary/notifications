/*
* Copyright 2019 elementary, Inc. (https://elementary.io)
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
    public Application () {
        Object (
            application_id: "io.elementary.notifications",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {
        var css_provider = new Gtk.CssProvider ();
        css_provider.load_from_resource ("/io/elementary/notifications/application.css");
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        var server = new Notifications.Server ();

        Bus.own_name (BusType.SESSION, "org.freedesktop.Notifications", BusNameOwnerFlags.NONE, (connection) => {
            try {
                connection.register_object ("/org/freedesktop/Notifications", server);
            } catch (Error e) {
                warning ("Registring notification server failed: %s", e.message);
                quit ();
            }
        },
        () => {},
        (con, name) => {
            warning ("Could not aquire bus %s", name);
            quit ();
        });

        hold ();
    }

    public static int main (string[] args) {
        var app = new Application ();
        return app.run (args);
    }
}
