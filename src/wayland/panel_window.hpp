#pragma once

#include <LayerShellQt/window.h>
#include <QtQuick/QQuickWindow>
#include <qflags.h>

class PanelWindow : public QQuickWindow {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(Layer layer READ layer WRITE setLayer NOTIFY layerChanged)
    Q_PROPERTY(Anchors anchors READ anchors WRITE setAnchors NOTIFY anchorsChanged)
    Q_PROPERTY(int exclusionZone READ exclusionZone WRITE setExclusionZone NOTIFY exclusionZoneChanged)
    Q_PROPERTY(QString scope READ scope WRITE setScope NOTIFY scopeChanged)
    Q_PROPERTY(KeyboardInteractivity keyboardInteractivity READ keyboardInteractivity WRITE setKeyboardInteractivity NOTIFY keyboardInteractivityChanged)

    public:
        enum Layer {
            Background = LayerShellQt::Window::LayerBackground,
            Top = LayerShellQt::Window::LayerTop,
            Overlay = LayerShellQt::Window::LayerOverlay,
            Bottom = LayerShellQt::Window::LayerBottom
        };
        enum Anchor {
            AnchorTop = LayerShellQt::Window::AnchorTop,
            AnchorLeft = LayerShellQt::Window::AnchorLeft,
            AnchorRight = LayerShellQt::Window::AnchorRight,
            AnchorBottom = LayerShellQt::Window::AnchorBottom
        };
        enum KeyboardInteractivity {
            Exclusive = LayerShellQt::Window::KeyboardInteractivityExclusive,
            None = LayerShellQt::Window::KeyboardInteractivityNone,
            OnDemand = LayerShellQt::Window::KeyboardInteractivityOnDemand
        };
        Q_ENUM(Anchor)
        Q_ENUM(KeyboardInteractivity)
        Q_ENUM(Layer)
        Q_DECLARE_FLAGS(Anchors, Anchor)

        explicit PanelWindow(QWindow *parent = nullptr);

        Layer layer() const;
        void setLayer(Layer layer);

        Anchors anchors() const;
        void setAnchors(Anchors anchors);

        int exclusionZone() const;
        void setExclusionZone(int zone);

        QString scope() const;
        void setScope(const QString &scope);

        KeyboardInteractivity keyboardInteractivity() const;
        void setKeyboardInteractivity(KeyboardInteractivity keyboardInteractivity);

        signals:
            void exclusionZoneChanged();
            void layerChanged();
            void anchorsChanged();
            void keyboardInteractivityChanged();
            void scopeChanged();

        private:
            LayerShellQt::Window *m_window;
            Layer m_layer = Layer::Top;
            Anchors m_anchors = Anchor::AnchorTop;
            KeyboardInteractivity m_keyboardInteractivity = KeyboardInteractivity::None;
            QString m_scope = "";
            int m_zone = 0;

};
 Q_DECLARE_OPERATORS_FOR_FLAGS(PanelWindow::Anchors);
