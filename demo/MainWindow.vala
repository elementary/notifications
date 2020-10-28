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
 * Authored by: Marius Meisenzahl <mariusmeisenzahl@gmail.com>
 *
 */

public class MainWindow : Gtk.ApplicationWindow {
    private Gtk.Entry title_entry;
    private Gtk.Entry body_entry;
    private Gtk.Entry id_entry;
    private Gtk.ComboBoxText priority_combobox;

    public MainWindow (Gtk.Application application) {
        Object (application: application);
    }

    construct {
        title = "Notifications Demo";
        default_width = 400;

        title_entry = new Gtk.Entry () {
            placeholder_text = "Title",
            text = "Title"
        };

        body_entry = new Gtk.Entry () {
            placeholder_text = "Body",
            text = "Body"
        };

        id_entry = new Gtk.Entry () {
            placeholder_text = "Replaces Id"
        };

        var priority_label = new Gtk.Label ("Priority:");

        priority_combobox = new Gtk.ComboBoxText () {
            hexpand = true
        };
        priority_combobox.append_text ("Low");
        priority_combobox.append_text ("Normal");
        priority_combobox.append_text ("High");
        priority_combobox.append_text ("Urgent");
        priority_combobox.set_active (1);


        var send_button = new Gtk.Button.with_label ("Send Notification") {
            halign = Gtk.Align.END,
            margin_top = 12
        };
        send_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var grid = new Gtk.Grid () {
            valign = Gtk.Align.CENTER,
            column_spacing = 12,
            row_spacing = 12,
            margin = 12
        };
        grid.attach (title_entry, 0, 0, 2);
        grid.attach (body_entry, 0, 1, 2);
        grid.attach (id_entry, 0, 2, 2);
        grid.attach (priority_label, 0, 3);
        grid.attach (priority_combobox, 1, 3);
        grid.attach (send_button, 0, 4, 2);

        add (grid);

        send_button.clicked.connect (send_notification);
    }

    private void send_notification () {
        NotificationPriority priority;
        switch (priority_combobox.active) {
        case 3:
            priority = NotificationPriority.URGENT;
            break;
        case 2:
            priority = NotificationPriority.HIGH;
            break;
        case 1:
            priority = NotificationPriority.LOW;
            break;
        case 0:
        default:
            priority = NotificationPriority.NORMAL;
            break;
        }

        var notification = new Notification (title_entry.text);
        notification.set_body (body_entry.text);
        notification.set_priority (priority);

        string? id = id_entry.text.length == 0 ? null : id_entry.text;

        application.send_notification (id, notification);
    }
}
