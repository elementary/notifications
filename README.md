# Notifications
[![Translation status](https://l10n.elementary.io/widgets/desktop/-/notifications-extra/svg-badge.svg)](https://l10n.elementary.io/engage/desktop/?utm_source=widget)

a Gtk notification server for Pantheon

## Building, Testing, and Installation

You'll need the following dependencies:
* libcanberra
* libgranite-7-dev (>=7.7.0)
* libgtk-4-dev
* libadwaita-1-dev (>=1.0.0)
* meson
* valac

Run `meson build` to configure the build environment. Change to the build directory and run `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`, then execute with `io.elementary.notifications`

    ninja install
    io.elementary.notifications
