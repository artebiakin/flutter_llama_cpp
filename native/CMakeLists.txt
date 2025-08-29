cmake_minimum_required(VERSION 3.18)

project(llama_flutter LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Build type
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

# Compiler flags
set(CMAKE_C_FLAGS_RELEASE "-O3 -DNDEBUG -ffast-math")
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG -ffast-math")

# Platform-specific settings
if(APPLE)
    set(CMAKE_OSX_DEPLOYMENT_TARGET "11.0")
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "arm64")
        set(CMAKE_OSX_ARCHITECTURES "arm64")
    else()
        set(CMAKE_OSX_ARCHITECTURES "x86_64")
    endif()
endif()

# Find llama.cpp
set(LLAMA_CPP_DIR "${CMAKE_CURRENT_SOURCE_DIR}/vendor/llama.cpp")

# Configure llama.cpp build
set(GGML_STATIC ON CACHE BOOL "ggml: static lib")
set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build shared libraries")
set(GGML_NATIVE OFF CACHE BOOL "ggml: use -march=native")
set(GGML_LTO OFF CACHE BOOL "ggml: use link time optimization")

# Platform-specific llama.cpp options
if(APPLE)
    set(GGML_METAL OFF CACHE BOOL "ggml: use Metal")
    set(GGML_ACCELERATE ON CACHE BOOL "ggml: use Accelerate framework")
endif()

if(ANDROID)
    set(GGML_OPENMP OFF CACHE BOOL "ggml: use OpenMP")
endif()

# Add llama.cpp subdirectory
add_subdirectory(${LLAMA_CPP_DIR} llama_cpp EXCLUDE_FROM_ALL)

# Create the main library
add_library(llama_flutter SHARED
    shim/llama_flutter.cc
)

# Set target properties
set_target_properties(llama_flutter PROPERTIES
    CXX_VISIBILITY_PRESET hidden
    C_VISIBILITY_PRESET hidden
    VISIBILITY_INLINES_HIDDEN ON
)

# Include directories
target_include_directories(llama_flutter PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/shim
    ${LLAMA_CPP_DIR}/include
    ${LLAMA_CPP_DIR}/ggml/include
    ${LLAMA_CPP_DIR}/common
)

# Link libraries
target_link_libraries(llama_flutter PRIVATE
    llama
    ggml
)

# Platform-specific linking
if(APPLE)
    target_link_libraries(llama_flutter PRIVATE
        "-framework Accelerate"
        "-framework Foundation"
    )
endif()

if(ANDROID)
    target_link_libraries(llama_flutter PRIVATE
        log
        android
    )
endif()

# Install the library
install(TARGETS llama_flutter
    LIBRARY DESTINATION .
    ARCHIVE DESTINATION .
    RUNTIME DESTINATION .
)
