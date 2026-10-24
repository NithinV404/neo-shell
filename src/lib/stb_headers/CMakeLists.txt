add_library(stb SHARED
    stb_dxt.h
)

target_include_directories(neoshell_logger PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
)
