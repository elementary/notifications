project(
    'io.elementary.notifications', 'vala', 'c',
    version: '8.0.0',
    meson_version : '>= 0.57'
)

gnome = import('gnome')
i18n = import('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')
add_project_arguments(['--vapidir', join_paths(meson.current_source_dir(), 'vapi')], language: 'vala')

css_gresource = gnome.compile_resources(
    'css-resource',
    join_paths('data', 'notifications.gresource.xml'),
    source_dir: 'data'
)

executable(
    meson.project_name(),
    'src/AbstractBubble.vala',
    'src/Application.vala',
    'src/Bubble.vala',
    'src/Confirmation.vala',
    'src/DBus.vala',
    'src/FdoActionGroup.vala',
    'src/Notification.vala',
    'src/Widgets/MaskedImage.vala',
    css_gresource,
    dependencies: [
        dependency ('libcanberra'),
        dependency ('libcanberra-gtk3'),
        dependency ('glib-2.0'),
        dependency ('gobject-2.0'),
        dependency ('gio-2.0'),
        dependency ('granite', version: '>=5.4.0'),
        dependency ('gtk+-3.0'),
        dependency ('libhandy-1')
    ],
    install : true
)

subdir('data')
subdir('demo')
subdir('po')

gnome.post_install(glib_compile_schemas: true)
