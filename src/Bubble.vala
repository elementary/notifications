/*
 * Copyright 2019-2023 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Notifications.Bubble : AbstractBubble {
    public new string action_name {
        get { return notification.default_action_name; }
    }

    // public new Variant action_target {
    //     owned get { return get_action_target_value (); }
    //     set { set_action_target_value (value); }
    // }

    public Notification notification {
        get {
            return _notification;
        }

        set {
            _notification = value;
            timeout = 0;

            var contents = new Contents (value);

            if (value.priority == URGENT) {
                contents.add_css_class ("urgent");
            } else {
                timeout = 4000;
            }

            content_area.add_child (contents);
            content_area.visible_child = contents;
        }
    }

    private Notification _notification;
    private Gtk.GestureClick click_gesture;

    public Bubble (Notification notification) {
        Object (notification: notification);
    }

    construct {
        click_gesture = new Gtk.GestureClick () {
            propagation_phase = BUBBLE
        };
        click_gesture.released.connect (released);

        ((Gtk.Widget) this).add_controller (click_gesture);
    }

    private void released () {
        if (action_name != null) {
            // FIXME: what the action
            // foreach (unowned var prefix in list_action_prefixes ()) {
            //     if (!action_name.has_prefix (prefix)) {
            //         continue;
            //     }

            //     get_action_group (prefix).activate_action (action_name[prefix.length + 1:], action_target);
            //     click_gesture.set_state (CLAIMED);
            //     return;
            // }

            warning ("cannot activate action '%s': no action group match prefix.", action_name);
        }

        if (notification.app_info != null) {
            notification.app_info.launch_uris_async.begin (null, null, null, (obj, res) => {
                try {
                    ((AppInfo) obj).launch_uris_async.end (res);
                    closed (Server.CloseReason.UNDEFINED);
                } catch (Error e) {
                    warning ("Unable to launch app: %s", e.message);
                }
            });
        }

        click_gesture.set_state (CLAIMED);
    }

    // public unowned string? get_action_name () {
    //     return notification.default_action_name;
    // }

    // public unowned Variant? get_action_target_value () {
    //     return notification.default_action_target;
    // }

    // we ignore the set methods because we query the notification model instead.
    // public void set_action_name (string? @value) {
    // }

    // public void set_action_target_value (Variant? @value) {
    // }

    private class Contents : Gtk.Grid {
        public Notifications.Notification notification { get; construct; }

        public Contents (Notifications.Notification notification) {
            Object (notification: notification);
        }

        construct {
            var app_image = new Gtk.Image () {
                gicon = notification.primary_icon
            };

            var image_overlay = new Gtk.Overlay ();
            image_overlay.valign = Gtk.Align.START;

            if (notification.image != null) {
                app_image.pixel_size = 24;
                app_image.halign = app_image.valign = Gtk.Align.END;

                image_overlay.child = notification.image;
                image_overlay.add_overlay (app_image);
            } else {
                app_image.pixel_size = 48;
                image_overlay.child = app_image;

                if (notification.badge_icon != null) {
                    var badge_image = new Gtk.Image.from_gicon (notification.badge_icon) {
                        halign = Gtk.Align.END,
                        valign = Gtk.Align.END,
                        pixel_size = 24
                    };
                    image_overlay.add_overlay (badge_image);
                }
            }

            var title_label = new Gtk.Label (notification.summary) {
                ellipsize = Pango.EllipsizeMode.END,
                max_width_chars = 33,
                valign = Gtk.Align.END,
                width_chars = 33,
                xalign = 0
            };
            title_label.add_css_class ("title");

            var body_label = new Gtk.Label (notification.body) {
                ellipsize = Pango.EllipsizeMode.END,
                lines = 2,
                max_width_chars = 33,
                use_markup = true,
                valign = Gtk.Align.START,
                width_chars = 33,
                wrap = true,
                wrap_mode = Pango.WrapMode.WORD_CHAR,
                xalign = 0
            };

            if ("\n" in notification.body) {
                string[] lines = notification.body.split ("\n");
                string stripped_body = lines[0] + "\n";
                for (int i = 1; i < lines.length; i++) {
                    stripped_body += lines[i].strip () + "";
                }

                body_label.label = stripped_body.strip ();
                body_label.lines = 1;
            }

            column_spacing = 6;
            attach (image_overlay, 0, 0, 1, 2);
            attach (title_label, 1, 0);
            attach (body_label, 1, 1);

            if (notification.buttons.length > 0) {
                var action_area = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
                    halign = Gtk.Align.END,
                    homogeneous = true
                };
                action_area.add_css_class ("buttonbox");

                foreach (var button in notification.buttons) {
                    action_area.append (new Gtk.Button.with_label (button.label) {
                        action_name = button.action_name
                    });
                }

                attach (action_area, 0, 2, 2);
            }

            var a11y_object = get_accessible ();
            a11y_object.accessible_name = title_label.label;
            a11y_object.accessible_description = body_label.label;
        }
    }
}
