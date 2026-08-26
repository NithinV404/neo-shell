#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlEngine>
#include <QQmlContext>
#include <LayerShellQt/Window>
#include <qjsonobject.h>
#include <qobject.h>
#include "Utils/logger.hpp"
#include "qml/Services/Compositor.hpp"
#include "qml/Services/ThemeManager.hpp"
#include "qml/Services/WorkspaceModel.hpp"
#include "Ipc/niri.hpp"

Logger *g_logger = nullptr;
void qtMessageHandler(QtMsgType type, const QMessageLogContext &, const QString &str) {
    std::string text = str.toStdString();
    switch (type) {
        case QtDebugMsg:
            g_logger->debug(text);
            break;
        case QtInfoMsg:
            g_logger->info(text);
            break;
        case QtWarningMsg:
            g_logger->warning(text);
            break;
        case QtCriticalMsg:
            g_logger->critical(text);
            break;
        case QtFatalMsg:
            g_logger->error(text);
            break;
    }
}

int main(int argc, char *argv[]) {

    auto &logger = Logger::getInstance();
    g_logger = &logger;
    qInstallMessageHandler(qtMessageHandler);

    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;
    WorkspaceModel workspaceModel;
    Compositor comp;
    NiriIpc *niri = nullptr;
    if(comp.detectCompositor() == CompositorType::Niri)
    {
        niri = new NiriIpc(&app);
        // Route Niri IPC responses to the workspace model
        QObject::connect(niri, &NiriIpc::replyReceived, &workspaceModel, &WorkspaceModel::handleReply);
        QObject::connect(niri, &NiriIpc::eventReceived, &workspaceModel, &WorkspaceModel::handleEvent);

        // Register model in QML context

        if (niri->connectToNiri()) {
            niri->requestWorkspaces();  // Get initial snapshot
            niri->startEventStream();   // Subscribe to live changes
        }
    }

    engine.rootContext()->setContextProperty("NiriWorkspaces", &workspaceModel);
    engine.loadFromModule("Shell", "Bar");
    logger.info("Loaded the engine successfully");

    if(engine.rootObjects().isEmpty()){
        logger.error("Failed to load QML root object");
        return -1;
    }

    auto *theme = engine.singletonInstance<ThemeManager*>("Shell.Services", "ThemeManager");
    if (theme) theme->loadWallpaperColors("/mnt/vault/Pictures/Wallpapers/wallhaven-oglrv9_3840x2160.png", true);

    auto *window = qobject_cast<QWindow*>(engine.rootObjects().first());
    auto *layerwindow = LayerShellQt::Window::get(window);

    layerwindow->setLayer(LayerShellQt::Window::LayerTop);

    layerwindow->setAnchors(
    LayerShellQt::Window::Anchors(
        LayerShellQt::Window::AnchorLeft |
        LayerShellQt::Window::AnchorRight |
        LayerShellQt::Window::AnchorTop
        )
    );
    layerwindow->setExclusiveZone(48);
    layerwindow->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityOnDemand);
    layerwindow->setScope(QStringLiteral("panel"));
    layerwindow->activateOnShow();



    window->show();
    return app.exec();
}
