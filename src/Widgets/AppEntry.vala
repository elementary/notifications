/*
 * Copyright 2011-2020 elementary, Inc. (https://elementary.io)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street - Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

public class Widgets.AppEntry : Gtk.ListBoxRow {
    private const string BUBBLES_KEY = "bubbles";
    private const string SOUNDS_KEY = "sounds";
    private const string REMEMBER_KEY = "remember";

    public Backend.App app { get; construct; }

    public AppEntry (Backend.App app) {
        Object (app: app);
    }

    construct {
        var image = new Gtk.Image.from_gicon (app.app_info.get_icon (), Gtk.IconSize.DND) {
            pixel_size = 32
        };

        var title_label = new Gtk.Label (app.app_info.get_display_name ()) {
            ellipsize = Pango.EllipsizeMode.END,
            xalign = 0,
            valign = Gtk.Align.END
        };
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

        var description_label = new Gtk.Label (get_permissions_string (app)) {
            use_markup = true,
            ellipsize = Pango.EllipsizeMode.END,
            xalign = 0,
            valign = Gtk.Align.START
        };

        var grid = new Gtk.Grid () {
            margin = 6,
            column_spacing = 6
        };
        grid.attach (image, 0, 0, 1, 2);
        grid.attach (title_label, 1, 0, 1, 1);
        grid.attach (description_label, 1, 1, 1, 1);

        this.add (grid);

        app.settings.changed.connect (() => {
            description_label.set_markup (get_permissions_string (app));
        });
    }

    private string get_permissions_string (Backend.App app) {
        string[] items = {};

        if (app.settings.get_boolean (BUBBLES_KEY)) {
            items += _("Bubbles");
        }

        if (app.settings.get_boolean (SOUNDS_KEY)) {
            items += _("Sounds");
        }

        if (app.settings.get_boolean (REMEMBER_KEY)) {
            items += _("Notification Center");
        }

        if (items.length == 0) {
            items += _("Disabled");
        }

        return "<span font_size=\"small\">%s</span>".printf (Markup.escape_text (string.joinv (", ", items)));
    }
}
