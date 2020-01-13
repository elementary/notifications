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
    public new string title { get; construct; }
    public uint32 id { get; construct; }
    public GLib.DesktopAppInfo? app_info { get; construct; }
    public GLib.NotificationPriority priority { get; construct; }

    private uint timeout_id;

    public Bubble (
        GLib.DesktopAppInfo? app_info,
        string app_icon,
        string title,
        string body,
        string[] actions,
        GLib.NotificationPriority priority,
        uint32 id
    ) {
        Object (
            app_info: app_info,
            title: title,
            body: body,
            actions: actions,
            app_icon: app_icon,
            priority: priority,
            id: id
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

        var image = new Gtk.Image.from_icon_name (app_icon, Gtk.IconSize.DIALOG);
        image.valign = Gtk.Align.START;
        image.pixel_size = 48;

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

        var grid = new Gtk.Grid ();
        grid.column_spacing = 6;
        grid.hexpand = true;
        grid.margin = 4;
        grid.margin_top = 6;
        grid.attach (image, 0, 0, 1, 2);
        grid.attach (title_label, 1, 0);
        grid.attach (body_label, 1, 1);

        headerbar.custom_title = grid;

        switch (priority) {
            case GLib.NotificationPriority.HIGH:
            case GLib.NotificationPriority.URGENT:
                get_style_context ().add_class ("urgent");
                break;
            default:
                self_destruct ();
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
                        destroy ();
                    } catch (Error e) {
                        critical ("Unable to launch app: %s", e.message);
                    }
                }
                return Gdk.EVENT_STOP;
            });
        }

        enter_notify_event.connect (() => {
            if (timeout_id != 0) {
                Source.remove (timeout_id);
                timeout_id = 0;
            }
        });

        leave_notify_event.connect (() => {
            if (priority == GLib.NotificationPriority.HIGH || priority == GLib.NotificationPriority.URGENT) {
                return Gdk.EVENT_PROPAGATE;
            }
            self_destruct ();
        });
    }

    private void self_destruct () {
        if (timeout_id != 0) {
            Source.remove (timeout_id);
        }

        timeout_id = GLib.Timeout.add (4000, () => {
            timeout_id = 0;
            destroy ();
            return false;
        });
    }

    private void launch_action (string action_key) {
        app_info.launch_action (action_key, new GLib.AppLaunchContext ());
        action_invoked (action_key);
        destroy ();
    }
}
