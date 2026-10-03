add_library(neoshell_logger SHARED
    logger.h
    logger.cpp
)

target_include_directories(neoshell_logger PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
)
