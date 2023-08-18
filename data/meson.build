install_data(
    'autostart.desktop',
    rename: meson.project_name() + '.desktop',
    install_dir: get_option('sysconfdir') / 'xdg' / 'autostart'
)

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
