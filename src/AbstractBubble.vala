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

    public uint32 timeout { get; set; }

    protected Gtk.Stack content_area;

    private Hdy.Carousel carousel;
    private Gtk.Revealer close_revealer;
    private Gtk.Revealer revealer;
    private Gtk.Grid draw_area;

    private Gtk.EventControllerMotion motion_controller;
    private uint timeout_id;

    private Pantheon.Desktop.Shell? desktop_shell;
    private Pantheon.Desktop.Panel? desktop_panel;

    construct {
        content_area = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.SLIDE_DOWN,
            vhomogeneous = false
        };

        draw_area = new Gtk.Grid () {
            hexpand = true
        };
        draw_area.get_style_context ().add_class ("draw-area");
        draw_area.add (content_area);

        var close_button = new Gtk.Button.from_icon_name ("window-close-symbolic", Gtk.IconSize.LARGE_TOOLBAR) {
            halign = Gtk.Align.START,
            valign = Gtk.Align.START
        };
        close_button.get_style_context ().add_class ("close");

        close_revealer = new Gtk.Revealer () {
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

        carousel = new Hdy.Carousel () {
            allow_mouse_drag = true,
            interactive = true,
            halign = Gtk.Align.END,
            hexpand = true
        };
        carousel.add (new Gtk.Grid ());
        carousel.add (revealer);
        carousel.scroll_to (revealer);

        child = carousel;
        default_height = 0;
        default_width = 332;
        resizable = false;
        type_hint = Gdk.WindowTypeHint.NOTIFICATION;
        get_style_context ().add_class ("notification");
        // Prevent stealing focus when an app window is closed
        set_accept_focus (false);
        set_titlebar (new Gtk.Grid ());

        // we have only one real page, so we don't need to check the index
        carousel.page_changed.connect (() => closed (Notifications.Server.CloseReason.DISMISSED));
        close_button.clicked.connect (() => closed (Notifications.Server.CloseReason.DISMISSED));
        closed.connect (close);

        carousel.notify["position"].connect (() => {
            if (Gdk.Display.get_default () is Gdk.Wayland.Display) {
                int left, right;
                get_blur_margins (out left, out right);

                // TODO: Use same approach for radius as dock
                desktop_panel.add_blur (left, right, 16, 16, 9);
            } else {
                init_x ();
            }
        });

        motion_controller = new Gtk.EventControllerMotion (carousel) {
            propagation_phase = TARGET
        };
        motion_controller.enter.connect (pointer_enter);
        motion_controller.leave.connect (pointer_leave);

        realize.connect (() => {
            if (Gdk.Display.get_default () is Gdk.Wayland.Display) {
                //  We have to wrap in Idle otherwise the Meta.Window of the WaylandSurface in Gala is still null
                Idle.add_once (init_wl);
            } else {
                init_x ();
            }
        });

        var a11y_object = get_accessible ();
        a11y_object.accessible_role = NOTIFICATION;
    }

    protected override bool delete_event (Gdk.EventAny event) {
        revealer.reveal_child = false;

        Timeout.add (revealer.transition_duration, () => {
            destroy ();
            return Source.REMOVE;
        });

        return Gdk.EVENT_STOP;
    }

    public new void present () {
        if (timeout_id != 0) {
            Source.remove (timeout_id);
            timeout_id = 0;
        }

        get_child ().show_all ();
        show ();

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

    private void get_blur_margins (out int left, out int right) {
        var distance = carousel.position * width_request;
        left = (int) (16 + distance).clamp (0, width_request);
        right = (int) (16 - distance).clamp (0, width_request);
    }

    private void init_x () {
        var display = Gdk.Display.get_default ();
        if (display is Gdk.X11.Display) {
            unowned var xdisplay = ((Gdk.X11.Display) display).get_xdisplay ();

            var window = ((Gdk.X11.Window) get_window ()).get_xid ();
            var prop = xdisplay.intern_atom ("_MUTTER_HINTS", false);

            int left, right;
            get_blur_margins (out left, out right);

            var value = "blur=%d,%d,16,16,9".printf (left, right);

            xdisplay.change_property (window, prop, X.XA_STRING, 8, 0, (uchar[]) value, value.length);
        }
    }

    private static Wl.RegistryListener registry_listener;
    private void init_wl () {
        registry_listener.global = registry_handle_global;
        unowned var display = Gdk.Display.get_default ();
        if (display is Gdk.Wayland.Display) {
            unowned var wl_display = ((Gdk.Wayland.Display) display).get_wl_display ();
            var wl_registry = wl_display.get_registry ();
            wl_registry.add_listener (
                registry_listener,
                this
            );

            if (wl_display.roundtrip () < 0) {
                return;
            }
        }
    }

    public void registry_handle_global (Wl.Registry wl_registry, uint32 name, string @interface, uint32 version) {
        if (@interface == "io_elementary_pantheon_shell_v1") {
            desktop_shell = wl_registry.bind<Pantheon.Desktop.Shell> (name, ref Pantheon.Desktop.Shell.iface, uint32.min (version, 1));
            unowned var window = get_window ();
            if (window is Gdk.Wayland.Window) {
                unowned var wl_surface = ((Gdk.Wayland.Window) window).get_wl_surface ();
                desktop_panel = desktop_shell.get_panel (wl_surface);
                // TODO: Use same approach for radius as dock
                desktop_panel.add_blur (16, 16, 16, 16, 9);
            }
        }
    }
}
