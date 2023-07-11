/*
 * Copyright 2019-2023 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

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
    private Notifications.Confirmation? confirmation = null;

    private GLib.Settings settings;

    private Gee.HashMap<uint32, Notifications.Bubble> bubbles;

    private static VariantType variant_type_pixbuf = new VariantType ("(iiibiiay)");

    construct {
        settings = new GLib.Settings ("io.elementary.notifications");
        bubbles = new Gee.HashMap<uint32, Notifications.Bubble> ();
    }

    public void close_notification (uint32 id) throws DBusError, IOError {
        if (bubbles.has_key (id)) {
            bubbles[id].close ();
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

    public void get_server_information (
        out string name,
        out string vendor,
        out string version,
        out string spec_version
    ) throws DBusError, IOError {

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
        NotificationPriority urgency = NORMAL;
        string? app_id = null;

        if ("desktop-entry" in hints && hints["desktop-entry"].is_of_type (VariantType.STRING)) {
            app_id = hints["desktop-entry"].get_string ();
        }

        if ("urgency" in hints && hints["urgency"].is_of_type (VariantType.BYTE)) {
            urgency = priority_from_urgency (hints["urgency"].get_byte ());
        }

        // Silence "Automatic suspend. Suspending soon because of inactivity." notifications
        // These values and hints are taken from gnome-settings-daemon source code
        // See: https://gitlab.gnome.org/GNOME/gnome-settings-daemon/-/blob/master/plugins/power/gsd-power-manager.c#L356
        // We must check for app_icon == "" to not block low power notifications
        if (app_id == "gnome-power-panel" && urgency == URGENT && app_icon == "" && expire_timeout == 0) {
            debug ("Blocked GSD notification");
            throw new DBusError.FAILED ("Notification Blocked");
        }

        var id = replaces_id;

        if (hints.contains (X_CANONICAL_PRIVATE_SYNCHRONOUS)) {
            send_confirmation (app_icon, hints);
        } else {
            // Only summary is required, so try to set a title when body is empty
            if (body._strip () == "") {
                body = summary._strip ();
                summary = app_name._strip ();
            } else if (summary._strip () == "") {
                summary = app_name._strip ();
            }

            if (body == "" || summary == "" && app_id == null) {
                throw new DBusError.INVALID_ARGS ("summary must not be empty");
            }

            var notification = new Notification (app_id, summary, body, actions) {
                image = parse_image_string (app_icon),
                priority = urgency
            };

            if (id == 0) {
                id = ++id_counter;
            }

            var image = search_image (hints);
            if (image != null) {
                if (image is LoadableIcon) {
                    notification.badge = notification.image;
                    notification.image = image;
                } else {
                    notification.badge = image;
                }
            }

            if (!settings.get_boolean ("do-not-disturb") || notification.priority == URGENT) {
                var app_settings = new Settings.with_path (
                    "io.elementary.notifications.applications",
                    settings.path.concat ("applications", "/", notification.app_id, "/")
                );

                if (app_settings.get_boolean ("bubbles")) {
                    if (bubbles.has_key (id) && bubbles[id] != null) {
                        bubbles[id].notification = notification;
                    } else {
                        bubbles[id] = new Bubble (notification);

                        bubbles[id].action_invoked.connect ((action_key) => {
                            action_invoked (id, action_key);
                        });

                        bubbles[id].closed.connect ((reason) => {
                            closed_callback (id, reason);
                        });
                    }

                    bubbles[id].present ();
                }

                if (app_settings.get_boolean ("sounds")) {
                    var sound = notification.priority != URGENT ? "dialog-information" : "dialog-warning";
                    if ("category" in hints && hints["category"].is_of_type (VariantType.STRING)) {
                        sound = category_to_sound_name (hints["category"].get_string ());
                    }

                    send_sound (sound);
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
            send_sound ("audio-volume-change");
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

        confirmation.present ();
    }

    private void send_sound (string sound_name) {
        if (sound_name == "") {
            return;
        }

        Canberra.Proplist props;
        Canberra.Proplist.create (out props);

        props.sets (Canberra.PROP_CANBERRA_CACHE_CONTROL, "volatile");
        props.sets (Canberra.PROP_EVENT_ID, sound_name);

        CanberraGtk.context_get ().play_full (0, props);
    }

    // convert between freedesktop urgency levels and GLib.NotificationPriority levels
    // See: https://specifications.freedesktop.org/notification-spec/notification-spec-latest.html#urgency-levels
    private static NotificationPriority priority_from_urgency (uint8 urgency) {
        switch (urgency) {
            case 0: return LOW;
            case 1: return NORMAL;
            case 2: return URGENT;
            default:
                warning ("unknown urgency value: %u, ignoring", urgency);
                return NORMAL;
        }
    }

    // search for a image hint, in priority order.
    // See: https://specifications.freedesktop.org/notification-spec/notification-spec-latest.html#icons-and-images
    private static Icon? search_image (HashTable<string, Variant> hints) {
        const string[] IMAGE_HINTS = { "image-data", "image_data", "image-path", "image_path", "icon_data" };
        Icon? image = null;

        foreach (unowned var hint in IMAGE_HINTS) {
            if (!hints.contains (hint)) {
                continue;
            }

            if (hints[hint].is_of_type (VariantType.STRING)) {
                image = parse_image_string (hints[hint].get_string ());
            } else if (hints[hint].is_of_type (variant_type_pixbuf)) {
                image = parse_image_pixbuf (hints[hint]);
            }

            if (image != null) {
                break;
            }

            warning ("wrong type for hint '%s': %s. ignoring", hint, hints[hint].get_type_string ());
        }

        return image;
    }

    private static Gdk.Pixbuf? parse_image_pixbuf (Variant variant)
    requires (variant.is_of_type (variant_type_pixbuf)) {
        int width, height, rowstride, bps;
        bool has_alpha;
        Bytes data;

        variant.get ("(iiibiiay)", out width, out height, out rowstride, out has_alpha, out bps, null, null);
        data = variant.get_child_value (6).get_data_as_bytes ();

        return new Gdk.Pixbuf.from_bytes (data, RGB, has_alpha, bps, width, height, rowstride);
    }

    private static Icon? parse_image_string (string image) {
        if (Gtk.IconTheme.get_default ().has_icon (image)) {
            return new ThemedIcon (image);
        }

        File? file = null;

        if (image.has_prefix ("file:")) {
            file = File.new_for_uri (image);
        } else if (image.has_prefix ("/")) {
            file = File.new_for_path (image);
        }

        if (file != null && file.query_exists ()) {
            return new FileIcon (file);
        }

        return null;
    }

    private static unowned string category_to_sound_name (string category) {
        unowned string sound;

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
                sound = "";
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
