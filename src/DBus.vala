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
    public enum CloseReason {
        EXPIRED = 1,
        DISMISSED = 2,
        CLOSE_NOTIFICATION_CALL = 3,
        UNDEFINED = 4
    }

    public signal void action_invoked (uint32 id, string action_key);
    public signal void notification_closed (uint32 id, uint32 reason);

    private const string X_CANONICAL_PRIVATE_SYNCHRONOUS = "x-canonical-private-synchronous";

    private uint32 id_counter = 0;
    private unowned Canberra.Context? ca_context = null;
    private DBus? bus_proxy = null;
    private Notifications.Confirmation? confirmation = null;

    private GLib.Settings settings;

    private Gee.HashMap<uint32, Notifications.Bubble> bubbles;

    construct {
        try {
            bus_proxy = Bus.get_proxy_sync (BusType.SESSION, "org.freedesktop.DBus", "/");
        } catch (Error e) {
            critical (e.message);
            bus_proxy = null;
        }

        ca_context = CanberraGtk4.context_get ();
        ca_context.change_props (
            Canberra.PROP_APPLICATION_NAME, "Notifications",
            Canberra.PROP_APPLICATION_ID, "io.elementary.notifications",
            null
        );
        ca_context.open ();

        settings = new GLib.Settings ("io.elementary.notifications");

        bubbles = new Gee.HashMap<uint32, Notifications.Bubble> ();
    }

    public void close_notification (uint32 id) throws DBusError, IOError {
        if (bubbles.has_key (id)) {
            bubbles[id].dismiss ();
            closed_callback (id, CloseReason.CLOSE_NOTIFICATION_CALL);
            return;
        }

        // according to spec, an empty dbus error should be sent if the notification
        // doesn't exist (anymore)
        throw new DBusError.FAILED ("");
    }

    public string [] get_capabilities () throws DBusError, IOError {
        return {
            "actions",
            "body",
            "body-markup",
            X_CANONICAL_PRIVATE_SYNCHRONOUS
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
        HashTable<string, Variant> hints,
        int32 expire_timeout,
        BusName sender
    ) throws DBusError, IOError {
        var id = (replaces_id != 0 ? replaces_id : ++id_counter);

        if (hints.contains (X_CANONICAL_PRIVATE_SYNCHRONOUS)) {
            send_confirmation (app_icon, hints);
        } else {
            var notification = new Notifications.Notification (app_name, app_icon, summary, body, actions, hints);

            if (!settings.get_boolean ("do-not-disturb") || notification.priority == GLib.NotificationPriority.URGENT) {
                var app_settings = new GLib.Settings.full (
                    SettingsSchemaSource.get_default ().lookup ("io.elementary.notifications.applications", true),
                    null,
                    "/io/elementary/notifications/applications/%s/".printf (notification.app_id)
                );

                if (app_settings.get_boolean ("bubbles")) {
                    if (bubbles.has_key (id) && bubbles[id] != null) {
                        bubbles[id].replace (notification);
                    } else {
                        bubbles[id] = new Notifications.Bubble (notification, id);
                        bubbles[id].show_all ();

                        bubbles[id].action_invoked.connect ((action_key) => {
                            action_invoked (id, action_key);
                        });

                        bubbles[id].closed.connect ((reason) => {
                            closed_callback (id, reason);
                        });
                    }
                }
                if (app_settings.get_boolean ("sounds")) {
                    switch (notification.priority) {
                        case GLib.NotificationPriority.HIGH:
                        case GLib.NotificationPriority.URGENT:
                            send_sound (hints, "dialog-warning");
                            break;
                        default:
                            send_sound (hints);
                            break;
                    }
                }
            }
        }

        return id;
    }

    private void closed_callback (uint32 id, uint32 reason) {
        bubbles.unset (id);
        notification_closed (id, reason);
    }

    private void send_confirmation (string icon_name, HashTable<string, Variant> hints) {
        double progress_value;
        Variant? val = hints.lookup ("value");
        if (val != null) {
            progress_value = val.get_int32 ().clamp (0, 100) / 100.0;
        } else {
            progress_value = -1;
        }

        // the sound indicator is an exception here, it won't emit a sound at all, even though for
        // consistency it should. So we make it emit the default one.
        var confirmation_type = hints.lookup (X_CANONICAL_PRIVATE_SYNCHRONOUS).get_string ();
        if (confirmation_type == "indicator-sound") {
            send_sound (hints, "audio-volume-change");
        }

        if (confirmation == null) {
            confirmation = new Notifications.Confirmation (
                icon_name,
                progress_value
            );
            confirmation.destroy.connect (() => {
                confirmation = null;
            });
        } else {
            confirmation.icon_name = icon_name;
            confirmation.progress = progress_value;
        }

        confirmation.show_all ();
    }

    private void send_sound (HashTable<string,Variant> hints, string sound_name = "dialog-information") {
        if (sound_name == "dialog-information") {
            Variant? variant = hints.lookup ("category");
            if (variant != null) {
                sound_name = category_to_sound_name (variant.get_string ());
            }
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
