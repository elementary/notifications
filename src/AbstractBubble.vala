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
    public signal void closed (uint32 reason) {
        close ();
    }

    public uint32 timeout { get; set; }

    protected Gtk.Stack content_area;

    private Gtk.Revealer close_revealer;
    private Gtk.Box draw_area;

    private uint timeout_id;

    construct {
        content_area = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.SLIDE_DOWN,
            vhomogeneous = false
        };

        draw_area = new Gtk.Box (HORIZONTAL, 0) {
            hexpand = true
        };
        draw_area.add_css_class ("draw-area");
        draw_area.append (content_area);

        var close_button = new Gtk.Button.from_icon_name ("window-close-symbolic") {
            halign = Gtk.Align.START,
            valign = Gtk.Align.START
        };
        close_button.add_css_class ("close");

        close_revealer = new Gtk.Revealer () {
            reveal_child = false,
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            halign = Gtk.Align.START,
            valign = Gtk.Align.START,
            child = close_button,
            overflow = VISIBLE
        };

        var overlay = new Gtk.Overlay () {
            child = draw_area
        };
        overlay.add_overlay (close_revealer);

        var carousel = new Adw.Carousel () {
            hexpand = true
        };
        carousel.append (new Gtk.Grid ());
        carousel.append (overlay);
        carousel.scroll_to (overlay, false);

        child = carousel;
        default_width = 332;
        resizable = false;
        add_css_class ("notification");
        // Prevent stealing focus when an app window is closed
        can_focus = false;
        set_titlebar (new Gtk.Grid ());

        carousel.page_changed.connect ((index) => {
            if (index == 0) {
                closed (Notifications.Server.CloseReason.DISMISSED);
            }
        });
        close_button.clicked.connect (() => closed (Notifications.Server.CloseReason.DISMISSED));

        var motion_controller = new Gtk.EventControllerMotion ();
        motion_controller.enter.connect (pointer_enter);
        motion_controller.leave.connect (pointer_leave);
        carousel.add_controller (motion_controller);
    }

    public new void present () {
        if (timeout_id != 0) {
            Source.remove (timeout_id);
            timeout_id = 0;
        }

        base.present ();

        if (timeout != 0) {
            timeout_id = Timeout.add (timeout, timeout_expired);
        }
    }

    private void pointer_enter () {
        close_revealer.reveal_child = true;

        if (timeout_id != 0) {
            Source.remove (timeout_id);
            timeout_id = 0;
        }
    }

    private void pointer_leave () {
        close_revealer.reveal_child = false;

        if (timeout != 0) {
            timeout_id = Timeout.add (timeout, timeout_expired);
        }
    }

    private bool timeout_expired () {
        closed (Notifications.Server.CloseReason.EXPIRED);
        return Source.REMOVE;
    }
}
