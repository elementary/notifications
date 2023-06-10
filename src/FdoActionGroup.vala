/*
 * Copyright 2023 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Author: Gustavo Marques <pushstarttocontinue@outlook.com>
 */

// RefString don't subclass string in vala, however they ctype is char*
namespace GLib {
    [CCode (cname = "g_str_hash", cheader_filename = "glib.h")]
    public extern uint ref_str_hash (RefString v);
    [CCode (cname = "g_str_equal", cheader_filename = "glib.h")]
    public extern bool ref_str_equal (RefString v1, RefString v2);
}

/**
 * A implementation of GLib.ActionGroup meant to be used by external programs
 * to trigger the signals in the org.freedesktop.Notifications interface.
 *
 * notification actions follow the "id.action" format, a "close(@au ids)" action
 * exist to trigger the NotificationClosed signal.
 */
public sealed class Notifications.Fdo.ActionGroup : Object, GLib.ActionGroup {
    private Gee.Collection<RefString> actions;
    private unowned Server server;

    private static VariantType close_parameter_type = new VariantType.array (VariantType.UINT32);

    public ActionGroup (Server server) {
        this.actions = new Gee.HashSet<RefString> (ref_str_hash, ref_str_equal);
        this.server = server;

        actions.add (new RefString.intern ("close"));
    }

    public unowned string add_action (uint32 id, string action) {
        var action_name = new RefString.intern (@"$id.$action");

        if (actions.add (action_name)) {
            action_added (action_name.to_string ());
        }

        return action_name.to_string ();
    }

    public void remove_actions (uint32 id) {
        var iter = actions.iterator ();
        var prefix = id.to_string ();

        while (iter.next ()) {
            var action = iter.get ().to_string ();
            if (!action.has_prefix (prefix)) {
                continue;
            }

            action_removed (action);
            iter.remove ();
        }
    }

    // GLib.ActionGroup impl
    public override bool query_action (
        string action_name,
        out bool enabled,
        out VariantType parameter_type,
        out VariantType state_type,
        out Variant state_hint,
        out Variant state
    ) {
        parameter_type = state_type = null;
        state_hint = state = null;
        enabled = action_name in (Gee.Collection<string>) actions;

        if (action_name == "close") {
            parameter_type = close_parameter_type;
        }

        return enabled;
    }

    public string[] list_actions () {
        var builder = new StrvBuilder ();

        foreach (var action in actions) {
            builder.add (action.to_string ().dup ());
        }

        return builder.end ();
    }

    public void activate_action (string action, Variant? target)
    requires (has_action (action)) {
        if (action == "close") {
            var iter = target.iterator ();
            uint32 id;

            while (iter.next ("u", out id)) {
                server.notification_closed (id, Server.CloseReason.DISMISSED);
            }

            return;
        }

        string action_name;
        uint32 id;

        uint.try_parse (action, out id, out action_name);
        if (id == 0) {
            warning ("failed to activate action '%s': failed to parse notification id", action);
            return;
        }

        debug ("activating action '%s' for notification id '%u'", action_name[1:], id);
        server.action_invoked (id, action_name[1:]);
    }

    public void change_action_state (string action_name, Variant @value) {
    }

    /* GLib says that we are only meant to override list_actions and query_actions,
    * however, the gio bindings only have query_action marked as virtual.
    *
    * FIXME: remove everthing below when we have valac 0.58 as minimal version.
    */
    public bool has_action (string action_name) {
        return action_name in (Gee.Collection<string>) actions;
    }

    public bool get_action_enabled (string action_name) {
        return has_action (action_name);
    }

    public unowned VariantType? get_action_parameter_type (string action_name) {
        if (action_name == "close") {
            return close_parameter_type;
        }

        return null;
    }

    public unowned VariantType? get_action_state_type (string action_name) {
        return null;
    }

    public Variant? get_action_state_hint (string action_name) {
        return null;
    }

    public Variant? get_action_state (string action_name) {
        return null;
    }
}
