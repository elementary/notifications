plug_files = files(
    'Plug.vala',
    'Widgets/Sidebar.vala',
    'Widgets/SettingsOption.vala',
    'Widgets/MainView.vala',
    'Widgets/AppSettingsView.vala',
    'Widgets/AppEntry.vala',
    'Backend/NotifyManager.vala',
    'Backend/App.vala'
)

glib_dep = dependency ('glib-2.0')
granite_dep = dependency ('granite', version: '>=5.4.0')
gobject_dep = dependency ('gobject-2.0')
gtk_dep = dependency ('gtk+-3.0')
switchboard_dep = dependency('switchboard-2.0')
switchboard_plugsdir = switchboard_dep.get_pkgconfig_variable('plugsdir', define_variable: ['libdir', libdir])

shared_module(
    meson.project_name(),
    plug_files,
    plug_gresource,
    dependencies: [
        dependency('gio-2.0'),
        glib_dep,
        gobject_dep,
        granite_dep,
        gtk_dep,
        switchboard_dep,
    ],
    install: true,
    install_dir : join_paths(switchboard_plugsdir, 'personal')
)

executable(
    meson.project_name(),
    'AbstractBubble.vala',
    'Application.vala',
    'Bubble.vala',
    'Confirmation.vala',
    'DBus.vala',
    'Notification.vala',
    'Widgets/MaskedImage.vala',
    server_gresource,
    dependencies: [
        dependency ('libcanberra'),
        dependency ('libcanberra-gtk3'),
        dependency ('libhandy-1'),
        glib_dep,
        gobject_dep,
        granite_dep,
        gtk_dep
    ],
    install : true
)
