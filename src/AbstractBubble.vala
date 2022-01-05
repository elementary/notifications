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
            margin = 16
        };
        draw_area.get_style_context ().add_class ("draw-area");
        draw_area.attach (content_area, 0, 0);

        var close_button = new Gtk.Button.from_icon_name ("window-close-symbolic", Gtk.IconSize.LARGE_TOOLBAR) {
            halign = Gtk.Align.START,
            valign = Gtk.Align.START
        };
        close_button.get_style_context ().add_class ("close");

        var close_revealer = new Gtk.Revealer () {
            reveal_child = false,
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            halign = Gtk.Align.START,
            valign = Gtk.Align.START
        };
        close_revealer.add (close_button);

        var overlay = new Gtk.Overlay ();
        overlay.add (draw_area);
        overlay.add_overlay (close_revealer);

        revealer = new Gtk.Revealer () {
            reveal_child = true,
            transition_duration = 195,
            transition_type = Gtk.RevealerTransitionType.CROSSFADE
        };
        revealer.add (overlay);

        var label = new Gtk.Grid ();

        carousel = new Adw.Carousel () {
            allow_mouse_drag = true,
            interactive = true,
            halign = Gtk.Align.END,
            hexpand = true
        };
        carousel.add (new Gtk.Grid ());
        carousel.add (revealer);
        carousel.scroll_to (revealer);

        default_height = 0;
        default_width = 332;
        resizable = false;
        type_hint = Gdk.WindowTypeHint.NOTIFICATION;
        get_style_context ().add_class ("notification");
        // Prevent stealing focus when an app window is closed
        set_accept_focus (false);
        set_titlebar (label);
        add (carousel);

        carousel.page_changed.connect ((index) => {
            if (index == 0) {
                closed (Notifications.Server.CloseReason.DISMISSED);
                destroy ();
            }
        });

        close_button.button_release_event.connect (() => {
            closed (Notifications.Server.CloseReason.DISMISSED);
            dismiss ();
            return Gdk.EVENT_STOP;
        });

        enter_notify_event.connect (() => {
            close_revealer.reveal_child = true;
            stop_timeout ();
            return Gdk.EVENT_PROPAGATE;
        });

        leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return Gdk.EVENT_STOP;
            }
            close_revealer.reveal_child = false;
            return Gdk.EVENT_PROPAGATE;
        });

        var granite_settings = Granite.Settings.get_default ();
        var gtk_settings = Gtk.Settings.get_default ();

        gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;

        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
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
