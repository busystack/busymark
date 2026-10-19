# Preserve the dependency pin and cache; compile verified build-local copies.
find_package(Python3 REQUIRED COMPONENTS Interpreter)
set(_yaru_source "${FLUTTER_MANAGED_DIR}/ephemeral/.plugin_symlinks/yaru_window_linux")
set(_yaru_patch "${CMAKE_CURRENT_SOURCE_DIR}/../tools/native_patches/yaru_window_linux")
set(_yaru_output "${CMAKE_BINARY_DIR}/patched-plugins/yaru_window_linux")
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
  "${_yaru_patch}/prepare.py" "${_yaru_patch}/source.lock.json"
  "${_yaru_patch}/retired-window.patch" "${_yaru_patch}/README.md")
foreach(_yaru_input pubspec.yaml LICENSE linux/CMakeLists.txt
    linux/yaru_window.cc linux/yaru_window.h linux/yaru_window_linux_plugin.cc
    linux/include/yaru_window_linux/yaru_window_linux_plugin.h)
  set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
    "${_yaru_source}/${_yaru_input}")
endforeach()
execute_process(
  COMMAND "${Python3_EXECUTABLE}" "${_yaru_patch}/prepare.py"
    "${_yaru_source}" "${_yaru_output}" --build-root "${CMAKE_BINARY_DIR}"
  RESULT_VARIABLE _yaru_result OUTPUT_VARIABLE _yaru_stdout ERROR_VARIABLE _yaru_stderr)
if(NOT _yaru_result EQUAL 0)
  message(FATAL_ERROR "Cannot prepare the required Yaru lifetime correction:\n${_yaru_stdout}\n${_yaru_stderr}")
endif()
if(NOT TARGET yaru_window_linux_plugin)
  message(FATAL_ERROR "The pinned Yaru window plugin target is missing")
endif()
set_property(TARGET yaru_window_linux_plugin PROPERTY SOURCES
  "${_yaru_output}/linux/yaru_window.cc"
  "${_yaru_output}/linux/yaru_window_linux_plugin.cc")
target_include_directories(yaru_window_linux_plugin PRIVATE "${_yaru_output}/linux")
