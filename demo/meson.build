executable(
    'io.elementary.notifications.demo',
    'Application.vala',
    'MainWindow.vala',
    dependencies : [
        dependency ('granite-7'),
        dependency ('gtk4'),
    ],
    install : true
)

applications_dir = join_paths(
    get_option('prefix'),
    get_option('datadir'),
    'applications'
)

install_data(
    'io.elementary.notifications.demo.desktop',
    install_dir: applications_dir
)
