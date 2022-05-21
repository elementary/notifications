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
*/

public class Notifications.AbstractBubble : Gtk.Window {
    public signal void closed (uint32 reason);

    protected Gtk.EventControllerLegacy bubble_motion_controller;
    protected Gtk.Stack content_area;
    protected Gtk.HeaderBar headerbar;
    protected Gtk.Grid draw_area;

    private Gtk.Revealer revealer;
    private uint timeout_id;
    private Adw.Carousel carousel;

    construct {
        content_area = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.SLIDE_DOWN,
            vhomogeneous = false
        };

        draw_area = new Gtk.Grid () {
            hexpand = true,
            margin_start = 16,
            margin_end = 16,
            margin_top = 16,
            margin_bottom = 16
        };
        draw_area.add_css_class ("draw-area");
        draw_area.attach (content_area, 0, 0);

        var close_button = new Gtk.Image.from_icon_name ("window-close-symbolic") {
            halign = Gtk.Align.START,
            valign = Gtk.Align.START,
            pixel_size = 24
            // Gtk.IconSize.LARGE_TOOLBAR
        };
        close_button.get_style_context ().add_class ("close");

        var close_button_controller = new Gtk.GestureClick ();
        close_button.add_controller (close_button_controller);

        var close_revealer = new Gtk.Revealer () {
            reveal_child = false,
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            halign = Gtk.Align.START,
            valign = Gtk.Align.START,
            child = close_button
        };

        var overlay = new Gtk.Overlay () {
            child = draw_area
        };
        overlay.add_overlay (close_revealer);

        revealer = new Gtk.Revealer () {
            reveal_child = true,
            transition_duration = 195,
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            child = overlay
        };

        var label = new Gtk.Grid ();

        carousel = new Adw.Carousel () {
            allow_mouse_drag = true,
            interactive = true,
            halign = Gtk.Align.END,
            hexpand = true
        };
        carousel.append (new Gtk.Grid ());
        carousel.append (revealer);
        carousel.scroll_to (revealer, true);

        default_height = 0;
        default_width = 332;
        resizable = false;
        // type_hint = Gdk.WindowTypeHint.NOTIFICATION;
        get_style_context ().add_class ("notification");
        // Prevent stealing focus when an app window is closed
        can_focus = false;
        set_titlebar (label);
        child = carousel;

        carousel.page_changed.connect ((index) => {
            if (index == 0) {
                closed (Notifications.Server.CloseReason.DISMISSED);
                destroy ();
            }
        });

        close_button_controller.released.connect (() => {
            closed (Notifications.Server.CloseReason.DISMISSED);
            dismiss ();
            // return Gdk.EVENT_STOP;
        });

        bubble_motion_controller = new Gtk.EventControllerLegacy ();
        ((Gtk.Widget) this).add_controller (bubble_motion_controller);

        // bubble_motion_controller.enter.connect (() => {
            // close_revealer.reveal_child = true;
            // stop_timeout ();
        //     // return Gdk.EVENT_PROPAGATE;
        // });

        bubble_motion_controller.event.connect ((event) => {
            if (event.get_event_type () == Gdk.EventType.ENTER_NOTIFY) {
                close_revealer.reveal_child = true;
                stop_timeout ();
            } else if (event.get_event_type () == Gdk.EventType.LEAVE_NOTIFY) {
                // if (event.detail == Gdk.NotifyType.INFERIOR) {
                //     return Gdk.EVENT_STOP;
                // }

                close_revealer.reveal_child = false;
                return Gdk.EVENT_PROPAGATE;
            }
        });
    }

    protected void stop_timeout () {
        if (timeout_id != 0) {
            Source.remove (timeout_id);
            timeout_id = 0;
        }
    }

    protected void start_timeout (uint timeout) {
        if (timeout_id != 0) {
            Source.remove (timeout_id);
        }

        timeout_id = GLib.Timeout.add (timeout, () => {
            timeout_id = 0;
            closed (Notifications.Server.CloseReason.EXPIRED);
            dismiss ();
            return false;
        });
    }

    public void dismiss () {
        revealer.reveal_child = false;
        GLib.Timeout.add (revealer.transition_duration, () => {
            destroy ();
            return false;
        });
    }
}
