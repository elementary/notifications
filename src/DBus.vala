/*
 * Copyright 2019-2025 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

[DBus (name = "org.freedesktop.Notifications")]
public class Notifications.Server : Object {
    public signal void action_invoked (uint32 id, string action_key);
    public signal void notification_closed (uint32 id, uint32 reason);

    private const string X_CANONICAL_PRIVATE_SYNCHRONOUS = "x-canonical-private-synchronous";

    private uint32 id_counter = 0;

    private unowned DBusConnection connection;
    private Fdo.ActionGroup action_group;

    private Gee.Map<uint32, Bubble?> bubbles;
    private Confirmation? confirmation;

    private uint action_group_id;
    private uint server_id;

    public Server (DBusConnection connection) throws Error {
        bubbles = new Gee.HashMap<uint32, Bubble?> ();
        action_group = new Fdo.ActionGroup (this);

        server_id = connection.register_object ("/org/freedesktop/Notifications", this);
        action_group_id = connection.export_action_group ("/org/freedesktop/Notifications", action_group);
        this.connection = connection;

        action_invoked.connect ((id) => close_bubble (id));
        notification_closed.connect ((id) => close_bubble (id));
    }

    ~Server () {
        connection.unexport_action_group (action_group_id);
        connection.unregister_object (server_id);
    }

    private void close_bubble (uint32 id) {
        Bubble? bubble;

        if (bubbles.unset (id, out bubble)) {
            if (bubble != null) {
                bubble.close ();
            }

            action_group.remove_actions (id);
        }
    }

    public void close_notification (uint32 id) throws DBusError, IOError {
        if (!bubbles.has_key (id)) {
            // according to spec, an empty dbus error should be sent if the notification doesn't exist (anymore)
            throw new DBusError.FAILED ("");
        }

        notification_closed (id, CloseReason.CLOSE_NOTIFICATION_CALL);
    }

    public string [] get_capabilities () throws DBusError, IOError {
        return {
            "action-icons",
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
        spec_version = "1.3";
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
        // Silence "Automatic suspend. Suspending soon because of inactivity." notifications
        // These values and hints are taken from gnome-settings-daemon source code
        // See: https://gitlab.gnome.org/GNOME/gnome-settings-daemon/-/blob/master/plugins/power/gsd-power-manager.c#L356
        // We must check for app_icon == "" to not block low power notifications
        if ("desktop-entry" in hints && hints["desktop-entry"].get_string () == "gnome-power-panel"
        && "urgency" in hints && hints["urgency"].get_byte () == 2
        && app_icon == ""
        && expire_timeout == 0
        ) {
            debug ("Blocked GSD notification");
            throw new DBusError.FAILED ("Notification Blocked");
        }

        var id = (replaces_id != 0 ? replaces_id : ++id_counter);

        if (hints.contains (X_CANONICAL_PRIVATE_SYNCHRONOUS)) {
            send_confirmation (app_icon, hints);
        } else {
            var notification = new Notification (app_name, app_icon, summary, body, hints) {
                buttons = new GenericArray<Notification.Button?> (actions.length / 2)
            };

            if ("action-icons" in hints && hints["action-icons"].is_of_type (VariantType.BOOLEAN)) {
                notification.action_icons = hints["action-icons"].get_boolean ();
            }

            // validate actions
            for (var i = 0; i < actions.length; i += 2) {
                if (actions[i] == "") {
                    continue;
                }

                var action_name = "fdo." + action_group.add_action (id, actions[i]);
                if (actions[i] == "default") {
                    notification.default_action_name = action_name;
                    continue;
                }

                var label = actions[i + 1].strip ();
                if (label == "") {
                    warning ("action '%s' sent without a label, skipping…", actions[i]);
                    continue;
                }

                notification.buttons.add ({ label, action_name });
            }

            if (!Application.settings.get_boolean ("do-not-disturb") || notification.priority == GLib.NotificationPriority.URGENT) {
                var app_settings = new Settings.with_path (
                    "io.elementary.notifications.applications",
                    Application.settings.path.concat ("applications", "/", notification.app_id, "/")
                );

                if (app_settings.get_boolean ("bubbles")) {
                    if (bubbles.has_key (id) && bubbles[id] != null) {
                        bubbles[id].notification = notification;
                    } else {
                        bubbles[id] = new Bubble (notification);
                        bubbles[id].insert_action_group ("fdo", action_group);
                        bubbles[id].close_request.connect (() => {
                            bubbles[id] = null;
                            return Gdk.EVENT_PROPAGATE;
                        });
                        bubbles[id].closed.connect ((res) => {
                            if (res == CloseReason.EXPIRED && app_settings.get_boolean ("remember")) {
                                return;
                            }

                            notification_closed (id, res);
                        });
                    }

                    bubbles[id].present ();
                }

                if (app_settings.get_boolean ("sounds")) {
                    var sound = notification.priority != URGENT ? "dialog-information" : "dialog-warning";
                    if ("category" in hints && hints["category"].is_of_type (VariantType.STRING)) {
                        sound = category_to_sound_name (hints["category"].get_string ());
                    }

                    Application.play_sound (sound);
                }
            }
        }

        return id;
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
            Application.play_sound ("audio-volume-change");
        }

        if (confirmation == null) {
            confirmation = new Notifications.Confirmation (
                icon_name,
                progress_value
            );
            confirmation.close_request.connect (() => {
                confirmation = null;
                return Gdk.EVENT_PROPAGATE;
            });
        } else {
            confirmation.icon_name = icon_name;
            confirmation.progress = progress_value;
        }

        confirmation.present ();
    }

    static unowned string category_to_sound_name (string category) {
        unowned string sound;

        switch (category) {
            case "call":
                sound = "dialog-information";
                break;
            case "call.ended":
                sound = "phone-hangup";
                break;
            case "call.incoming":
                sound = "phone-incoming-call";
                break;
            case "call.unanswered":
                sound = "phone-outgoing-busy";
                break;
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
