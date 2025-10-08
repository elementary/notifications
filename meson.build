project(
    'io.elementary.notifications', 'vala', 'c',
    version: '8.0.0',
    meson_version : '>= 0.57'
)

gnome = import('gnome')
i18n = import('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

css_gresource = gnome.compile_resources(
    'css-resource',
    join_paths('data', 'notifications.gresource.xml'),
    source_dir: 'data'
)

subdir('protocol')

executable(
    meson.project_name(),
    'src/AbstractBubble.vala',
    'src/Application.vala',
    'src/Bubble.vala',
    'src/CanberraGtk4.vala',
    'src/Confirmation.vala',
    'src/DBus.vala',
    'src/FdoActionGroup.vala',
    'src/Notification.vala',
    'src/PortalProxy.vala',
    'src/Widgets/MaskedImage.vala',
    css_gresource,
    dependencies: [
        dependency ('libcanberra'),
        dependency ('glib-2.0'),
        dependency ('gobject-2.0'),
        dependency ('gio-2.0'),
        dependency ('granite-7', version: '>=7.7.0'),
        dependency ('gtk4'),
        dependency('gtk4-wayland'),
        dependency('gtk4-x11'),
        dependency ('gtk4-x11'),
        dependency ('libadwaita-1'),
        dependency('wayland-client'),
        pantheon_desktop_shell_dep
    ],
    install : true
)

subdir('data')
subdir('demo')
subdir('po')

gnome.post_install(glib_compile_schemas: true)
