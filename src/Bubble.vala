/*
 * Copyright 2019-2023 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Notifications.Bubble : AbstractBubble {
    public signal void action_invoked (string action_key);

    public Notification notification {
        get {
            return _notification;
        }

        set {
            _notification = value;
            timeout = 0;

            for (int i = 0; i < notification.actions.length; i += 2) {
                if (notification.actions[i] == "default") {
                    _has_default = true;
                    break;
                }
            }

            var contents = new Contents (value);
            contents.action_invoked.connect ((a) => action_invoked (a));
            contents.show_all ();

            if (value.priority == URGENT) {
                contents.get_style_context ().add_class ("urgent");
            } else {
                timeout = 4000;
            }

            content_area.add (contents);
            content_area.visible_child = contents;
        }
    }

    private Notification _notification;
    private Gtk.GestureMultiPress press_gesture;
    private bool _has_default;

    public Bubble (Notification notification) {
        Object (notification: notification);
    }

    construct {
        press_gesture = new Gtk.GestureMultiPress (this) {
            propagation_phase = BUBBLE
        };
        press_gesture.released.connect (released);

        action_invoked.connect (close);
    }

    private void released () {
        if (_has_default) {
            action_invoked ("default");
        } else if (notification.app_info != null) {
            notification.app_info.launch_uris_async.begin (null, null, null, (obj, res) => {
                try {
                    ((AppInfo) obj).launch_uris_async.end (res);
                    close ();
                } catch (Error e) {
                    critical ("Unable to launch app: %s", e.message);
                }
            });
        }

        press_gesture.set_state (CLAIMED);
    }

    private class Contents : Gtk.Grid {
        public signal void action_invoked (string action_key);

        public Notifications.Notification notification { get; construct; }

        public Contents (Notifications.Notification notification) {
            Object (notification: notification);
        }

        construct {
            var image_overlay = new Gtk.Overlay () {
                valign = START
            };

            if (notification.image is LoadableIcon) {
                image_overlay.child = new MaskedImage ((LoadableIcon) notification.image);
            } else {
                image_overlay.child = new Gtk.Image.from_gicon (notification.image, DIALOG) {
                    pixel_size = 48
                };
            }

            if (notification.badge != null) {
                var badge_image = new Gtk.Image.from_gicon (notification.badge, LARGE_TOOLBAR) {
                    pixel_size = 24,
                    halign = END,
                    valign = END
                };

                image_overlay.add_overlay (badge_image);
            }

            var title_label = new Gtk.Label (notification.title) {
                ellipsize = Pango.EllipsizeMode.END,
                max_width_chars = 33,
                valign = Gtk.Align.END,
                width_chars = 33,
                xalign = 0
            };
            title_label.get_style_context ().add_class ("title");

            var body_label = new Gtk.Label (notification.body) {
                ellipsize = Pango.EllipsizeMode.END,
                lines = "\n" in notification.body ? 1 : 2,
                max_width_chars = 33,
                use_markup = true,
                valign = Gtk.Align.START,
                width_chars = 33,
                wrap = true,
                wrap_mode = Pango.WrapMode.WORD_CHAR,
                xalign = 0
            };

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
