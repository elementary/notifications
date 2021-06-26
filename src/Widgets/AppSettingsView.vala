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

public class Widgets.AppSettingsView : Gtk.Grid {
    private Gtk.Image app_image;
    private Gtk.Label app_label;

    private SettingsOption bubbles_option;
    private SettingsOption sound_option;
    private SettingsOption remember_option;

    construct {
        app_image = new Gtk.Image () {
            pixel_size = 48
        };

        app_label = new Gtk.Label (null) {
            use_markup = true,
            halign = Gtk.Align.START,
            hexpand = true
        };
        app_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        var header = new Gtk.Grid () {
            column_spacing = 12
        };
        header.attach (app_image, 0, 0);
        header.attach (app_label, 1, 0);

        bubbles_option = new SettingsOption (
            "/io/elementary/switchboard/bubbles.svg",
            _("Bubbles"),
            _("Bubbles appear in the top right corner of the display and disappear automatically."),
            new Gtk.Switch ()
        );

        sound_option = new SettingsOption (
            "/io/elementary/switchboard/sounds.svg",
            _("Sounds"),
            _("Sounds play once when a new notification arrives."),
            new Gtk.Switch ()
        );

        remember_option = new SettingsOption (
            "/io/elementary/switchboard/notify-center.svg",
            _("Notification Center"),
            _("Show missed notifications in Notification Center."),
            new Gtk.Switch ()
        );

        margin = 12;
        row_spacing = 32;
        attach (header, 0, 0);
        attach (bubbles_option, 0, 1);
        attach (sound_option, 0, 2);
        attach (remember_option, 0, 3);

        update_selected_app ();

        Backend.NotifyManager.get_default ().notify["selected-app-id"].connect (() => {
            remove_bindings ();
            update_selected_app ();
        });
    }

    private void remove_bindings () {
        Settings.unbind (bubbles_option.widget, "state");
        Settings.unbind (sound_option.widget, "state");
        Settings.unbind (remember_option.widget, "state");
    }

    private void update_selected_app () {
        var notify_manager = Backend.NotifyManager.get_default ();
        var app_id = notify_manager.selected_app_id;
        var selected_app = notify_manager.apps.get (app_id);

        selected_app.settings.bind ("bubbles", bubbles_option.widget, "state", GLib.SettingsBindFlags.DEFAULT);
        selected_app.settings.bind ("sounds", sound_option.widget, "state", GLib.SettingsBindFlags.DEFAULT);
        selected_app.settings.bind ("remember", remember_option.widget, "state", GLib.SettingsBindFlags.DEFAULT);

        app_label.label = selected_app.app_info.get_display_name ();
        app_image.gicon = selected_app.app_info.get_icon ();
    }
}
