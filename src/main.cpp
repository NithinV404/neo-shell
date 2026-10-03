#include "ipc/niri.h"
#include <logger/logger.h>
#include "qml/Services/Clock.h"
#include "qml/Services/Compositor.h"
#include "qml/Services/ThemeManager.h"
#include "qml/Services/WorkspaceModel.h"
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQmlEngine>
#include <QQuickWindow>
#include <qquickwindow.h>
#include <qsgrendererinterface.h>

neoshell::Logger *g_logger = nullptr;
void qtMessageHandler(QtMsgType type, const QMessageLogContext &, const QString &str) {
  std::string text = str.toStdString();
  switch (type) {
  case QtDebugMsg: g_logger->debug(text); break;
  case QtInfoMsg: g_logger->info(text); break;
  case QtWarningMsg: g_logger->warning(text); break;
  case QtCriticalMsg: g_logger->critical(text); break;
  case QtFatalMsg: g_logger->error(text); break;
  }
}

int main(int argc, char *argv[]) {
  auto &logger = neoshell::Logger::getInstance();
  g_logger = &logger;
  qInstallMessageHandler(qtMessageHandler);

  QGuiApplication app(argc, argv);
  QQmlApplicationEngine engine;
  Compositor comp;

  ThemeManager theme;
  WorkspaceModel workspaceModel;
  ClockService clock;
  NiriIpc *niri = nullptr;
  if (comp.detectCompositor() == CompositorType::Niri) {
    niri = new NiriIpc(&app);
    QObject::connect(niri, &NiriIpc::replyReceived, &workspaceModel, &WorkspaceModel::handleReply);
    QObject::connect(niri, &NiriIpc::eventReceived, &workspaceModel, &WorkspaceModel::handleEvent);

    if (niri->connectToNiri()) {
      niri->requestWorkspaces();
      niri->startEventStream();
    }
  }

  qmlRegisterSingletonInstance<ThemeManager>("Shell.Services", 1, 0, "Theme", &theme);
  qmlRegisterSingletonInstance<WorkspaceModel>("Shell.Services", 1, 0, "NiriWorkspaces", &workspaceModel);
  qmlRegisterSingletonInstance<ClockService>("Shell.Services", 1, 0, "ClockService", &clock);


  theme.loadWallpaperColors("/mnt/vault/Pictures/Wallpapers/wallhaven-ly8l7p_3840x2160.png", true);

  engine.loadFromModule("Shell", "Main");


  if (engine.rootObjects().isEmpty()) {
    logger.error("Failed to load QML root object");
    return -1;
  }

  logger.info("Loaded the engine successfully");
  // We don't need to grab the window here anymore!
  // The QML PanelWindow element will handle its own anchors and layer!

  return app.exec();
}
