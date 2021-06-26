/*
 * Copyright 2011-2020 elementary, Inc. (https://elementary.io)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street - Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

public class Backend.NotifyManager : Object {
    public static NotifyManager? instance = null;

    public static unowned NotifyManager get_default () {
        if (instance == null) {
            instance = new NotifyManager ();
        }

        return instance;
    }

    public Gee.HashMap<string, App> apps { get; construct; } /* string: app-id */

    public string selected_app_id { get; set; }

    construct {
        apps = new Gee.HashMap<string, App> ();

        var installed_apps = AppInfo.get_all ();

        foreach (AppInfo app_info in installed_apps) {
            DesktopAppInfo? desktop_app_info = app_info as DesktopAppInfo;

            if (desktop_app_info != null && desktop_app_info.get_boolean ("X-GNOME-UsesNotifications")) {
                var app = new App (desktop_app_info);
                apps.@set (app.app_id, app);
            }
        }
    }
}
