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
    private string _confirmation_type;
    public string confirmation_type {
        get {
            return _confirmation_type;
        }
        set {
            if (value == _confirmation_type) {
                return;
            }

            _confirmation_type = value;

            if (icon_name_binding != null) {
                icon_name_binding.unbind ();
            }
            if (progress_binding != null) {
                progress_binding.unbind ();
            }

            var contents = create_contents ();
            content_area.add (contents);
            content_area.visible_child = contents;
        }
    }

    public new string icon_name { get; construct set; }
    public double progress { get; construct set; }

    private Binding? icon_name_binding;
    private Binding? progress_binding;

    public Confirmation (string confirmation_type, string icon_name, double progress) {
        Object (
            confirmation_type: confirmation_type,
            icon_name: icon_name,
            progress: progress,
            timeout: 2000
        );
    }

    construct {
        get_style_context ().add_class ("confirmation");
    }

    private Gtk.Widget create_contents () {
        var image = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.DIALOG) {
            valign = Gtk.Align.START,
            pixel_size = 48
        };

        var progressbar = new Gtk.ProgressBar () {
            hexpand = true,
            valign = Gtk.Align.CENTER,
            margin_end = 6,
            width_request = 258,
            fraction = progress
        };
        progressbar.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var contents = new Gtk.Grid () {
            column_spacing = 6
        };
        contents.attach (image, 0, 0);
        contents.attach (progressbar, 1, 0);
        contents.show_all ();

        icon_name_binding = bind_property ("icon-name", image, "icon-name");
        progress_binding = bind_property ("progress", progressbar, "fraction");

        return contents;
    }
}
