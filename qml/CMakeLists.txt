qt_add_qml_module(shell
    URI Shell
    VERSION 1.0
    QML_FILES
        Bar.qml
        WallpaperSurf.qml
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/Shell
)
