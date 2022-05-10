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

public class Notifications.MaskedImage : Gtk.Overlay {
    private const int ICON_SIZE = 48;

    public Gdk.Pixbuf pixbuf { get; construct; }

    public MaskedImage (Gdk.Pixbuf pixbuf) {
        Object (pixbuf: pixbuf);
    }

    construct {
        var mask = new Gtk.Image.from_resource ("/io/elementary/notifications/image-mask.svg");
        mask.pixel_size = ICON_SIZE;

        var scale = get_style_context ().get_scale ();

        var image = new Gtk.Image ();
        image.gicon = mask_pixbuf (pixbuf, scale);
        image.pixel_size = ICON_SIZE;

        add (image);
        add_overlay (mask);
    }
}
