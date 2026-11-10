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

public class Notifications.Confirmation : AbstractBubble {
    public new string icon_name { get; construct set; }
    public double progress { get; construct set; }

    public Confirmation (string icon_name, double progress) {
        Object (
            icon_name: icon_name,
            progress: progress,
            timeout: 2000
        );
    }

    construct {
        var image = new Gtk.Image.from_icon_name (icon_name);

        var symbol = new Notifications.Symbol ("/io/elementary/notifications/icons/audio-volume.svg");

        var stack = new Gtk.Stack ();
        stack.add_named (symbol, "symbol");
        stack.add_named (image, "image");

        var progressbar = new Gtk.ProgressBar () {
            hexpand = true,
            valign = CENTER,
            margin_end = 6,
            width_request = 258
        };
        progressbar.add_css_class (Granite.STYLE_CLASS_FLAT);

        var contents = new Gtk.Box (HORIZONTAL, 6);
        contents.append (stack);
        contents.append (progressbar);

        content_area.add_child (contents);

        add_css_class ("confirmation");

        bind_property ("progress", progressbar, "fraction", SYNC_CREATE);
        bind_property ("icon-name", image, "icon-name");
        bind_property ("icon-name", symbol, "state", SYNC_CREATE, icon_to_state);
        bind_property ("icon-name", stack, "visible-child-name", SYNC_CREATE, icon_to_child_name);
    }

    private bool icon_to_child_name (Binding binding, Value from_value, ref Value to_value) {
        var icon_name = (string) from_value;

        if (icon_name.has_prefix ("audio-volume")) {
            to_value.set_string ("symbol");
            return true;
        }

        to_value.set_string ("image");
        return true;
    }

    private bool icon_to_state (Binding binding, Value from_value, ref Value to_value) {
        var icon_name = (string) from_value;
        switch (icon_name) {
            case "audio-volume-high-symbolic":
                to_value.set_string ("high");
                return true;
            case "audio-volume-low-symbolic":
                to_value.set_string ("low");
                return true;
            case "audio-volume-medium-symbolic":
                to_value.set_string (Notifications.SymbolState.NORMAL);
                return true;
            case "audio-volume-muted-blocking-symbolic":
                to_value.set_string ("disabled-blocking");
                return true;
            case "audio-volume-muted-symbolic":
                to_value.set_string (Notifications.SymbolState.DISABLED);
                return true;
            default:
                return false;
        }
    }
}
