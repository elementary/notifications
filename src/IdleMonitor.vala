/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: Copyright 2025 elementary, Inc. (https://elementary.io)
 */

public class Notifications.IdleMonitor : Object {
    [DBus (name = "org.gnome.Mutter.IdleMonitor")]
    private interface MutterIdleMonitor : Object {
        public signal void watch_fired (uint32 id);
        public abstract uint32 add_idle_watch (uint64 interval) throws Error;
    }

    private static GLib.Once<IdleMonitor> instance;
    public static unowned IdleMonitor get_default () {
        return instance.once (() => new IdleMonitor ());
    }

    private MutterIdleMonitor? idle_monitor;
    private uint32 idle_id = 0;
    private uint32 active_id = 0;

    public bool is_idle { get; private set; default = false; }

    construct {
        Bus.get_proxy.begin<MutterIdleMonitor> (
            SESSION, "org.gnome.Mutter.IdleMonitor", "/org/gnome/Mutter/IdleMonitor/Core", NONE, null,
            (obj, res) => {
                try {
                    idle_monitor = Bus.get_proxy.end<MutterIdleMonitor> (res);
                    idle_id = idle_monitor.add_idle_watch (30000);
                    active_id = idle_monitor.add_idle_watch (100);
                    idle_monitor.watch_fired.connect ((id) => {
                        if (id == idle_id) {
                            is_idle = true;
                        } else if (id == active_id && is_idle) {
                            is_idle = false;
                        }
                    });
                } catch (Error e) {
                    warning ("Couldn't connect to idle monitor: %s", e.message);
                }
            }
        );
    }
}
