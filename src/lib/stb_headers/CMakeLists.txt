add_library(stb_image SHARED
    stb_image.h
    stb_dxt.h
)

target_include_directories(neoshell_logger PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
)
