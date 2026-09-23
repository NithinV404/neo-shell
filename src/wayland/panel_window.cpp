#include "panel_window.hpp"

PanelWindow::PanelWindow(QWindow *parent): QQuickWindow(parent), m_window(LayerShellQt::Window::get(this)) {}

PanelWindow::Layer PanelWindow::layer() const {return m_layer;}
void PanelWindow::setLayer(Layer layer){
    if(m_layer == layer) return;
    m_layer = layer;
    m_window->setLayer(static_cast<LayerShellQt::Window::Layer>(m_layer));
    emit layerChanged();
}

PanelWindow::Anchors PanelWindow::anchors() const { return m_anchors; }
void PanelWindow::setAnchors(Anchors anchors){
    if(m_anchors == anchors) return;
    m_anchors = anchors;
    LayerShellQt::Window::Anchors layerAnchors(
            static_cast<LayerShellQt::Window::Anchor>(anchors.toInt())
    );
    m_window->setAnchors(layerAnchors);
    emit anchorsChanged();
}

int PanelWindow::exclusionZone() const { return m_zone; }
void PanelWindow::setExclusionZone(int zone) {
    if(m_zone == zone) return;
    m_zone = zone;
    m_window->setExclusiveZone(m_zone);
    emit exclusionZoneChanged();
}

QString PanelWindow::scope() const { return m_scope; }
void PanelWindow::setScope(const QString &scope) {
    if(m_scope == scope) return;
    m_scope = scope;
    m_window->setScope(scope);
    emit scopeChanged();
}

PanelWindow::KeyboardInteractivity PanelWindow::keyboardInteractivity() const { return m_keyboardInteractivity; }
void PanelWindow::setKeyboardInteractivity(PanelWindow::KeyboardInteractivity keyboardInteractivity) {
    if(m_keyboardInteractivity == keyboardInteractivity) return;
    m_keyboardInteractivity = keyboardInteractivity;
    m_window->setKeyboardInteractivity(static_cast<LayerShellQt::Window::KeyboardInteractivity>(m_keyboardInteractivity));
    emit keyboardInteractivityChanged();
}
