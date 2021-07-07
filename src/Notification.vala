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
    public string summary { get; construct set; }

    public GLib.Icon? primary_icon { get; set; default = null; }
    public GLib.Icon? badge_icon { get; set; default = null; }
    public MaskedImage? image { get; set; default = null; }

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
        unowned Variant? variant = null;

        // GLib.Notification.set_priority ()
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

        // Always "" if sent by GLib.Notification
        if (app_icon == "" && app_info != null) {
            primary_icon = app_info.get_icon ();
        } else if (app_icon.contains ("/")) {
            var file = File.new_for_uri (app_icon);
            if (file.query_exists ()) {
                primary_icon = new FileIcon (file);
            }
        }

        if (primary_icon == null) {
            primary_icon = new ThemedIcon ("dialog-information");
        }

        // GLib.Notification.set_icon ()
        if ((variant = hints.lookup ("image-path")) != null || (variant = hints.lookup ("image_path")) != null) {
            var image_path = variant.get_string ();

            // GLib.Notification also sends icon names via this hint
            if (Gtk.IconTheme.get_default ().has_icon (image_path) && image_path != app_icon) {
                badge_icon = new ThemedIcon (image_path);
            } else if (image_path.has_prefix ("/") || image_path.has_prefix ("file://")) {
                var scale = ((Gtk.Application) GLib.Application.get_default ()).get_active_window ().get_style_context ().get_scale ();

                try {
                    var pixbuf = new Gdk.Pixbuf.from_file_at_size (image_path, 48 * scale, 48 * scale);
                    image = new Notifications.MaskedImage (pixbuf);
                } catch (Error e) {
                    critical ("Unable to mask image: %s", e.message);
                }
            }
        }

        // Always "" if sent by GLib.Notification
        if (app_name == "" && app_info != null) {
            app_name = app_info.get_display_name ();
        }

        /*Only summary is required by GLib.Notification, so try to set a title when body is empty*/
        if (body == "") {
            body = fix_markup (summary);
            summary = app_name;
        } else {
            body = fix_markup (body);
            summary = fix_markup (summary);
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
}
