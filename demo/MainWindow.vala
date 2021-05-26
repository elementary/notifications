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
    private Gtk.ComboBoxText category_combobox;
    private Gtk.ComboBoxText sound_combobox;
    private Gtk.Switch suppress_sound_switch;

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

        var priority_label = new Gtk.Label ("Priority:");

        priority_combobox = new Gtk.ComboBoxText () {
            hexpand = true
        };
        priority_combobox.append_text ("Low");
        priority_combobox.append_text ("Normal");
        priority_combobox.append_text ("High");
        priority_combobox.append_text ("Urgent");
        priority_combobox.set_active (1);

        var libnotify_label = new Gtk.Label ("Libnotify Tests") {
            halign = Gtk.Align.CENTER
        };

        var category_label = new Gtk.Label ("Category:");

        category_combobox = new Gtk.ComboBoxText () {
            hexpand = true
        };
        category_combobox.append_text ("");
        category_combobox.append_text ("device");
        category_combobox.append_text ("device.added");
        category_combobox.append_text ("device.error");
        category_combobox.append_text ("device.removed");
        category_combobox.append_text ("email");
        category_combobox.append_text ("email.arrived");
        category_combobox.append_text ("email.bounced");
        category_combobox.append_text ("im");
        category_combobox.append_text ("im.error");
        category_combobox.append_text ("im.received");
        category_combobox.append_text ("network");
        category_combobox.append_text ("network.connected");
        category_combobox.append_text ("network.disconnected");
        category_combobox.append_text ("network.error");
        category_combobox.append_text ("presence");
        category_combobox.append_text ("presence.offline");
        category_combobox.append_text ("presence.online");
        category_combobox.append_text ("transfer");
        category_combobox.append_text ("transfer.complete");
        category_combobox.append_text ("transfer.error");
        category_combobox.set_active (0);

        var sound_label = new Gtk.Label ("Sound Name:");

        sound_combobox = new Gtk.ComboBoxText () {
            hexpand = true
        };
        sound_combobox.append_text ("");
        sound_combobox.append_text ("device-added");
        sound_combobox.append_text ("device-removed");
        sound_combobox.append_text ("dialog-error");
        sound_combobox.append_text ("dialog-information");
        sound_combobox.append_text ("message-new-instant");
        sound_combobox.append_text ("message");
        sound_combobox.append_text ("network-connectivity-established");
        sound_combobox.append_text ("network-connectivity-lost");
        sound_combobox.append_text ("service-login");
        sound_combobox.append_text ("service-logout");
        sound_combobox.set_active (0);

        var suppress_sound_label = new Gtk.Label ("Suppress Sounds:");
        suppress_sound_switch = new Gtk.Switch () {
            active = false,
            halign = Gtk.Align.START
        };

        var send_button = new Gtk.Button.with_label ("Send Notification") {
            can_default = true,
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
        grid.attach (libnotify_label, 0, 4, 2);
        grid.attach (category_label, 0, 5);
        grid.attach (category_combobox, 1, 5);
        grid.attach (sound_label, 0, 6);
        grid.attach (sound_combobox, 1, 6);
        grid.attach (suppress_sound_label, 0, 7);
        grid.attach (suppress_sound_switch, 1, 7);
        grid.attach (send_button, 0, 8, 2);

        add (grid);

        send_button.has_default = true;
        send_button.clicked.connect (route_notification);
    }

    private void route_notification () {
        var category = category_combobox.get_active_text ();
        var sound = sound_combobox.get_active_text ();
        if (category.length > 0 || sound.length > 0) {
            send_libnotify_notification ();
        } else {
            send_notification ();
        }
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
        case 0:
            priority = NotificationPriority.LOW;
            break;
        case 1:
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

    private void send_libnotify_notification () {
        Notify.init ("io.elementary.notifications.demo");

        Notify.Urgency urgency;
        switch (priority_combobox.active) {
        case 3:
        case 2:
            urgency = Notify.Urgency.CRITICAL;
            break;
        case 0:
            urgency = Notify.Urgency.LOW;
            break;
        case 1:
        default:
            urgency = Notify.Urgency.NORMAL;
            break;
        }

        var notification = new Notify.Notification (title_entry.text, body_entry.text, "preferences-system-notifications") {
            app_name = "io.elementary.notifications.demo"
        };
        notification.set_urgency (urgency);

        var category = category_combobox.get_active_text ();
        if (category.length > 0) {
            notification.set_category (category_combobox.get_active_text ());
        }

        var sound = sound_combobox.get_active_text ();
        if (sound.length > 0) {
            Variant sound_name = new Variant ("s", sound_combobox.get_active_text ());
            notification.set_hint ("sound-name", sound_name);
        }

        Variant suppress_sound = new Variant ("b", suppress_sound_switch.active);
        notification.set_hint ("suppress-sound", suppress_sound);

        try {
            notification.show ();
        } catch (Error e) {
            critical ("Failed to send notification: %s", e.message);
        }
    }
}
