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

public class Notifications.Notification : GLib.Object {
    private const string OTHER_APP_ID = "gala-other";

    public GLib.DesktopAppInfo? app_info { get; private set; default = null; }
    public GLib.NotificationPriority priority { get; private set; default = GLib.NotificationPriority.NORMAL; }
    public HashTable<string, Variant> hints { get; construct; }
    public string[] actions { get; construct; }
    public string app_icon { get; construct; }
    public string app_id { get; private set; default = OTHER_APP_ID; }
    public string app_name { get; construct; }
    public string body { get; construct set; }
    public string? image_path { get; private set; default = null; }
    public string summary { get; construct set; }

    public Notification (string app_name, string app_icon, string summary, string body, string[] actions, HashTable<string, Variant> hints) {
        Object (
            app_name: app_name,
            app_icon: app_icon,
            summary: summary,
            body: body,
            actions: actions,
            hints: hints
        );
    }

    construct {
        /*Only summary is required by GLib, so try to set a title when body is empty*/
        if (body == "") {
            body = summary;
            summary = app_name;
        }

        unowned Variant? variant = null;

        if ((variant = hints.lookup ("urgency")) != null && variant.is_of_type (VariantType.BYTE)) {
            priority = (GLib.NotificationPriority) variant.get_byte ();
        }

        if ((variant = hints.lookup ("desktop-entry")) != null && variant.is_of_type (VariantType.STRING)) {
            app_id = variant.get_string ();
            app_id.replace (".desktop", "");

            app_info = new DesktopAppInfo ("%s.desktop".printf (app_id));
        }

        if ((variant = hints.lookup ("image-path")) != null || (variant = hints.lookup ("image_path")) != null) {
            image_path = variant.get_string ();

            if (!image_path.has_prefix ("/") && !image_path.has_prefix ("file://")) {
                image_path = null;
            }
        }

        if (app_icon == "") {
            if (app_info != null) {
                app_icon = app_info.get_icon ().to_string ();
            } else {
                app_icon = "dialog-information";
            }
        }
    }
}
