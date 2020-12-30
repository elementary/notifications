/*
 * Copyright (c) 2011-2020 elementary, Inc. (https://elementary.io)
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

public class Backend.App : Object {
    public DesktopAppInfo app_info { get; construct; }
    public string app_id { get; private set; }
    public Settings settings { get; private set; }

    public App (DesktopAppInfo app_info) {
        Object (app_info: app_info);
    }

    construct {
        app_id = app_info.get_id ().replace (".desktop", "");

        string child_schema_id = "io.elementary.notifications.applications";
        string child_path = "/io/elementary/notifications/applications/%s/";
        if (GLib.SettingsSchemaSource.get_default ().lookup (child_schema_id, true) == null) {
            child_schema_id = "org.pantheon.desktop.gala.notifications.application";
            child_path = "/org/pantheon/desktop/gala/notifications/applications/%s/";
        }

        settings = new Settings.full (
            SettingsSchemaSource.get_default ().lookup (child_schema_id, true),
            null,
            child_path.printf (app_id)
        );
    }
}
