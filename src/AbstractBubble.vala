/*
* Copyright 2020-2025 elementary, Inc. (https://elementary.io)
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

public enum Notifications.CloseReason {
    EXPIRED = 1,
    DISMISSED = 2,
    /**
     * This value is unique for org.freedesktop.Notifications server interface and must not be used elsewhere.
     */
    CLOSE_NOTIFICATION_CALL = 3,
    UNDEFINED = 4
}

public class Notifications.AbstractBubble : Gtk.Window {
    public signal void closed (CloseReason reason) {
        close ();
    }

    public uint32 timeout { get; set; }

    protected Gtk.Stack content_area;

    private static Settings? transparency_settings;

    private Gtk.Revealer close_revealer;
    private Gtk.Box draw_area;

    private uint timeout_id;

    private double current_swipe_progress = 1.0;
    private Pantheon.Desktop.Shell? desktop_shell;
    private Pantheon.Desktop.Panel? desktop_panel;

    static construct {
        var transparency_schema = SettingsSchemaSource.get_default ().lookup ("io.elementary.desktop.wingpanel", true);
        if (transparency_schema != null && transparency_schema.has_key ("use-transparency")) {
            transparency_settings = new Settings ("io.elementary.desktop.wingpanel");
        }
    }

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
                closed (CloseReason.DISMISSED);
            }
        });
        close_button.clicked.connect (() => closed (CloseReason.DISMISSED));

        var motion_controller = new Gtk.EventControllerMotion ();
        motion_controller.enter.connect (pointer_enter);
        motion_controller.leave.connect (pointer_leave);
        carousel.add_controller (motion_controller);

        child.realize.connect (() => {
            if (Gdk.Display.get_default () is Gdk.Wayland.Display) {
                //  We have to wrap in Idle otherwise the Meta.Window of the WaylandSurface in Gala is still null
                Idle.add_once (init_wl);
            } else {
                x11_make_notification ();
                x11_update_mutter_hints ();
            }
        });

        carousel.notify["position"].connect (() => {
            current_swipe_progress = carousel.position;

            if (desktop_panel != null) {
                int left, right;
                get_blur_margins (out left, out right);

                desktop_panel.add_blur (left, right, 16, 16, 9);
            } else if (Gdk.Display.get_default () is Gdk.X11.Display) {
                x11_update_mutter_hints ();
            }
        });

        transparency_settings.changed["use-transparency"].connect (update_transparency);
        update_transparency ();
    }

    private void update_transparency () requires (transparency_settings != null) {
        if (transparency_settings.get_boolean ("use-transparency")) {
            remove_css_class ("reduce-transparency");
        } else {
            add_css_class ("reduce-transparency");
        }
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
        closed (CloseReason.EXPIRED);
        return Source.REMOVE;
    }

    private void get_blur_margins (out int left, out int right) {
        var width = get_width ();
        var distance = (1 - current_swipe_progress) * width;
        left = (int) (16 + distance).clamp (0, width);
        right = (int) (16 - distance).clamp (0, width);
    }

    private void x11_update_mutter_hints () {
        var display = Gdk.Display.get_default ();
        if (display is Gdk.X11.Display) {
            unowned var xdisplay = ((Gdk.X11.Display) display).get_xdisplay ();

            var window = ((Gdk.X11.Surface) get_surface ()).get_xid ();
            var prop = xdisplay.intern_atom ("_MUTTER_HINTS", false);

            int left, right;
            get_blur_margins (out left, out right);

            var value = "blur=%d,%d,16,16,9".printf (left, right);

            xdisplay.change_property (window, prop, X.XA_STRING, 8, 0, (uchar[]) value, value.length);
        }
    }

    private void x11_make_notification () {
        unowned var display = Gdk.Display.get_default ();
        if (display is Gdk.X11.Display) {
            unowned var xdisplay = ((Gdk.X11.Display) display).get_xdisplay ();

            var window = ((Gdk.X11.Surface) get_surface ()).get_xid ();

            var atom = xdisplay.intern_atom ("_NET_WM_WINDOW_TYPE", false);
            var notification_atom = xdisplay.intern_atom ("_NET_WM_WINDOW_TYPE_NOTIFICATION", false);

            // (X.Atom) 4 is XA_ATOM
            // 32 is format
            // 0 means replace
            xdisplay.change_property (window, atom, (X.Atom) 4, 32, 0, (uchar[]) notification_atom, 1);
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
            unowned var surface = get_surface ();
            if (surface is Gdk.Wayland.Surface) {
                unowned var wl_surface = ((Gdk.Wayland.Surface) surface).get_wl_surface ();
                desktop_panel = desktop_shell.get_panel (wl_surface);
                desktop_panel.add_blur (16, 16, 16, 16, 9);
            }
        }
    }
}
