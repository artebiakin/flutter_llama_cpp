# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(flutter_llama_cpp_library VERSION 0.0.1 LANGUAGES C)

add_library(flutter_llama_cpp SHARED
  "flutter_llama_cpp.c"
)

set_target_properties(flutter_llama_cpp PROPERTIES
  PUBLIC_HEADER flutter_llama_cpp.h
  OUTPUT_NAME "flutter_llama_cpp"
)

target_compile_definitions(flutter_llama_cpp PUBLIC DART_SHARED_LIB)

if (ANDROID)
  # Support Android 15 16k page size
  target_link_options(flutter_llama_cpp PRIVATE "-Wl,-z,max-page-size=16384")
endif()
