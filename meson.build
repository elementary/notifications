project(
    'io.elementary.notifications',
    'vala', 'c',
    version: '1.0.0'
)

gnome = import('gnome')
i18n = import('i18n')
prefix = get_option('prefix')
datadir = join_paths(prefix, get_option('datadir'))
libdir = join_paths(prefix, get_option('libdir'))

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')
add_project_arguments(['--vapidir', join_paths(meson.current_source_dir(), 'vapi')], language: 'vala')

server_gresource = gnome.compile_resources(
    'server-resource',
    join_paths('data', 'notifications.gresource.xml'),
    source_dir: 'data'
)

plug_gresource = gnome.compile_resources(
    'plug-resource',
    join_paths('data', 'plug.gresource.xml'),
    source_dir: 'data'
)

subdir('data')
subdir('demo')
subdir('src')
subdir('po')

meson.add_install_script('meson/post_install.py')
