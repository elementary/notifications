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

public class Widgets.SettingsOption : Gtk.Grid {
    public string image_path { get; construct; }
    public string title { get; construct; }
    public string description { get; construct; }
    public Gtk.Widget widget { get; construct; }

    private static Gtk.CssProvider css_provider;

    private Gtk.Image image;
    private Gtk.Settings gtk_settings;

    public SettingsOption (string image_path, string title, string description, Gtk.Widget widget) {
        Object (
            image_path: image_path,
            title: title,
            description: description,
            widget: widget
        );
    }

    static construct {
        css_provider = new Gtk.CssProvider ();
        css_provider.load_from_resource ("/io/elementary/switchboard/SettingsOption.css");
    }

    construct {
        image = new Gtk.Image.from_resource (image_path);

        var card = new Gtk.Grid () {
            valign = Gtk.Align.START
        };
        card.add (image);

        unowned Gtk.StyleContext card_context = card.get_style_context ();
        card_context.add_class (Granite.STYLE_CLASS_CARD);
        card_context.add_class (Granite.STYLE_CLASS_ROUNDED);
        card_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        var title_label = new Gtk.Label (title) {
            halign = Gtk.Align.START,
            valign = Gtk.Align.END,
            hexpand = true,
            vexpand = false
        };
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

        widget.halign = Gtk.Align.START;
        widget.valign = Gtk.Align.CENTER;
        widget.hexpand = false;
        widget.vexpand = false;

        var description_label = new Gtk.Label (description) {
            xalign = 0,
            valign = Gtk.Align.START,
            hexpand = true,
            vexpand = false,
            wrap = true,
            justify = Gtk.Justification.LEFT
        };

        column_spacing = 12;
        row_spacing = 6;
        margin_start = 60;
        margin_end = 30;
        attach (card, 0, 0, 1, 3);
        attach (title_label, 1, 0);
        attach (widget, 1, 1);
        attach (description_label, 1, 2);

        gtk_settings = Gtk.Settings.get_default ();
        gtk_settings.notify["gtk-application-prefer-dark-theme"].connect (() => {
            update_image_resource ();
        });

        update_image_resource ();
    }

    private void update_image_resource () {
        if (gtk_settings.gtk_application_prefer_dark_theme) {
            image.resource = image_path.replace (".svg", "-dark.svg");
        } else {
            image.resource = image_path;
        }
    }
}
