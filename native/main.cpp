// omarchy-about — tiny native launcher whose only job is to give the QML card
// a STABLE Wayland app_id (com.omarchy.about) so that:
//   * the keybinding can focus an existing window instead of opening a new one,
//   * Hyprland window rules can target it by class (the generic `qml` runtime
//     reports `org.qt-project.qml`, which every Qt/QML app shares).
//
// It is intentionally minimal: it sets the desktop file name (== app_id under
// Wayland), then loads the SAME share/omarchy-about/main.qml the script uses.
// The QML path is passed via $OMARCHY_ABOUT_QML; every other argument (the data
// JSON and an optional --shot=PATH) is forwarded untouched so Qt.application.
// arguments sees exactly what it did under `qml6 ... -- args`.
//
// Build:  g++ -std=c++17 -fPIC native/main.cpp -o build/omarchy-about-bin \
//             $(pkg-config --cflags --libs Qt6Gui Qt6Qml)

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QString>
#include <QByteArray>
#include <QUrl>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // Identity. Under Wayland, the xdg-shell app_id is taken from the desktop
    // file name, so this is what makes the window's class stable & unique.
    // NB: we deliberately do NOT set applicationDisplayName — Qt would append
    // it to every window title (" — About This PC"); the QML sets its own title.
    app.setApplicationName(QStringLiteral("omarchy-about"));
    app.setDesktopFileName(QStringLiteral("com.omarchy.about"));

    const QByteArray qml = qgetenv("OMARCHY_ABOUT_QML");
    if (qml.isEmpty()) {
        qWarning("omarchy-about: OMARCHY_ABOUT_QML is not set");
        return 2;
    }

    QQmlApplicationEngine engine;
    engine.load(QUrl::fromLocalFile(QString::fromLocal8Bit(qml)));
    if (engine.rootObjects().isEmpty()) {
        qWarning("omarchy-about: failed to load %s", qml.constData());
        return 1;
    }
    return app.exec();
}
