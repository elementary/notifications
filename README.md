# Notifications
[![Translation status](https://l10n.elementary.io/widgets/desktop/-/notifications-extra/svg-badge.svg)](https://l10n.elementary.io/engage/desktop/?utm_source=widget)

a Gtk notification server for Pantheon

## Building, Testing, and Installation

You'll need the following dependencies:
* libcanberra
* libgranite-dev (>=5)
* libgtk-4-dev
* libadwaita-1-dev
* meson
* valac

Run `meson build` to configure the build environment. Change to the build directory and run `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`, then execute with `io.elementary.notifications`

    ninja install
    io.elementary.notifications
