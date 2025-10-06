/*
* Copyright 2019-2025 elementary, Inc. (https://elementary.io)
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
    public static Settings settings = new Settings ("io.elementary.notifications");

    public Application () {
        Object (
            application_id: "io.elementary.notifications",
            flags: ApplicationFlags.IS_SERVICE
        );
    }

    protected override bool dbus_register (DBusConnection connection, string object_path) throws Error {
        try {
            new Notifications.Server (connection);
            new Notifications.PortalProxy (connection);
        } catch (Error e) {
            Error.prefix_literal (out e, "Registering notification server failed: ");
            throw e;
        }

        return base.dbus_register (connection, object_path);
    }

    protected override void startup () {
        base.startup ();

        Granite.init ();

        unowned var context = CanberraGtk4.context_get ();
        context.change_props (
            Canberra.PROP_APPLICATION_NAME, "Notifications",
            Canberra.PROP_APPLICATION_ID, application_id,
            null
        );

        context.open ();

        Bus.own_name_on_connection (
            get_dbus_connection (),
            "org.freedesktop.Notifications",
            DO_NOT_QUEUE,
            () => hold (),
            (conn, name) => {
                critical ("Could not acquire bus: %s", name);
                name_lost ();
            }
        );

        Bus.own_name_on_connection (
            get_dbus_connection (),
            "io.elementary.notifications.PortalProxy",
            DO_NOT_QUEUE,
            () => hold (),
            (conn, name) => {
                critical ("Could not acquire bus: %s", name);
                name_lost ();
            }
        );
    }

    public static void play_sound (string sound_name) {
        Canberra.Proplist props;
        Canberra.Proplist.create (out props);

        props.sets (Canberra.PROP_CANBERRA_CACHE_CONTROL, "volatile");
        props.sets (Canberra.PROP_EVENT_ID, sound_name);

        CanberraGtk4.context_get ().play_full (0, props);
    }

    public static void play_sound (string sound_name) {
        Canberra.Proplist props;
        Canberra.Proplist.create (out props);

        props.sets (Canberra.PROP_CANBERRA_CACHE_CONTROL, "volatile");
        props.sets (Canberra.PROP_EVENT_ID, sound_name);

        CanberraGtk4.context_get ().play_full (0, props);
    }

    public static int main (string[] args) {
        var app = new Application ();
        return app.run (args);
    }
}
