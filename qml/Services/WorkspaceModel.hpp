
#include <qabstractitemmodel.h>
#include <qjsonarray.h>
#include <qjsonobject.h>
#include <qjsonvalue.h>
#include <qlist.h>
#include <qobject.h>
#include <qtypes.h>
#include <qstring.h>
#include <QAbstractListModel>
#include "logger.hpp"


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

class WorkspaceModel : public QAbstractListModel {
    Q_OBJECT

    Q_PROPERTY(int activeWorkspaceIndex READ activeWorkspaceIndex NOTIFY activeWorkspaceChanged)
    Q_PROPERTY(int activeWindowIndex READ activeWindowIndex NOTIFY activeWindowChanged)
    Q_PROPERTY(QString focusedAppId READ focusedAppId NOTIFY focusedWindowChanged)
    Q_PROPERTY(QString focusedWindowTitle READ focusedWindowTitle NOTIFY focusedWindowChanged)

    enum Roles {
        IdRoles = Qt::UserRole + 1,
        NameRole,
        IndexRole,
        IsFocusedRole,
        IsActiveRole,
        OutputRole,
        WindowCountRole,
        Windows
    };

    public :
        explicit WorkspaceModel(QObject *parent = nullptr);
        ~WorkspaceModel() override = default;
        Logger &logger = Logger::getInstance();
        int rowCount(const QModelIndex &parent = QModelIndex()) const override;
        QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
        QHash<int, QByteArray> roleNames() const override;

        int activeWorkspaceIndex() const { return m_activeWorkspaceIndex; }
        int activeWindowIndex() const { return m_activeWindowIndex; }
        QString focusedWindowTitle() const { return m_focusedWindow.title; }
        QString focusedAppId() const {  return m_focusedWindow.app_id; }

    public slots:
        void handleEvent(const QJsonObject &event);
        void handleReply(const QJsonObject &reply);

    signals:
        void activeWindowChanged();
        void activeWorkspaceChanged();
        void focusedWindowChanged();

    private:
        void parseWorkspaces(const QJsonArray &array);
        void workspaceChangedEvnHandler(const QJsonArray &event);
        void windowsChangedEvnHandler(const QJsonArray &event);
        void workspaceActivatedEvnHandler(const QJsonObject &event);
        void windowFocusChangedEvnHandler();
        void windowFocusChangedEvnHandler(const QJsonObject &event);
        void parseWindows(const QJsonArray &array);
        void updateFocusedWindow(const std::uint64_t id);

        QList<WorkspaceInfo> m_workspaces;
        QList<WindowInfo> m_windows;
        WindowInfo m_focusedWindow;
        int m_activeWorkspaceIndex = -1;
        int m_activeWindowIndex = -1;
};
