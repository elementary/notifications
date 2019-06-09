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
    unowned Canberra.Context? ca_context = null;

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

        send_test_notification ();

        hold ();
    }

    private void send_test_notification () {
        var notification = new Notifications.Notification (
            "Notification Title",
            "Notification body that contains a description that could be long and need wrapping or truncating"
        );
        notification.gicon = new ThemedIcon ("application-default-icon");
        notification.show_all ();

        Canberra.Proplist props;
        Canberra.Proplist.create (out props);

        props.sets (Canberra.PROP_CANBERRA_CACHE_CONTROL, "volatile");
        props.sets (Canberra.PROP_EVENT_ID, "dialog-information");

        ca_context = CanberraGtk.context_get ();
        ca_context.change_props (
            Canberra.PROP_APPLICATION_NAME, "Notifications",
            Canberra.PROP_APPLICATION_ID, "io.elementary.notifications",
            null
        );
        ca_context.open ();
        ca_context.play_full (0, props);

        GLib.Timeout.add (2000, () => {
            send_test_notification ();
            return false;
        });
    }

    public static int main (string[] args) {
        var app = new Application ();
        return app.run (args);
    }
}
