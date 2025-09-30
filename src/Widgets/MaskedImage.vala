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

public class Notifications.MaskedImage : Granite.Bin {
    public Gdk.Pixbuf pixbuf { get; construct; }

    private const int ICON_SIZE = 40;

    public MaskedImage (Gdk.Pixbuf pixbuf) {
        Object (pixbuf: pixbuf);
    }

    class construct {
        set_css_name ("masked-image");
    }

    construct {
        var image = new Gtk.Image () {
            paintable = Gdk.Texture.for_pixbuf (pixbuf),
            pixel_size = ICON_SIZE
        };

        add_css_class (Granite.CssClass.CARD);
        add_css_class (Granite.CssClass.CHECKERBOARD);
        overflow = HIDDEN;

        child = image;
    }
}
