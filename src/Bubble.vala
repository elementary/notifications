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

public class Notifications.Bubble : AbstractBubble {
    public signal void action_invoked (string action_key);

    public string[] actions { get; construct; }
    public string app_icon { get; construct; }
    public string body { get; construct; }
    public string? image_path { get; construct; }
    public new string title { get; construct; }
    public uint32 id { get; construct; }
    public GLib.DesktopAppInfo? app_info { get; construct; }
    public GLib.NotificationPriority priority { get; construct; }

    public Bubble (
        GLib.DesktopAppInfo? app_info,
        string app_icon,
        string title,
        string body,
        string[] actions,
        GLib.NotificationPriority priority,
        string? image_path,
        uint32 id
    ) {
        Object (
            app_info: app_info,
            title: title,
            body: body,
            actions: actions,
            app_icon: app_icon,
            priority: priority,
            image_path: image_path,
            id: id
        );
    }

    construct {
        var contents = new Contents (app_info, title, app_icon, body, image_path);

        content_area.add (contents);

        switch (priority) {
            case GLib.NotificationPriority.HIGH:
            case GLib.NotificationPriority.URGENT:
                content_area.get_style_context ().add_class ("urgent");
                break;
            default:
                start_timeout (4000);
                break;
        }

        if (app_info != null) {
            bool default_action = false;

            for (int i = 0; i < actions.length; i += 2) {
                if (actions[i] == "default") {
                    default_action = true;
                    break;
                }
            }

            button_press_event.connect ((event) => {
                if (default_action) {
                    launch_action ("default");
                } else {
                    try {
                        app_info.launch (null, null);
                        dismiss ();
                    } catch (Error e) {
                        critical ("Unable to launch app: %s", e.message);
                    }
                }
                return Gdk.EVENT_STOP;
            });
        }

        leave_notify_event.connect (() => {
            if (priority == GLib.NotificationPriority.HIGH || priority == GLib.NotificationPriority.URGENT) {
                return Gdk.EVENT_PROPAGATE;
            }
            start_timeout (4000);
        });
    }

    private void launch_action (string action_key) {
        app_info.launch_action (action_key, new GLib.AppLaunchContext ());
        action_invoked (action_key);
        dismiss ();
    }

    public void replace (string new_summary, string new_body) {
        start_timeout (4000);

        var new_contents = new Contents (app_info, new_summary, app_icon, new_body, image_path);
        new_contents.show_all ();

        content_area.add (new_contents);
        content_area.visible_child = new_contents;
    }

    private class Contents : Gtk.Grid {
        public GLib.DesktopAppInfo? app_info { get; construct; }
        public new string title { get; construct; }
        public string app_icon { get; construct; }
        public string body { get; construct; }
        public string? image_path { get; construct; }

        public Contents (GLib.DesktopAppInfo? app_info, string title, string app_icon, string body, string? image_path) {
            Object (
                app_icon: app_icon,
                app_info: app_info,
                body: body,
                image_path: image_path,
                title: title
            );
        }

        construct {
            if (app_icon == "") {
                if (app_info != null) {
                    app_icon = app_info.get_icon ().to_string ();
                } else {
                    app_icon = "dialog-information";
                }
            }

            var app_image = new Gtk.Image ();
            app_image.icon_name = app_icon;

            var image_overlay = new Gtk.Overlay ();
            image_overlay.valign = Gtk.Align.START;

            if (image_path != null) {
                try {
                    var scale = get_style_context ().get_scale ();
                    var pixbuf = new Gdk.Pixbuf.from_file_at_size (image_path, 48 * scale, 48 * scale);

                    var masked_image = new Notifications.MaskedImage (pixbuf);

                    app_image.pixel_size = 24;
                    app_image.halign = app_image.valign = Gtk.Align.END;

                    image_overlay.add (masked_image);
                    image_overlay.add_overlay (app_image);
                } catch (Error e) {
                    critical ("Unable to mask image: %s", e.message);

                    app_image.pixel_size = 48;
                    image_overlay.add (app_image);
                }
            } else {
                app_image.pixel_size = 48;
                image_overlay.add (app_image);
            }

            var title_label = new Gtk.Label (title);
            title_label.ellipsize = Pango.EllipsizeMode.END;
            title_label.valign = Gtk.Align.END;
            title_label.xalign = 0;
            title_label.get_style_context ().add_class ("title");

            var body_label = new Gtk.Label (body);
            body_label.ellipsize = Pango.EllipsizeMode.END;
            body_label.lines = 2;
            body_label.use_markup = true;
            body_label.valign = Gtk.Align.START;
            body_label.wrap = true;
            body_label.xalign = 0;

            if ("\n" in body) {
                string[] lines = body.split ("\n");
                string stripped_body = lines[0] + "\n";
                for (int i = 1; i < lines.length; i++) {
                    stripped_body += lines[i].strip () + "";
                }

                body_label.label = stripped_body.strip ();
                body_label.lines = 1;
            }

            column_spacing = 6;
            attach (image_overlay, 0, 0, 1, 2);
            attach (title_label, 1, 0);
            attach (body_label, 1, 1);
        }
    }
}
