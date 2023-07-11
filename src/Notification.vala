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

    public Icon image {
        get {
            if (_image == null) {
                return app_info != null ? app_info.get_icon () : fallback_icon;
            }

            return _image;
        }

        set {
            _image = value;
        }
    }

    public Icon? badge { get; set; }

    public string[] actions { get; construct; }

    private Icon _image;
    private string _app_id;
    private string _title;
    private string _body;

    // used when no icon was provided
    private static Icon fallback_icon = new ThemedIcon ("dialog-information");

    public Notification (string? app_id, string summary, string body, string[] actions) {
        Object (
            app_info: app_id != null ? new DesktopAppInfo (app_id + ".desktop") : null,
            title: summary,
            body: body,
            actions: actions
        );
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
}
