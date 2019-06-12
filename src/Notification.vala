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

public class Notifications.Notification : Gtk.Window {
    public string app_icon { get; construct; }
    public string body { get; construct; }
    public new string title { get; construct; }
    public GLib.NotificationPriority priority { get; set; default = GLib.NotificationPriority.NORMAL; }

    private Gtk.Grid action_area;
    private Gtk.SizeGroup size_group;
    private uint timeout_id;

    public Notification (string app_icon, string title, string body) {
        Object (
            title: title,
            body: body,
            app_icon: app_icon
        );
    }

    construct {
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
        body_label.valign = Gtk.Align.START;
        body_label.wrap = true;
        body_label.xalign = 0;

        action_area = new Gtk.Grid ();
        action_area.orientation = Gtk.Orientation.VERTICAL;
        action_area.margin_start = 2;
        action_area.row_spacing = 4;

        size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);

        var grid = new Gtk.Grid ();
        grid.column_spacing = 6;
        grid.hexpand = true;
        grid.margin = 4;
        grid.margin_top = 6;
        grid.margin_end = 2;
        grid.attach (image, 0, 0, 1, 2);
        grid.attach (title_label, 1, 0);
        grid.attach (body_label, 1, 1);
        grid.attach (action_area, 2, 0, 1, 2);

        var style_context = get_style_context ();
        style_context.add_class ("rounded");
        style_context.add_class ("notification");

        var headerbar = new Gtk.HeaderBar ();
        headerbar.custom_title = grid;

        var headerbar_style_context = headerbar.get_style_context ();
        headerbar_style_context.add_class ("default-decoration");
        headerbar_style_context.add_class (Gtk.STYLE_CLASS_FLAT);

        set_titlebar (headerbar);

        var spacer = new Gtk.Grid ();
        spacer.height_request = 3;

        default_width = 300;
        default_height = 0;
        type_hint = Gdk.WindowTypeHint.NOTIFICATION;
        add (spacer);

        timeout_id = GLib.Timeout.add (2500, () => {
            timeout_id = 0;
            destroy ();
            return false;
        });

        notify["priority"].connect (() => {
            if (priority == GLib.NotificationPriority.URGENT) {
                get_style_context ().add_class ("urgent");
                if (timeout_id != 0) {
                    Source.remove (timeout_id);
                    timeout_id = 0;
                }
            }
        });
    }

    public void add_action (string label, string action) {
        var button = new Gtk.Button.with_label (label);
        button.vexpand = true;

        action_area.add (button);
        size_group.add_widget (button);
    }
}

