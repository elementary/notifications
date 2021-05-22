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

public class Notifications.ImageData : GLib.Object {
    public int width { get; construct; }
    public int height { get; construct; }
    public int rowstride { get; construct; }
    public bool has_alpha { get; construct; }
    public int bits_per_sample { get; construct; }
    public int n_channels { get; construct; }
    public void* raw { get; set; }

    public ImageData (int width, int height, int rowstride, bool has_alpha, int bits_per_sample, int n_channels, void* raw) {
        Object (
            width: width, 
            height: height, 
            rowstride: rowstride, 
            has_alpha: has_alpha, 
            bits_per_sample: bits_per_sample, 
            n_channels: n_channels, 
            raw: raw
        );
    }

    /**
     * Decode a raw image (iiibiiay) sent through 'hints'
     */
    public static ImageData from_variant(Variant img)
    {
        // Read the image fields
        int v_width           = img.get_child_value(0).get_int32();
        int v_height          = img.get_child_value(1).get_int32();
        int v_rowstride       = img.get_child_value(2).get_int32();
        bool v_has_alpha      = img.get_child_value(3).get_boolean();
        int v_bits_per_sample = img.get_child_value(4).get_int32();
        int v_n_channels      = img.get_child_value(5).get_int32();
        void* v_raw = img.get_child_value (6).get_data();

        return new ImageData(v_width, v_height, v_rowstride, v_has_alpha, v_bits_per_sample, v_n_channels, v_raw);
    }

    public Gdk.Pixbuf to_pixbuf_at_size(int w, int h) {
        unowned uint8[] data = (uint8[]) raw;
        var pixbuf = new Gdk.Pixbuf.with_unowned_data (data, Gdk.Colorspace.RGB,
            has_alpha, bits_per_sample, width, height, rowstride, null);
        var scaled_pixbuf = pixbuf.scale_simple(w, h,  Gdk.InterpType.BILINEAR);
        return scaled_pixbuf;
    }
}
