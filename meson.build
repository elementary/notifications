project('io.elementary.notifications', 'vala', 'c')

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
    'src/Application.vala',
    'src/Notification.vala',
    css_gresource,
    dependencies: [
        dependency ('libcanberra'),
        dependency ('libcanberra-gtk3'),
        dependency ('glib-2.0'),
        dependency ('gobject-2.0'),
        dependency ('granite', version: '>=0.5'),
        dependency ('gtk+-3.0'),
    ],
    install : true
)

subdir('data')
# subdir('po')

