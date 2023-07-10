/*
 * Copyright 2020-2023 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Notifications.Notification : GLib.Object {
    public DesktopAppInfo? app_info { get; construct; }
    public NotificationPriority priority { get; set; default = NORMAL; }

    public string app_id {
        get {
            if (_app_id == null) {
                if (app_info != null && app_info.get_boolean ("X-GNOME-UsesNotifications")) {
                    _app_id = app_info.get_id ();
                    // GLib.DesktopAppInfo.get_id() always include the .desktop suffix.
                    _app_id = _app_id.substring (0, _app_id.last_index_of (".desktop"));
                } else {
                    _app_id = "gala-other";
                }
            }

            return _app_id;
        }
    }

    public string title {
        get {
            // GLib.Notifications only requires the title, when that's the case, we use it as the body.
            // So, use the applications's display name as title if we have one.
            if (_title == null && app_info != null) {
                return app_info.get_display_name ();
            }

            return _title ?? "";
        }

        construct set {
            _title = (value == null || value == "") ? null : fix_markup (value);
        }
    }

    public string body {
        get {
            return _body ?? "";
        }

        construct set {
            _body = (value == null || value == "") ? null : fix_markup (sanitize_body (value));
        }
    }

    public GLib.Icon? primary_icon { get; set; default = null; }
    public GLib.Icon? badge_icon { get; set; default = null; }
    public MaskedImage? image { get; set; default = null; }

    public HashTable<string, Variant> hints { get; construct; }
    public string[] actions { get; construct; }
    public string app_icon { get; construct; }

    private string? _app_id;
    private string? _title;
    private string? _body;

    public Notification (
        string? app_id,
        string app_icon,
        string summary,
        string body,
        string[] actions,
        HashTable<string, Variant> hints
    ) {
        Object (
            app_info: app_id != null ? new DesktopAppInfo (app_id + ".desktop") : null,
            app_icon: app_icon,
            title: summary,
            body: body,
            actions: actions,
            hints: hints
        );
    }

    construct {
        // Always "" if sent by GLib.Notification
        if (app_icon == "" && app_info != null) {
            primary_icon = app_info.get_icon ();
        } else if (app_icon.contains ("/")) {
            var file = File.new_for_uri (app_icon);
            if (file.query_exists ()) {
                primary_icon = new FileIcon (file);
            }
        } else {
            // Icon name set directly, such as by Notify.Notification
            primary_icon = new ThemedIcon (app_icon);
        }

        unowned Variant? variant = null;

        // GLib.Notification.set_icon ()
        if ((variant = hints.lookup ("image-path")) != null || (variant = hints.lookup ("image_path")) != null) {
            var image_path = variant.get_string ();

            // GLib.Notification also sends icon names via this hint
            if (Gtk.IconTheme.get_default ().has_icon (image_path) && image_path != app_icon) {
                badge_icon = new ThemedIcon (image_path);
            } else if (image_path.has_prefix ("/") || image_path.has_prefix ("file://")) {
                try {
                    var pixbuf = new Gdk.Pixbuf.from_file (image_path);
                    image = new Notifications.MaskedImage (pixbuf);
                } catch (Error e) {
                    critical ("Unable to mask image: %s", e.message);
                }
            }
        }

        // Raw image data sent within a variant
        if ((variant = hints.lookup ("image-data")) != null || (variant = hints.lookup ("image_data")) != null || (variant = hints.lookup ("icon_data")) != null) {
            var pixbuf = image_data_variant_to_pixbuf (variant);
            if (pixbuf != null) {
                image = new Notifications.MaskedImage (pixbuf);
            }
        }

        // Display a generic notification icon if there is no notification image
        if (image == null && primary_icon == null) {
            primary_icon = new ThemedIcon ("dialog-information");
        }
    }

    // Copied from gnome-shell, fixes the mess of markup that is sent to us
    private static string fix_markup (string markup) {
        var text = markup;

        try {
            text = /&(?!amp;|quot;|apos;|lt;|gt;|nbsp;|#39)/.replace (markup, markup.length, 0, "&amp;"); //vala-lint=space-before-paren
            text = /<(?!\/?[biu]>)/.replace (text, text.length, 0, "&lt;"); //vala-lint=space-before-paren
        } catch (Error e) {
            warning ("Invalid regex: %s", e.message);
        }

        return text;
    }

    // remove sequences of whitespaces and newlines.
    private static string sanitize_body (string body) {
        var lines = body.delimit ("\f\r\n", '\n')._delimit ("\t\v", ' ').split ("\n");
        foreach (unowned var line in lines) {
            line._strip ();
        }

        var sanitized = string.joinv ("\n", lines);
        while ("  " in sanitized) {
            sanitized = sanitized.replace ("  ", " ");
        }

        while ("\n\n" in sanitized) {
            sanitized = sanitized.replace ("\n\n", "\n");
        }

        return sanitized;
    }

    private Gdk.Pixbuf? image_data_variant_to_pixbuf (Variant img) {
        if (img.get_type_string () != "(iiibiiay)") {
            warning ("Invalid type string: %s", img.get_type_string ());
            return null;
        }
        int width = img.get_child_value (0).get_int32 ();
        int height = img.get_child_value (1).get_int32 ();
        int rowstride = img.get_child_value (2).get_int32 ();
        bool has_alpha = img.get_child_value (3).get_boolean ();
        int bits_per_sample = img.get_child_value (4).get_int32 ();
        unowned uint8[] raw = (uint8[]) img.get_child_value (6).get_data ();

        // Build the pixbuf from the unowned buffer, and copy it to maintain our own instance.
        Gdk.Pixbuf pixbuf = new Gdk.Pixbuf.with_unowned_data (raw, Gdk.Colorspace.RGB,
            has_alpha, bits_per_sample, width, height, rowstride, null);
        return pixbuf.copy ();
    }

}
