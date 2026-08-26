#include "WorkspaceModel.hpp"
#include <cstdint>
#include <qjsonarray.h>
#include <qjsonobject.h>
#include <qlogging.h>
#include <qtypes.h>
#include <qvariant.h>

WorkspaceModel::WorkspaceModel(QObject *parent) : QAbstractListModel(parent) {};

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
  return {{IdRoles, "wsId"},
          {NameRole, "wsName"},
          {IndexRole, "wsIndex"},
          {IsFocusedRole, "isFocused"},
          {IsActiveRole, "isActive"},
          {OutputRole, "output"},};
};


void WorkspaceModel::handleEvent(const QJsonObject &event) {
  if (event.contains("WorkspacesChanged")) {
      workspaceChangedEvnHandler(event["WorkspacesChanged"].toObject()["workspaces"].toArray());
  } else if (event.contains("WindowsChanged")){
      windowsChangedEvnHandler(event["WindowsChanged"].toObject()["windows"].toArray());
  }else if (event.contains("WorkspaceActivated")) {
      workspaceActivatedEvnHandler(event["WorkspaceActivated"].toObject());
  } else if(event.contains("WindowFocusChanged")){
      windowFocusChangedEvnHandler(event["WindowFocusChanged"].toObject());
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

void WorkspaceModel::workspaceChangedEvnHandler(const QJsonArray &event) {
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
    if(obj["id"].isNull())
    {
        m_focusedWindow = {};
        updateFocusedWindow(-1);
        emit focusedWindowChanged();
    }
    else {
        updateFocusedWindow(obj["id"].toInteger());
    }
}

void WorkspaceModel::parseWindows(const QJsonArray &array) {
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
    if(wn.is_focused)
    {
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
    for(int i=0; i<m_windows.size(); ++i)
    {
      bool isNowFocused = (m_windows[i].id == id);
      if(m_windows[i].is_focused != isNowFocused) {
          m_windows[i].is_focused = isNowFocused;
          if(isNowFocused)
          {
              m_activeWindowIndex = i;
              m_focusedWindow = m_windows[i];
              emit activeWindowChanged();
          }
      }
  }
  emit focusedWindowChanged();
}
