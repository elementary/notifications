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
        this.application = application;

        title = "Notifications Demo";
        set_default_size (400, 400);

        var grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER,
            row_spacing = 12
        };

        title_entry = new Gtk.Entry () {
            hexpand = true,
            placeholder_text = "Title",
            text = "Title"
        };
        grid.add (title_entry);

        body_entry = new Gtk.Entry () {
            hexpand = true,
            placeholder_text = "Body",
            text = "Body"
        };
        grid.add (body_entry);

        id_entry = new Gtk.Entry () {
            hexpand = true,
            placeholder_text = "Id"
        };
        grid.add (id_entry);

        var priority_label = new Gtk.Label ("Priority:");

        priority_combobox = new Gtk.ComboBoxText () {
            hexpand = true
        };
        priority_combobox.append_text ("low");
        priority_combobox.append_text ("normal");
        priority_combobox.append_text ("high");
        priority_combobox.append_text ("urgent");
        priority_combobox.set_active (1);

        var priority_grid = new Gtk.Grid () {
            column_spacing = 6,
            margin = 6
        };
        priority_grid.add (priority_label);
        priority_grid.add (priority_combobox);
        grid.add (priority_grid);


        var send_button = new Gtk.Button.with_label ("Send notification");
        send_button.clicked.connect (send_notification);
        grid.add (send_button);

        add (grid);
    }

    private void send_notification () {
        var notification = new Notification (title_entry.text);
        notification.set_body (body_entry.text);

        NotificationPriority priority;
        switch (priority_combobox.get_active_text ()) {
        case "urgent":
            priority = NotificationPriority.URGENT;
            break;
        case "high":
            priority = NotificationPriority.HIGH;
            break;
        case "low":
            priority = NotificationPriority.LOW;
            break;
        case "normal":
        default:
            priority = NotificationPriority.NORMAL;
            break;
        }
        notification.set_priority (priority);

        string? id = id_entry.text.length == 0 ? null : id_entry.text;

        application.send_notification (id, notification);
    }
}
