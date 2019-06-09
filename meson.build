project('io.elementary.notifications', 'vala', 'c')

gnome = import('gnome')
i18n = import('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

css_gresource = gnome.compile_resources(
    'css-resource',
    join_paths('data', 'notifications.gresource.xml'),
    source_dir: 'data'
)

executable(
    meson.project_name(),
    'src/Application.vala',
    'src/MainWindow.vala',
    css_gresource,
    dependencies: [
        dependency ('glib-2.0'),
        dependency ('gobject-2.0'),
        dependency ('granite', version: '>=0.5'),
        dependency ('gtk+-3.0'),
    ],
    install : true
)

subdir('data')
# subdir('po')

