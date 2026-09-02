icon_sizes = ['32', '48']

foreach i : icon_sizes
    install_data(
        join_paths('icons', 'app', i + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i, 'apps'),
        rename: meson.project_name() + '.svg'
    )
    install_data(
        join_paths('icons', 'app', i + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i + '@2', 'apps'),
        rename: meson.project_name() + '.svg'
    )
endforeach

install_data(
    'notifications.gschema.xml',
    rename: meson.project_name() + '.gschema.xml',
    install_dir: get_option('prefix') / get_option('datadir') / 'glib-2.0' / 'schemas'
)

i18n.merge_file(
    input: 'notifications.metainfo.xml.in',
    output: meson.project_name() + '.metainfo.xml',
    po_dir: meson.project_source_root() / 'po' / 'extra',
    type: 'xml',
    install: true,
    install_dir: get_option('datadir') / 'metainfo',
)
