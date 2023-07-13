/*
 * Copyright 2019 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 */

public class Notifications.MaskedImage : Gtk.Overlay {
    public LoadableIcon gicon { get; construct; }

    private const int ICON_SIZE = 48;

    public MaskedImage (LoadableIcon gicon) {
        Object (gicon: gicon);
    }

    construct {
        child = new Gtk.Image.from_gicon (mask_icon (gicon, get_style_context ().get_scale ()), DIALOG) {
            pixel_size = ICON_SIZE
        };

        var mask = new Gtk.Image.from_resource ("/io/elementary/notifications/image-mask.svg") {
            pixel_size = ICON_SIZE
        };
        add_overlay (mask);
    }

    private static Icon? mask_icon (LoadableIcon icon, int scale) {
        var mask_offset = 4 * scale;
        var mask_size_offset = mask_offset * 2;
        var size = ICON_SIZE * scale - mask_size_offset;
        Gdk.Pixbuf input;

        if (icon is Gdk.Pixbuf) {
            input = ((Gdk.Pixbuf) icon).scale_simple (size, size, BILINEAR);
        } else try {
            input = new Gdk.Pixbuf.from_stream_at_scale (icon.load (ICON_SIZE, null), size, size, false);
        } catch (Error e) {
            warning ("failed to scale icon: %s", e.message);
            return new ThemedIcon ("image-missing");
        }

        var mask_size = ICON_SIZE * scale;
        var offset_x = mask_offset;
        var offset_y = mask_offset + scale;

        var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, mask_size, mask_size);
        var cr = new Cairo.Context (surface);

        Granite.Drawing.Utilities.cairo_rounded_rectangle (cr, offset_x, offset_y, size, size, mask_offset);
        cr.clip ();

        Gdk.cairo_set_source_pixbuf (cr, input, offset_x, offset_y);
        cr.paint ();

        return Gdk.pixbuf_get_from_surface (surface, 0, 0, mask_size, mask_size);
    }
}
