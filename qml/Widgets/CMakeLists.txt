qt_add_qml_module(shellwidgets
    URI Shell.Widgets
    VERSION 1.0
    QML_FILES
        Clock.qml
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/Shell/Widgets
)

target_link_libraries(shellwidgets PRIVATE
    Qt6::Core
    Qt6::Quick
)

target_include_directories(shellwidgets PRIVATE
    ${CMAKE_SOURCE_DIR}/src/widgets/n_wallpaper
)
