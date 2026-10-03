#include <qstring.h>

enum CompositorType {
    None,
    Niri
};

class Compositor {
    public:
        CompositorType detectCompositor();
};
