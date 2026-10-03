#include "WorkspaceModel.h"

WorkspaceModel::WorkspaceModel(QObject *parent) : QAbstractListModel(parent), m_windowModel(new WindowModel(this)) {};

int WorkspaceModel::rowCount(const QModelIndex &parent) const {
  if (parent.isValid()) {
    return 0;
  }
  return m_workspaces.count();
};

QVariant WorkspaceModel::data(const QModelIndex &index, int role) const {
  if (!index.isValid() || index.row() < 0 ||
      index.row() >= m_workspaces.count()) {
    return QVariant();
  }

  const auto &ws = m_workspaces.at(index.row());
  switch (role) {
  case IdRoles:
    return QVariant::fromValue(ws.id);
  case NameRole:
    return ws.name;
  case IndexRole:
    return ws.idx;
  case IsFocusedRole:
    return ws.is_focused;
  case IsActiveRole:
    return ws.is_active;
  case OutputRole:
    return ws.output;
  default:
    return QVariant();
  }
};

QHash<int, QByteArray> WorkspaceModel::roleNames() const {
  return {
      {IdRoles, "wsId"},          {NameRole, "wsName"},
      {IndexRole, "wsIndex"},     {IsFocusedRole, "isFocused"},
      {IsActiveRole, "isActive"}, {OutputRole, "output"},
  };
};

void WorkspaceModel::handleEvent(const QJsonObject &event) {
  if (event.contains("WorkspacesChanged")) {
    workspacesChangedEvnHandler(
        event["WorkspacesChanged"]["workspaces"].toArray());
  } else if (event.contains("WindowsChanged")) {
    windowsChangedEvnHandler(
        event["WindowsChanged"].toObject()["windows"].toArray());
  } else if (event.contains("WorkspaceActivated")) {
    workspaceActivatedEvnHandler(event["WorkspaceActivated"].toObject());
  } else if (event.contains("WindowFocusChanged")) {
    windowFocusChangedEvnHandler(event["WindowFocusChanged"].toObject());
  } else if (event.contains("WindowOpenedOrChanged")) {
    windowOpenedOrChangedEvnHandler(event["WindowOpenedOrChanged"]["window"].toObject());
  } else if (event.contains("WindowClosed")) {
      windowClosedEvnHandler(event["WindowClosed"]["id"].toInt());
  } else if (event.contains("WorkspaceActiveWindowChanged")) {
      workspaceActiveWindowChangedEvnHandler(event["WorkspaceActiveWindowChanged"].toObject());
  }
};

void WorkspaceModel::handleReply(const QJsonObject &reply) {
  if (reply.contains("Ok")) {
    QJsonValue okVal = reply["Ok"];
    if (okVal.toObject().contains("Workspaces")) {
      parseWorkspaces(okVal.toObject()["Workspaces"].toArray());
    }
  }
};

void WorkspaceModel::workspacesChangedEvnHandler(const QJsonArray &event) {
  parseWorkspaces(event);
}

void WorkspaceModel::windowsChangedEvnHandler(const QJsonArray &event) {
  parseWindows(event);
}

void WorkspaceModel::workspaceActivatedEvnHandler(const QJsonObject &event) {
  quint64 id = event["id"].toInteger();
  bool focused = event["focused"].toBool();
  for (int i = 0; i < m_workspaces.size(); ++i) {
    bool nowActive = (m_workspaces[i].id == id);
    bool nowFocused = (m_workspaces[i].id == id && focused);
    if (m_workspaces[i].is_active != nowActive) {
      m_workspaces[i].is_active = nowActive;
      if (nowActive) {
        m_activeWorkspaceIndex = i;
        emit activeWorkspaceChanged();
      }
      emit dataChanged(createIndex(i, 0), createIndex(i, 0), {IsActiveRole});
    }
    if (m_workspaces[i].is_focused != nowFocused) {
      m_workspaces[i].is_focused = nowFocused;
      emit dataChanged(createIndex(i, 0), createIndex(i, 0), {IsFocusedRole});
    }
  }
}

void WorkspaceModel::windowFocusChangedEvnHandler(const QJsonObject &event) {
  auto &obj = event;
  if (obj["id"].isNull()) {
    m_focusedWindow = {};
    updateFocusedWindow(-1);
    emit focusedWindowChanged();
  } else {
    updateFocusedWindow(obj["id"].toInteger());
  }
}

void WorkspaceModel::windowOpenedOrChangedEvnHandler(const QJsonObject &event) {
  const uint64_t id = event["id"].toInteger();
  bool found = false;
  QList<WindowInfo> &m_windows = windowModel()->windows();
  for (WindowInfo &window : m_windows) {
    if (window.id == id) {
      window.app_id = event["app_id"].toString();
      window.title = event["title"].toString();
      window.workspace_id = event["workspace_id"].toInteger();
      window.is_focused = event["is_focused"].toBool();
      window.is_floating = event["is_floating"].toBool();
      window.is_urgent = event["is_urgent"].toBool();
      if (window.is_focused) {
        m_focusedWindow = window;
        emit focusedWindowChanged();
      }
      found = true;
      break;
    }
  }
  if(!found) {
      WindowInfo wn;
      wn.id = id;
      wn.title = event["title"].toString();
      wn.app_id = event["app_id"].toString();
      wn.pid = event["pid"].toInteger();
      wn.workspace_id = event["workspace_id"].toInteger();
      wn.is_focused = event["is_focused"].toBool();
      wn.is_floating = event["is_floating"].toBool();
      wn.is_urgent = event["is_urgent"].toBool();

      m_windows.append(wn);

      if (wn.is_focused) {
        m_focusedWindow = wn;
        emit focusedWindowChanged();
      }
  }
}

void WorkspaceModel::windowClosedEvnHandler(const std::int64_t &id) {
    QList<WindowInfo> &m_windows = windowModel()->windows();
    for(int i=0; i<m_windows.size(); ++i) {
        if(m_windows[i].id == id)
        {
            m_windows.removeAt(i);
        }
    }
}

void WorkspaceModel::workspaceActiveWindowChangedEvnHandler(const QJsonObject &event) {
    uint64_t workspace_id = event["workspace_id"].toInteger();
    uint64_t active_window_id = event["active_window_id"].toInteger();

    for(WorkspaceInfo &workspace: m_workspaces) {
        if(workspace.id == workspace_id) {
            workspace.active_window_id = active_window_id;
            updateFocusedWindow(active_window_id);
        }
    }
}

void WorkspaceModel::parseWindows(const QJsonArray &array) {
  QList<WindowInfo> &m_windows = windowModel()->windows();
  m_windows.clear();
  for (const auto &value : array) {
    WindowInfo wn;
    QJsonObject obj = value.toObject();
    wn.id = obj["id"].toInteger();
    wn.title = obj["title"].toString();
    wn.app_id = obj["app_id"].toString();
    wn.pid = obj["pid"].toInteger();
    wn.is_floating = obj["is_floating"].toBool();
    wn.is_focused = obj["is_focused"].toBool();
    wn.is_urgent = obj["is_urgent"].toBool();
    wn.workspace_id = obj["workspace_id"].toInteger();
    m_windows.append(wn);
    if (wn.is_focused) {
      m_focusedWindow = wn;
      emit focusedWindowChanged();
    }
  }
}

void WorkspaceModel::parseWorkspaces(const QJsonArray &array) {
  beginResetModel();
  m_workspaces.clear();
  for (const auto &val : array) {
    QJsonObject obj = val.toObject();
    WorkspaceInfo ws;
    ws.id = obj["id"].toInteger();
    ws.name = obj["name"].toString();
    ws.idx = obj["idx"].toInt();
    ws.is_focused = obj["is_focused"].toBool();
    ws.is_active = obj["is_active"].toBool();
    ws.is_urgent = obj["is_urgent"].toBool();
    ws.output = obj["output"].toString();
    ws.active_window_id = obj["active_window_id"].toInteger();
    m_workspaces.append(ws);
  }

  std::sort(m_workspaces.begin(), m_workspaces.end(),
            [](const WorkspaceInfo &a, const WorkspaceInfo &b) {
              return a.idx < b.idx;
            });

  endResetModel();
  emit activeWorkspaceChanged();
}

void WorkspaceModel::updateFocusedWindow(const std::uint64_t id) {
  QList<WindowInfo> &m_windows = windowModel()->windows();
  for (int i = 0; i < m_windows.size(); ++i) {
    bool isNowFocused = (m_windows[i].id == id);
    if (m_windows[i].is_focused != isNowFocused) {
      m_windows[i].is_focused = isNowFocused;
      if (isNowFocused) {
        m_activeWindowIndex = i;
        m_focusedWindow = m_windows[i];
        emit activeWindowChanged();
      }
    }
  }
  emit focusedWindowChanged();
}

QList<WindowInfo> &WindowModel::windows() { return m_windows; }

int WindowModel::rowCount(const QModelIndex &parent) const {
  return parent.isValid() ? 0 : m_windows.count();
}

QVariant WindowModel::data(const QModelIndex &index, int role) const {
  if (!index.isValid() || index.row() < 0 || index.row() >= m_windows.count())
    return {};
  const auto &w = m_windows.at(index.row());
  switch (role) {
  case TitleRole:
    return w.title;
  case AppIdRole:
    return w.app_id;
  case IsFocusedRole:
    return w.is_focused;
  case IsFloatingRule:
    return w.is_floating;
  case WorkspaceIdRole:
    return w.workspace_id;
  }
  return {};
}

QHash<int, QByteArray> WindowModel::roleNames() const  {
  return {{TitleRole, "title"},
          {AppIdRole, "appId"},
          {IsFocusedRole, "isFocused"},
          {IsFloatingRule, "isFloating"},
          {WorkspaceIdRole, "workspaceId"}};
}

void WindowModel::replaceAll(const QList<WindowInfo> &windows) {
  beginResetModel();
  m_windows = windows;
  endResetModel();
}

void WindowModel::updateOrAppend(const QJsonObject &obj) {
  quint64 winId = obj["id"].toInteger();

  for (int i = 0; i < m_windows.size(); ++i) {
    if (m_windows[i].id == winId) {
      m_windows[i].title = obj["title"].toString();
      m_windows[i].app_id = obj["app_id"].toString();
      m_windows[i].is_focused = obj["is_focused"].toBool();
      m_windows[i].workspace_id = obj["workspace_id"].toInteger();

      emit dataChanged(
          createIndex(i, 0), createIndex(i, 0),
          {TitleRole, AppIdRole, IsFocusedRole, WorkspaceIdRole});
      return;
    }
  }

  beginInsertRows(QModelIndex(), m_windows.size(), m_windows.size());
  WindowInfo wn;
  wn.id = winId;
  wn.title = obj["title"].toString();
  wn.app_id = obj["app_id"].toString();
  wn.is_focused = obj["is_focused"].toBool();
  wn.workspace_id = obj["workspace_id"].toInteger();
  m_windows.append(wn);
  endInsertRows();
}
