#include "Compositor.hpp"
#include <qprocess.h>

CompositorType Compositor::detectCompositor() {
    auto env = QProcessEnvironment::systemEnvironment();

    if(!env.value("NIRI_SOCKET").isEmpty())
    {
        return CompositorType::Niri;
    }
    else {
        return CompositorType::None;
    }
}
