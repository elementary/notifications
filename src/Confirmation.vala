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
    public string confirmation_type { get; construct set; }
    public new string icon_name { get; construct set; }
    public double progress { get; construct set; }

    private Gtk.Image image;
    private Gtk.ProgressBar progressbar;

    public Confirmation (string confirmation_type, string icon_name, double progress) {
        Object (
            confirmation_type: confirmation_type,
            icon_name: icon_name,
            progress: progress,
            timeout: 2000
        );
    }

    construct {
        var contents = create_contents ();
        content_area.add (contents);

        get_style_context ().add_class ("confirmation");
    }

    public void replace (string confirmation_type, string icon_name, double progress) {
        if (this.confirmation_type == confirmation_type) {
            image.icon_name = icon_name;
            progressbar.fraction = progress;
            return;
        }

        this.confirmation_type = confirmation_type;
        this.icon_name = icon_name;
        this.progress = progress;

        var contents = create_contents ();
        content_area.add (contents);
        content_area.visible_child = contents;
    }

    private Gtk.Widget create_contents () {
        image = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.DIALOG) {
            valign = Gtk.Align.START,
            pixel_size = 48
        };

        progressbar = new Gtk.ProgressBar () {
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

        return contents;
    }
}
