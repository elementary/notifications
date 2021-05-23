/*
* Copyright 2020 elementary, Inc. (https://elementary.io)
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

public class Notifications.Notification : GLib.Object {
    private const string OTHER_APP_ID = "gala-other";

    public GLib.DesktopAppInfo? app_info { get; private set; default = null; }
    public GLib.NotificationPriority priority { get; private set; default = GLib.NotificationPriority.NORMAL; }
    public HashTable<string, Variant> hints { get; construct; }
    public string[] actions { get; construct; }
    public string app_icon { get; construct; }
    public string app_id { get; private set; default = OTHER_APP_ID; }
    public string app_name { get; construct; }
    public string body { get; construct set; }
    public string? image_path { get; private set; default = null; }
    public Gdk.Pixbuf? pixbuf { get; private set; default = null; }
    public string summary { get; construct set; }

    private static Regex entity_regex;
    private static Regex tag_regex;

    public Notification (string app_name, string app_icon, string summary, string body, string[] actions, HashTable<string, Variant> hints) {
        Object (
            app_name: app_name,
            app_icon: app_icon,
            summary: summary,
            body: body,
            actions: actions,
            hints: hints
        );
    }

    static construct {
        try {
            entity_regex = new Regex ("&(?!amp;|quot;|apos;|lt;|gt;)");
            tag_regex = new Regex ("<(?!\\/?[biu]>)");
        } catch (Error e) {
            warning ("Invalid regex: %s", e.message);
        }
    }

    construct {
        /*Only summary is required by GLib, so try to set a title when body is empty*/
        if (body == "") {
            body = fix_markup (summary);
            summary = app_name;
        } else {
            body = fix_markup (body);
            summary = fix_markup (summary);
        }

        unowned Variant? variant = null;

        if ((variant = hints.lookup ("image-data")) != null) {
            pixbuf = read_image_data (variant);
        }

        if ((variant = hints.lookup ("urgency")) != null && variant.is_of_type (VariantType.BYTE)) {
            priority = (GLib.NotificationPriority) variant.get_byte ();
        }

        if ((variant = hints.lookup ("desktop-entry")) != null && variant.is_of_type (VariantType.STRING)) {
            app_id = variant.get_string ();
            app_id.replace (".desktop", "");

            app_info = new DesktopAppInfo ("%s.desktop".printf (app_id));
            if (app_info == null) {
                app_info = new DesktopAppInfo.from_filename ("/etc/xdg/autostart/%s.desktop".printf (app_id));
            }
        }

        if ((variant = hints.lookup ("image-path")) != null || (variant = hints.lookup ("image_path")) != null) {
            image_path = variant.get_string ();

            if (!image_path.has_prefix ("/") && !image_path.has_prefix ("file://")) {
                image_path = null;
            }
        }

        if (app_icon == "") {
            if (app_info != null) {
                app_icon = app_info.get_icon ().to_string ();
            } else {
                app_icon = "dialog-information";
            }
        }
    }

    /**
     * Copied from gnome-shell, fixes the mess of markup that is sent to us
     */
    private string fix_markup (string markup) {
        var text = markup;

        try {
            text = entity_regex.replace (markup, markup.length, 0, "&amp;");
            text = tag_regex.replace (text, text.length, 0, "&lt;");
        } catch (Error e) {
            warning ("Invalid regex: %s", e.message);
        }

        return text;
    }

    private Gdk.Pixbuf? read_image_data (Variant img) {
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
