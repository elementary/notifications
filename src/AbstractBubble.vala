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

public class Notifications.AbstractBubble : Gtk.Window {
    protected Gtk.Grid content_area;
    protected Gtk.HeaderBar headerbar;

    private uint timeout_id;

    construct {
        content_area = new Gtk.Grid ();
        content_area.column_spacing = 6;
        content_area.hexpand = true;
        content_area.margin = 4;
        content_area.margin_top = 6;

        headerbar = new Gtk.HeaderBar ();
        headerbar.custom_title = content_area;

        unowned Gtk.StyleContext headerbar_style_context = headerbar.get_style_context ();
        headerbar_style_context.add_class ("default-decoration");
        headerbar_style_context.add_class (Gtk.STYLE_CLASS_FLAT);

        var spacer = new Gtk.Grid ();
        spacer.height_request = 3;

        unowned Gtk.StyleContext style_context = get_style_context ();
        style_context.add_class ("rounded");
        style_context.add_class ("notification");

        default_width = 300;
        default_height = 0;
        type_hint = Gdk.WindowTypeHint.NOTIFICATION;
        add (spacer);
        set_titlebar (headerbar);

        enter_notify_event.connect (() => {
            stop_timeout ();
            return Gdk.EVENT_PROPAGATE;
        });
    }

    protected void stop_timeout () {
        if (timeout_id != 0) {
            Source.remove (timeout_id);
            timeout_id = 0;
        }
    }

    protected void start_timeout (uint timeout) {
        if (timeout_id != 0) {
            Source.remove (timeout_id);
        }

        timeout_id = GLib.Timeout.add (timeout, () => {
            timeout_id = 0;
            destroy ();
            return false;
        });
    }
}
