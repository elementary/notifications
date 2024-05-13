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
        var image = new Gtk.Image.from_icon_name (icon_name) {
            valign = Gtk.Align.START,
            pixel_size = 48
        };

        var progressbar = new Gtk.ProgressBar () {
            hexpand = true,
            valign = Gtk.Align.CENTER,
            margin_end = 6,
            width_request = 258
        };
        progressbar.add_css_class (Granite.STYLE_CLASS_FLAT);

        var contents = new Gtk.Box (HORIZONTAL, 6);
        contents.append (image);
        contents.append (progressbar);

        content_area.add_child (contents);

        add_css_class("confirmation");

        bind_property ("icon-name", image, "icon-name");
        bind_property ("progress", progressbar, "fraction");
    }
}
