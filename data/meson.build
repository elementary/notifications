install_data(
    'autostart.desktop',
    rename: meson.project_name() + '.desktop',
    install_dir: join_paths(get_option('sysconfdir'), 'xdg', 'autostart')
)

i18n.merge_file(
    input: 'notifications.appdata.xml.in',
    output: meson.project_name() + '.appdata.xml',
    po_dir: join_paths(meson.source_root(), 'po', 'extra'),
    type: 'xml',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'metainfo'),
)
