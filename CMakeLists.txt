cmake_minimum_required(VERSION 3.16)
project(neoshell)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_AUTOMOC ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_BUILD_TYPE RelWithDebInfo)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick Widgets Network Concurrent GuiPrivate)
find_package(LayerShellQt REQUIRED)

qt_policy(SET QTP0001 NEW)
qt_policy(SET QTP0004 NEW)


add_subdirectory(qml/Widgets)
add_subdirectory(qml/Panels)
add_subdirectory(src/utils/logger)
add_subdirectory(src/lib/stb_headers)

# ----------- IPC Library -----------
add_library(shellIpc STATIC
    src/ipc/niri.h
    src/ipc/niri.cpp
)
target_include_directories(shellIpc PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/src/ipc
)
target_link_libraries(shellIpc PUBLIC
    Qt6::Core
    Qt6::Network
)

# Services QML Module
add_library(shellServices STATIC)

qt_add_qml_module(shellServices
    URI Shell.Services
    VERSION 1.0
    SOURCES
        ${CMAKE_SOURCE_DIR}/src/widgets/n_wallpaper/wallpaper.h
        ${CMAKE_SOURCE_DIR}/src/widgets/n_wallpaper/wallpaper.cpp
        ${CMAKE_SOURCE_DIR}/src/widgets/n_wallpaper/matugen.cpp
        ${CMAKE_SOURCE_DIR}/src/widgets/n_wallpaper/matugen.h
        ${CMAKE_SOURCE_DIR}/src/widgets/n_wallpaper/bc1_compression.h
        ${CMAKE_SOURCE_DIR}/src/widgets/n_wallpaper/bc1_compression.cpp
        ${CMAKE_SOURCE_DIR}/src/widgets/n_wallpaper/theme_manager.h
        ${CMAKE_SOURCE_DIR}/src/widgets/n_wallpaper/theme_manager.cpp
        ${CMAKE_SOURCE_DIR}/qml/Services/Compositor.cpp
        ${CMAKE_SOURCE_DIR}/qml/Services/Compositor.h
        ${CMAKE_SOURCE_DIR}/qml/Services/WorkspaceModel.cpp
        ${CMAKE_SOURCE_DIR}/qml/Services/WorkspaceModel.h
        ${CMAKE_SOURCE_DIR}/qml/Services/Clock.cpp
        ${CMAKE_SOURCE_DIR}/qml/Services/Clock.h
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/Shell/Services
)

target_include_directories(shellServices PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/qml/Services
    ${CMAKE_CURRENT_SOURCE_DIR}/src/widgets/n_wallpaper
)

target_link_libraries(shellServices PRIVATE
    neoshell_logger
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::Concurrent
    Qt6::GuiPrivate
    stb
    neoshell_logger
)

# Main Executable
qt_add_executable(neoshell
)

qt_add_qml_module(neoshell
    URI Shell
    VERSION 1.0
    QML_FILES
        qml/WallpaperSurf.qml
        qml/Main.qml
        qml/Bar.qml
        qml/Widgets/Clock.qml
    SOURCES
        src/wayland/panel_window.h
        src/wayland/panel_window.cpp
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/Shell
)

target_sources(neoshell PRIVATE
    src/main.cpp
)

target_include_directories(neoshell PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_SOURCE_DIR}/src/wayland
)


target_link_libraries(neoshell PRIVATE
    shellIpc
    neoshell_logger
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::Widgets
    LayerShellQt::Interface
)

target_compile_definitions(neoshell PRIVATE
    PROJECT_SOURCE_DIR="${CMAKE_SOURCE_DIR}"
)
