
#include "logger.h"
#include <QAbstractListModel>
#include <QJsonObject>
#include <QJsonArray>

struct WindowInfo {
  Q_GADGET
  Q_PROPERTY(int id MEMBER id)
  Q_PROPERTY(QString app_id MEMBER app_id)
  Q_PROPERTY(QString title MEMBER title)
  Q_PROPERTY(bool is_floating MEMBER is_floating)
  Q_PROPERTY(bool is_focused MEMBER is_focused)
  Q_PROPERTY(bool is_urgent MEMBER is_urgent)
  Q_PROPERTY(qint64 pid MEMBER pid)
  Q_PROPERTY(quint64 workspace_id MEMBER workspace_id)

public:
  int id = 0;
  QString app_id;
  QString title;
  bool is_floating = false;
  bool is_focused = false;
  bool is_urgent = false;
  qint64 pid = 0;
  quint64 workspace_id = 0;
};

struct WorkspaceInfo {
  quint16 id;
  quint16 idx;
  quint16 active_window_id;
  QString name;
  bool is_focused;
  bool is_urgent;
  bool is_active;
  QString output;
};

class WindowModel : public QAbstractListModel {
  Q_OBJECT

  enum Roles {
    TitleRole = Qt::UserRole + 1,
    AppIdRole,
    IsFocusedRole,
    IsFloatingRule,
    WorkspaceIdRole
  };

public:
  explicit WindowModel(QObject *parent) : QAbstractListModel(parent) {}
  void updateFocusedWindow(const std::uint64_t id);
  QList<WindowInfo>& windows();
  QVariant data(const QModelIndex &index, int role) const override;
  int rowCount(const QModelIndex &parent = QModelIndex()) const override;
  QHash<int, QByteArray> roleNames() const override;
  void replaceAll(const QList<WindowInfo> &windows);
  void updateOrAppend(const QJsonObject &obj);

private:
  QList<WindowInfo> m_windows;
};


class WorkspaceModel : public QAbstractListModel {
  Q_OBJECT

  Q_PROPERTY(int activeWorkspaceIndex READ activeWorkspaceIndex NOTIFY
                 activeWorkspaceChanged)
  Q_PROPERTY(
      int activeWindowIndex READ activeWindowIndex NOTIFY activeWindowChanged)
  Q_PROPERTY(QString focusedAppId READ focusedAppId NOTIFY focusedWindowChanged)
  Q_PROPERTY(QString focusedWindowTitle READ focusedWindowTitle NOTIFY
                 focusedWindowChanged)
  Q_PROPERTY(WindowModel* windowModel READ windowModel CONSTANT)

  enum Roles {
    IdRoles = Qt::UserRole + 1,
    NameRole,
    IndexRole,
    IsFocusedRole,
    IsActiveRole,
    OutputRole,
  };

public:
  explicit WorkspaceModel(QObject *parent = nullptr);
  ~WorkspaceModel() override = default;
  neoshell::Logger &logger = neoshell::Logger::getInstance();
  int rowCount(const QModelIndex &parent = QModelIndex()) const override;
  QVariant data(const QModelIndex &index,
                int role = Qt::DisplayRole) const override;
  QHash<int, QByteArray> roleNames() const override;

  WindowModel* windowModel() const { return m_windowModel; };
  int activeWorkspaceIndex() const { return m_activeWorkspaceIndex; }
  int activeWindowIndex() const { return m_activeWindowIndex; }
  QString focusedWindowTitle() const { return m_focusedWindow.title; }
  QString focusedAppId() const { return m_focusedWindow.app_id; }

public slots:
  void handleEvent(const QJsonObject &event);
  void handleReply(const QJsonObject &reply);

signals:
  // void windowsChanged();
  // void workspacesChanged();
  void activeWindowChanged();
  void activeWorkspaceChanged();
  void focusedWindowChanged();

private:
  void parseWorkspaces(const QJsonArray &array);
  void workspacesChangedEvnHandler(const QJsonArray &event);
  void windowsChangedEvnHandler(const QJsonArray &event);
  void workspaceActivatedEvnHandler(const QJsonObject &event);
  void windowFocusChangedEvnHandler(const QJsonObject &event);
  void windowOpenedOrChangedEvnHandler(const QJsonObject &event);
  void windowClosedEvnHandler(const std::int64_t &id);
  void workspaceActiveWindowChangedEvnHandler(const QJsonObject &event);
  void parseWindows(const QJsonArray &array);
  void updateFocusedWindow(const std::uint64_t id);

  QList<WorkspaceInfo> m_workspaces;
  WindowModel* m_windowModel;
  WindowInfo m_focusedWindow;
  int m_activeWorkspaceIndex = -1;
  int m_activeWindowIndex = -1;
};
