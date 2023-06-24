/*
 * Copyright 2019-2023 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Notifications.Bubble : AbstractBubble {
    public signal void action_invoked (string action_key);

    public Notifications.Notification notification { get; construct; }

    private Gtk.GestureMultiPress press_gesture;

    public Bubble (Notification notification) {
        Object (notification: notification);
    }

    construct {
        var contents = new Contents (notification);

        content_area.add (contents);

        switch (notification.priority) {
            case GLib.NotificationPriority.HIGH:
            case GLib.NotificationPriority.URGENT:
                content_area.get_style_context ().add_class ("urgent");
                break;
            default:
                timeout = 4000;
                break;
        }

        bool default_action = false;
        bool has_actions = notification.actions.length > 0;

        for (int i = 0; i < notification.actions.length; i += 2) {
            if (notification.actions[i] == "default") {
                default_action = true;
                break;
            }
        }

        contents.action_invoked.connect ((action_key) => {
            action_invoked (action_key);
            close ();
        });

        press_gesture = new Gtk.GestureMultiPress (this) {
            propagation_phase = BUBBLE
        };
        press_gesture.released.connect (() => {
            if (default_action) {
                action_invoked ("default");
                close ();
            } else if (notification.app_info != null && !has_actions) {
                try {
                    notification.app_info.launch (null, null);
                    close ();
                } catch (Error e) {
                    critical ("Unable to launch app: %s", e.message);
                }
            }

            press_gesture.set_state (CLAIMED);
        });
    }

    public void replace (Notifications.Notification new_notification) {
        var new_contents = new Contents (new_notification);
        new_contents.show_all ();

        new_contents.action_invoked.connect ((action_key) => {
            action_invoked (action_key);
            close ();
        });

        content_area.add (new_contents);
        content_area.visible_child = new_contents;
    }

    private class Contents : Gtk.Grid {
        public signal void action_invoked (string action_key);

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

                image_overlay.add (notification.image);
                image_overlay.add_overlay (app_image);
            } else {
                app_image.pixel_size = 48;
                image_overlay.add (app_image);

                if (notification.badge_icon != null) {
                    var badge_image = new Gtk.Image.from_gicon (notification.badge_icon, Gtk.IconSize.LARGE_TOOLBAR) {
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
            title_label.get_style_context ().add_class ("title");

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

            if (notification.actions.length > 0) {
                var action_area = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
                    halign = Gtk.Align.END,
                    homogeneous = true
                };
                action_area.get_style_context ().add_class ("buttonbox");

                bool action_area_packed = false;

                for (int i = 0; i < notification.actions.length; i += 2) {
                    if (notification.actions[i] != "default") {
                        var button = new Gtk.Button.with_label (notification.actions[i + 1]);
                        var action = notification.actions[i].dup ();

                        button.clicked.connect (() => {
                            action_invoked (action);
                        });

                        action_area.pack_end (button);

                        if (!action_area_packed) {
                            attach (action_area, 0, 2, 2);
                            action_area_packed = true;
                        }
                    } else {
                        i += 2;
                    }
                }
            }
        }
    }
}
