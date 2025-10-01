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
    private Gtk.Entry icon_entry;
    private Gtk.Entry id_entry;
    private Gtk.DropDown priority_dropdown;
    private Gtk.SpinButton action_spinbutton;

    public MainWindow (Gtk.Application application) {
        Object (application: application);
    }

    construct {
        title = "Notifications Demo";
        default_width = 400;

        title_entry = new Gtk.Entry () {
            activates_default = true,
            placeholder_text = "Title",
            text = "Title"
        };

        body_entry = new Gtk.Entry () {
            activates_default = true,
            placeholder_text = "Body",
            text = "Body"
        };

        id_entry = new Gtk.Entry () {
            activates_default = true,
            placeholder_text = "Replaces Id"
        };

        icon_entry = new Gtk.Entry () {
            activates_default = true,
            placeholder_text = "Badge Icon Name"
        };

        var priority_label = new Gtk.Label ("Priority:");

        string[] priorities = {
            "Low",
            "Normal",
            "High",
            "Urgent",
        };
        priority_dropdown = new Gtk.DropDown.from_strings (priorities) {
            hexpand = true,
            selected = 1
        };

        var action_label = new Gtk.Label ("Actions:");

        action_spinbutton = new Gtk.SpinButton.with_range (0, 3, 1);

        var send_button = new Gtk.Button.with_label ("Send Notification") {
            halign = Gtk.Align.END,
            margin_top = 12
        };
        send_button.add_css_class (Granite.CssClass.SUGGESTED);

        var grid = new Gtk.Grid () {
            valign = Gtk.Align.CENTER,
            column_spacing = 12,
            row_spacing = 12,
            margin_top = 12,
            margin_bottom = 12,
            margin_start = 12,
            margin_end = 12
        };
        grid.attach (title_entry, 0, 0, 2);
        grid.attach (body_entry, 0, 1, 2);
        grid.attach (id_entry, 0, 2, 2);
        grid.attach (icon_entry, 0, 3, 2);
        grid.attach (priority_label, 0, 4);
        grid.attach (priority_dropdown, 1, 4);
        grid.attach (action_label, 0, 5);
        grid.attach (action_spinbutton, 1, 5);
        grid.attach (send_button, 0, 6, 2);

        var toast = new Granite.Toast ("");

        var overlay = new Gtk.Overlay () {
            child = grid
        };
        overlay.add_overlay (toast);

        child = overlay;

        send_button.grab_focus ();
        send_button.clicked.connect (send_notification);

        var toast_action = new SimpleAction ("toast", VariantType.STRING);

        GLib.Application.get_default ().add_action (toast_action);

        toast_action.activate.connect ((parameter) => {
            toast.title = parameter.get_string ();
            toast.send_notification ();
        });
    }

    private void send_notification () {
        NotificationPriority priority;
        switch (priority_dropdown.selected) {
            case 3:
                priority = NotificationPriority.URGENT;
                break;
            case 2:
                priority = NotificationPriority.HIGH;
                break;
            case 0:
                priority = NotificationPriority.LOW;
                break;
            case 1:
            default:
                priority = NotificationPriority.NORMAL;
                break;
        }

        var notification = new GLib.Notification (title_entry.text);
        notification.set_body (body_entry.text);
        notification.set_priority (priority);

        for (int i = 1; i <= action_spinbutton.value; i++) {
            var title = "Action %i".printf (i);
            notification.add_button (
                title,
                GLib.Action.print_detailed_name ("app.toast", new Variant ("s", title))
            );
        }

        string? id = id_entry.text.length == 0 ? null : id_entry.text;

        if (icon_entry.text != "") {
            notification.set_icon (new ThemedIcon (icon_entry.text));
        }

        application.send_notification (id, notification);
    }
}
