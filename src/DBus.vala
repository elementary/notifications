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

[DBus (name = "org.freedesktop.DBus")]
private interface Notifications.DBus : Object {
    [DBus (name = "GetConnectionUnixProcessID")]
    public abstract uint32 get_connection_unix_process_id (string name) throws Error;
}

[DBus (name = "org.freedesktop.Notifications")]
public class Notifications.Server : Object {
    private unowned Canberra.Context? ca_context = null;
    private DBus? bus_proxy = null;

    construct {
        try {
            bus_proxy = Bus.get_proxy_sync (BusType.SESSION, "org.freedesktop.DBus", "/");
        } catch (Error e) {
            critical (e.message);
            bus_proxy = null;
        }

        ca_context = CanberraGtk.context_get ();
        ca_context.change_props (
            Canberra.PROP_APPLICATION_NAME, "Notifications",
            Canberra.PROP_APPLICATION_ID, "io.elementary.notifications",
            null
        );
        ca_context.open ();
    }

    public string [] get_capabilities () throws DBusError, IOError {
        return {
            "body",
            "body-markup"
        };
    }

    public void get_server_information (out string name, out string vendor, out string version, out string spec_version) throws DBusError, IOError {
        name = "io.elementary.notifications";
        vendor = "elementaryOS";
        version = "0.1";
        spec_version = "1.2";
    }

    public new uint32 notify (
        string app_name,
        uint32 replaces_id,
        string app_icon,
        string summary,
        string body,
        string[] actions,
        HashTable<string,
        Variant> hints,
        int32 expire_timeout,
        BusName sender
    ) throws DBusError, IOError {
        if (app_icon == "") {
            app_icon = "dialog-information";
        }

        var notification = new Notifications.Notification (
            app_icon,
            summary,
            body
        );
        notification.show_all ();

        send_sound (hints);

        return 0;
    }

    private void send_sound (HashTable<string,Variant> hints) {
        Variant? variant = null;

        variant = hints.lookup ("category");
        unowned string? sound_name = "dialog-information";

        if (variant != null) {
            sound_name = category_to_sound_name (variant.get_string ());
        }

        if (sound_name != null) {
            Canberra.Proplist props;
            Canberra.Proplist.create (out props);

            props.sets (Canberra.PROP_CANBERRA_CACHE_CONTROL, "volatile");
            props.sets (Canberra.PROP_EVENT_ID, sound_name);

            ca_context.play_full (0, props);
        }
    }

    static unowned string? category_to_sound_name (string category) {
        unowned string? sound = null;
        switch (category) {
            case "device.added":
                sound = "device-added";
                break;
            case "device.removed":
                sound = "device-removed";
                break;
            case "im":
                sound = "message";
                break;
            case "im.received":
                sound = "message-new-instant";
                break;
            case "network.connected":
                sound = "network-connectivity-established";
                break;
            case "network.disconnected":
                sound = "network-connectivity-lost";
                break;
            case "presence.online":
                sound = "service-login";
                break;
            case "presence.offline":
                sound = "service-logout";
                break;
            // no sound at all
            case "x-gnome.music":
                sound = null;
                break;
            // generic errors
            case "device.error":
            case "email.bounced":
            case "im.error":
            case "network.error":
            case "transfer.error":
                sound = "dialog-error";
                break;
            // use generic default
            case "network":
            case "email":
            case "email.arrived":
            case "presence":
            case "transfer":
            case "transfer.complete":
            default:
                sound = "dialog-information";
                break;
        }

        return sound;
    }
}
