// Copyright


// TEST CALL FOR DSPY:
// 'io.elementary.mail.desktop'
// 'new-mail'
// {'title': <'New mail from John Doe'>, 'body': <'You have a new mail from John Doe. Click to read it.'>, 'priority': <'high'>}

[DBus (name = "io.elementary.notifications.PortalProxy")]
public class Notifications.PortalProxy : Object {
    private const string ID_FORMAT = "%s:%s";

    public signal void action_invoked (string app_id, string id, string action_name, Variant[] parameters);

    public HashTable<string, Variant> supported_options { get; construct; }
    public uint version { get; default = 2; }

    [DBus (visible = false)]
    public DBusConnection connection { private get; construct; }

    private uint server_id;
    private Gee.Map<string, Bubble?> bubbles;

    public PortalProxy (DBusConnection connection) {
        Object (connection: connection);
    }

    ~PortalProxy () {
        connection.unregister_object (server_id);
    }

    construct {
        try {
            server_id = connection.register_object ("/io/elementary/notifications/PortalProxy", this);
        } catch (Error e) {
            critical (e.message);
        }

        supported_options = new HashTable<string, Variant> (str_hash, str_equal);
        bubbles = new Gee.HashMap<string, Bubble?> ();
    }

    public void add_notification (string app_id, string id, HashTable<string, Variant> data) throws Error {
        if (!("title" in data)) {
            throw new DBusError.FAILED ("Can't show notification without title");
        }

        unowned var title = data["title"].get_string ();

        unowned string body = "";
        if ("body-markup" in data) {
            body = data["body-markup"].get_string ();
        } else if ("body" in data) {
            body = data["body"].get_string ();
        }

        var app_icon = app_id;
        var hints = new HashTable<string, Variant> (str_hash, str_equal);

        var notification = new Notification (app_id, app_icon, title, body, hints) {
            buttons = new GenericArray<Notification.Button?> (0)
        };

        if (!Application.settings.get_boolean ("do-not-disturb") || notification.priority == GLib.NotificationPriority.URGENT) {
            var app_settings = new Settings.with_path (
                "io.elementary.notifications.applications",
                Application.settings.path.concat ("applications", "/", notification.app_id, "/")
            );

            if (app_settings.get_boolean ("bubbles")) {
                var full_id = ID_FORMAT.printf (app_id, id);

                if (bubbles.has_key (full_id) && bubbles[full_id] != null) {
                    bubbles[full_id].notification = notification;
                } else {
                    bubbles[full_id] = new Bubble (notification);
                    bubbles[full_id].close_request.connect (() => {
                        bubbles[full_id] = null;
                        return Gdk.EVENT_PROPAGATE;
                    });
                }

                bubbles[full_id].present ();
            }

            if (app_settings.get_boolean ("sounds")) {
                var sound = notification.priority != URGENT ? "dialog-information" : "dialog-warning";

                send_sound (sound);
            }
        }
    }

    public void remove_notification (string app_id, string id) throws Error {
        var full_id = ID_FORMAT.printf (app_id, id);

        if (!bubbles.has_key (full_id)) {
            throw new DBusError.FAILED ("Provided id %s not found", id);
        }

        bubbles[full_id].close ();
    }

    private void send_sound (string sound_name) {
        if (sound_name == "") {
            return;
        }

        Canberra.Proplist props;
        Canberra.Proplist.create (out props);

        props.sets (Canberra.PROP_CANBERRA_CACHE_CONTROL, "volatile");
        props.sets (Canberra.PROP_EVENT_ID, sound_name);

        CanberraGtk4.context_get ().play_full (0, props);
    }
}
