cmake_minimum_required(VERSION 3.16)
project(neoshell)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_AUTOMOC ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick Widgets Network)
find_package(LayerShellQt REQUIRED)

qt_policy(SET QTP0001 NEW)
qt_policy(SET QTP0004 NEW)

# ----------- IPC Library -----------
add_library(shellIpc STATIC
    src/ipc/niri.hpp
    src/ipc/niri.cpp
)
target_include_directories(shellIpc PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/src/ipc
)
target_link_libraries(shellIpc PUBLIC
    Qt6::Core
    Qt6::Network
)

# ----------- Utils Library -----------
add_library(shellUtils STATIC
    src/utils/logger.cpp
    src/utils/matugen.cpp
)
target_include_directories(shellUtils PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/src/utils
)
target_link_libraries(shellUtils PRIVATE
    Qt6::Gui
    Qt6::Core
)

# Services QML Module
add_library(shellServices STATIC)

qt_add_qml_module(shellServices
    URI Shell.Services
    VERSION 1.0
    SOURCES
        qml/Services/Compositor.cpp
        qml/Services/ThemeManager.cpp
        qml/Services/WorkspaceModel.cpp
        qml/Services/Clock.cpp
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/Shell/Services
)

target_include_directories(shellServices PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/qml/Services
)

target_link_libraries(shellServices PRIVATE
    shellUtils
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::Widgets
)

# Main Executable
qt_add_executable(neoshell)

qt_add_qml_module(neoshell
    URI Shell
    VERSION 1.0
    QML_FILES
        qml/Bar.qml
        qml/Widgets/Clock.qml
    SOURCES
        src/wayland/panel_window.hpp
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

add_subdirectory(qml/Widgets)

target_link_libraries(neoshell PRIVATE
    shellIpc
    shellServices
    shellUtils
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::Widgets
    LayerShellQt::Interface
)

target_compile_definitions(neoshell PRIVATE
    PROJECT_SOURCE_DIR="${CMAKE_SOURCE_DIR}"
)
