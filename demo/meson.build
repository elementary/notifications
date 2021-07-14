executable(
    'io.elementary.notifications.demo',
    'Application.vala',
    'MainWindow.vala',
    dependencies : [
        dependency ('granite'),
        dependency ('gtk+-3.0'),
        dependency ('libnotify'),
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
