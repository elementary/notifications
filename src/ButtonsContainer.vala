/*
 * Copyright 2025 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Notifications.ButtonsContainer : Gtk.Widget {
    private const int SPACING = 6;

    class construct {
        set_css_name ("buttonbox");
    }

    construct {
        layout_manager = new Gtk.CustomLayout (
            (widget) => HEIGHT_FOR_WIDTH,
            (widget, orientation, for_size, out minimum, out natural, out minimum_baseline, out natural_baseline) => {
                minimum_baseline = -1;
                natural_baseline = -1;

                if (orientation == HORIZONTAL) {
                    var max_min_w = 0, sum_nat_w = 0, visible_count = 0;

                    for (unowned var child = widget.get_first_child (); child != null; child = child.get_next_sibling ()) {
                        if (!child.visible) {
                            continue;
                        }

                        visible_count++;

                        int child_min, child_nat;
                        child.measure (orientation, for_size, out child_min, out child_nat, null, null);

                        max_min_w = int.max (max_min_w, child_min);
                        sum_nat_w += child_nat;
                    }

                    sum_nat_w += SPACING * (visible_count - 1);

                    minimum = max_min_w;
                    natural = sum_nat_w;
                } else {
                    // We need to compute total height after wrapping
                    // 'for_size' here is the available width for wrapping
                    minimum = compute_wrapped_size_height (widget, for_size, false);
                    natural = compute_wrapped_size_height (widget, for_size, true);
                }
            },
            (widget, width, height, baseline) => {
                var row_y = 0, row_height = 0, row_used_width = 0;
                var row = new GLib.List<Gtk.Widget> ();

                for (unowned var child = widget.get_first_child (); child != null; child = child.get_next_sibling ()) {
                    if (!child.visible) {
                        continue;
                    }

                    int child_min_w, child_nat_w, child_min_h, child_nat_h;
                    child.measure (HORIZONTAL, -1, out child_min_w, out child_nat_w, null, null);
                    child.measure (VERTICAL, -1, out child_min_h, out child_nat_h, null, null);

                    if (row.length () > 0 && row_used_width + child_nat_w > width) {
                        var total_row_width = 0;
                        foreach (var row_child in row) {
                            int nat_w;
                            row_child.measure (HORIZONTAL, -1, null, out nat_w, null, null);
                            total_row_width += nat_w <= width ? nat_w : width;
                        }
                        total_row_width += SPACING * ((int) row.length() - 1);

                        // Set starting x so the row is right-aligned
                        var row_x = width - total_row_width;

                        // Allocate children left-to-right
                        foreach (var row_child in row) {
                            int nat_w, nat_h;
                            row_child.measure (HORIZONTAL, -1, null, out nat_w, null, null);
                            row_child.measure (VERTICAL, -1, null, out nat_h, null, null);

                            var w = nat_w <= total_row_width ? nat_w : total_row_width;

                            row_child.allocate (w, nat_h, baseline, new Gsk.Transform ().translate({ row_x, row_y }));

                            row_x += w + SPACING;
                        }

                        row_y += row_height + SPACING;
                        row_height = 0;
                        row_used_width = 0;
                        row = new GLib.List<Gtk.Widget> ();
                    }

                    row.append (child);
                    row_used_width += child_nat_w;
                    row_height = int.max (row_height, child_nat_h);
                }

                if (row.length () > 0) {
                    var total_row_width = 0;
                    foreach (var row_child in row) {
                        int nat_w;
                        row_child.measure (HORIZONTAL, -1, null, out nat_w, null, null);
                        total_row_width += nat_w <= width ? nat_w : width;
                    }
                    total_row_width += SPACING * ((int) row.length() - 1);

                    // Set starting x so the row is right-aligned
                    var row_x = width - total_row_width;

                    // Allocate children left-to-right
                    foreach (var row_child in row) {
                        int nat_w, nat_h;
                        row_child.measure (HORIZONTAL, -1, null, out nat_w, null, null);
                        row_child.measure (VERTICAL, -1, null, out nat_h, null, null);

                        var w = nat_w <= width ? nat_w : width;

                        row_child.allocate(w, nat_h, baseline, new Gsk.Transform().translate({ row_x, row_y }));

                        row_x += w + SPACING;
                    }
                }
            }
        );
    }

    public void append (Gtk.Widget child) {
        child.insert_after (this, get_last_child ());
    }

    private static int compute_wrapped_size_height (Gtk.Widget widget, int width, bool natural) {
        var row_used = 0, row_height = 0, total_height = 0;
        for (unowned var child = widget.get_first_child (); child != null; child = child.get_next_sibling ()) {
            if (!child.visible) {
                continue;
            }

            int child_min_w, child_nat_w, child_min_h, child_nat_h;
            child.measure (HORIZONTAL, -1, out child_min_w, out child_nat_w, null, null);
            child.measure (VERTICAL, -1, out child_min_h, out child_nat_h, null, null);

            var cw = natural ? child_nat_w : child_min_w;
            var ch = natural ? child_nat_h : child_min_h;

            var prospective = row_used == 0 ? cw : row_used + SPACING + cw;

            // If the child doesn't fit in the current row and it's not the first in row -> wrap
            if (row_used > 0 && prospective > width) {
                total_height += row_height + SPACING;
                row_used = 0;
                row_height = 0;
            }

            if (row_used == 0) {
                row_used = cw;
            } else {
                row_used += SPACING + cw;
            }

            row_height = int.max (row_height, ch);
        }

        total_height += row_height;

        return total_height;
    }
}
