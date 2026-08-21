# Project-level configuration.
cmake_minimum_required(VERSION 3.13)
project(runner LANGUAGES CXX)

# The name of the executable created for the application. Change this to change
# the on-disk name of your application.
set(BINARY_NAME "busymark")
# The unique GTK application identifier for this application. See:
# https://wiki.gnome.org/HowDoI/ChooseApplicationID
set(APPLICATION_ID "io.busystack.busymark")

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(SET CMP0063 NEW)

# Load bundled libraries from the lib/ directory relative to the binary.
set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")

# Root filesystem for cross-building.
if(FLUTTER_TARGET_PLATFORM_SYSROOT)
  set(CMAKE_SYSROOT ${FLUTTER_TARGET_PLATFORM_SYSROOT})
  set(CMAKE_FIND_ROOT_PATH ${CMAKE_SYSROOT})
  set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
  set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
endif()

# Define build configuration options.
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE "Debug" CACHE
    STRING "Flutter build mode" FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
    "Debug" "Profile" "Release")
endif()

# Compilation settings that should be applied to most targets.
#
# Be cautious about adding new options here, as plugins use this function by
# default. In most cases, you should add new options to specific targets instead
# of modifying this function.
function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_14)
  target_compile_options(${TARGET} PRIVATE -Wall -Werror)
  target_compile_options(${TARGET} PRIVATE "$<$<NOT:$<CONFIG:Debug>>:-O3>")
  target_compile_definitions(${TARGET} PRIVATE "$<$<NOT:$<CONFIG:Debug>>:NDEBUG>")
endfunction()

# Flutter library and tool build rules.
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

# System-level dependencies.
find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)
pkg_check_modules(HANDY REQUIRED IMPORTED_TARGET libhandy-1)
pkg_check_modules(LIBSECRET REQUIRED IMPORTED_TARGET libsecret-1)
pkg_check_modules(WEBKIT REQUIRED IMPORTED_TARGET webkit2gtk-4.1)

# Application build; see runner/CMakeLists.txt.
add_subdirectory("runner")

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)

# BusyMark bundles a pinned static Typst compiler for deterministic PDF export.
# The preparation script verifies the upstream release checksum before the
# compiler becomes part of the application bundle.
set(TYPST_BUNDLE_DIR "${CMAKE_BINARY_DIR}/typst/linux-${CMAKE_SYSTEM_PROCESSOR}")
set(TYPST_EXECUTABLE "${TYPST_BUNDLE_DIR}/typst")
set(TYPST_LICENSE "${TYPST_BUNDLE_DIR}/LICENSE")
set(TYPST_NOTICE "${TYPST_BUNDLE_DIR}/NOTICE")
set(TYPST_VERSION_FILE "${TYPST_BUNDLE_DIR}/VERSION")
add_custom_command(
  OUTPUT
    "${TYPST_EXECUTABLE}"
    "${TYPST_LICENSE}"
    "${TYPST_NOTICE}"
    "${TYPST_VERSION_FILE}"
  COMMAND
    "${CMAKE_CURRENT_SOURCE_DIR}/../tools/fetch_typst.sh"
    "${TYPST_BUNDLE_DIR}"
    "${CMAKE_SYSTEM_PROCESSOR}"
  DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/../tools/fetch_typst.sh"
  COMMENT "Preparing pinned Typst compiler for PDF export"
  VERBATIM
)
add_custom_target(busymark_typst ALL
  DEPENDS
    "${TYPST_EXECUTABLE}"
    "${TYPST_LICENSE}"
    "${TYPST_NOTICE}"
    "${TYPST_VERSION_FILE}"
)
add_dependencies(${BINARY_NAME} busymark_typst)

# Offline visualization engines and the pinned D2 CLI. JavaScript is bundled
# at build time; Node.js is not installed in or required by the application.
set(VISUALIZATION_WEB_DIR "${CMAKE_BINARY_DIR}/visualization/web")
set(VISUALIZATION_WEB_VERSION "${VISUALIZATION_WEB_DIR}/VERSION")
set(VISUALIZATION_WEB_HARNESS "${VISUALIZATION_WEB_DIR}/harness.html")
set(VISUALIZATION_WEB_BOOTSTRAP "${VISUALIZATION_WEB_DIR}/bootstrap.js")
set(VISUALIZATION_WEB_ENGINES "${VISUALIZATION_WEB_DIR}/render-engines.js")
set(VISUALIZATION_WEB_SCALAR "${VISUALIZATION_WEB_DIR}/scalar.js")
set(VISUALIZATION_WEB_VIZ "${VISUALIZATION_WEB_DIR}/viz-global.js")
add_custom_command(
  OUTPUT
    "${VISUALIZATION_WEB_VERSION}"
    "${VISUALIZATION_WEB_HARNESS}"
    "${VISUALIZATION_WEB_BOOTSTRAP}"
    "${VISUALIZATION_WEB_ENGINES}"
    "${VISUALIZATION_WEB_SCALAR}"
    "${VISUALIZATION_WEB_VIZ}"
  COMMAND
    "${CMAKE_CURRENT_SOURCE_DIR}/../tools/fetch_visualization_web.sh"
    "${VISUALIZATION_WEB_DIR}"
  DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/../tools/fetch_visualization_web.sh"
    "${CMAKE_CURRENT_SOURCE_DIR}/../tools/visualization/package.json"
    "${CMAKE_CURRENT_SOURCE_DIR}/../tools/visualization/package-lock.json"
    "${CMAKE_CURRENT_SOURCE_DIR}/../tools/visualization/render_engines.js"
    "${CMAKE_CURRENT_SOURCE_DIR}/../tools/visualization/reference.js"
    "${CMAKE_CURRENT_SOURCE_DIR}/../tools/visualization/bootstrap.js"
    "${CMAKE_CURRENT_SOURCE_DIR}/../tools/visualization/harness.html"
    "${CMAKE_CURRENT_SOURCE_DIR}/../tools/visualization/reference.html"
    "${CMAKE_CURRENT_SOURCE_DIR}/../tools/visualization/generate_notices.js"
  COMMENT "Preparing pinned offline visualization web engines"
  VERBATIM
)
add_custom_target(busymark_visualization_web ALL
  DEPENDS
    "${VISUALIZATION_WEB_VERSION}"
    "${VISUALIZATION_WEB_HARNESS}"
    "${VISUALIZATION_WEB_BOOTSTRAP}"
    "${VISUALIZATION_WEB_ENGINES}"
    "${VISUALIZATION_WEB_SCALAR}"
    "${VISUALIZATION_WEB_VIZ}"
)
add_dependencies(${BINARY_NAME} busymark_visualization_web)

set(D2_BUNDLE_DIR "${CMAKE_BINARY_DIR}/d2/linux-${CMAKE_SYSTEM_PROCESSOR}")
set(D2_EXECUTABLE "${D2_BUNDLE_DIR}/d2")
set(D2_VERSION_FILE "${D2_BUNDLE_DIR}/VERSION")
set(D2_LICENSE "${D2_BUNDLE_DIR}/LICENSE.txt")
set(D2_NOTICE "${D2_BUNDLE_DIR}/NOTICE")
add_custom_command(
  OUTPUT
    "${D2_EXECUTABLE}"
    "${D2_VERSION_FILE}"
    "${D2_LICENSE}"
    "${D2_NOTICE}"
  COMMAND
    "${CMAKE_CURRENT_SOURCE_DIR}/../tools/fetch_d2.sh"
    "${D2_BUNDLE_DIR}"
    "${CMAKE_SYSTEM_PROCESSOR}"
  DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/../tools/fetch_d2.sh"
  COMMENT "Preparing checksum-pinned D2 renderer"
  VERBATIM
)
add_custom_target(busymark_d2 ALL
  DEPENDS
    "${D2_EXECUTABLE}"
    "${D2_VERSION_FILE}"
    "${D2_LICENSE}"
    "${D2_NOTICE}"
)
add_dependencies(${BINARY_NAME} busymark_d2)

# Only the install-generated bundle's copy of the executable will launch
# correctly, since the resources must in the right relative locations. To avoid
# people trying to run the unbundled copy, put it in a subdirectory instead of
# the default top-level location.
set_target_properties(${BINARY_NAME}
  PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/intermediates_do_not_run"
)


# Generated plugin build rules, which manage building the plugins and adding
# them to the application.
include(flutter/generated_plugins.cmake)


# === Installation ===
# By default, "installing" just makes a relocatable bundle in the build
# directory.
set(BUILD_BUNDLE_DIR "${PROJECT_BINARY_DIR}/bundle")
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "..." FORCE)
endif()

# Start with a clean build bundle directory every time.
install(CODE "
  file(REMOVE_RECURSE \"${BUILD_BUNDLE_DIR}/\")
  " COMPONENT Runtime)

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}/lib")

install(PROGRAMS "${TYPST_EXECUTABLE}"
  DESTINATION "${CMAKE_INSTALL_PREFIX}/libexec/busymark"
  COMPONENT Runtime)

install(FILES "${TYPST_LICENSE}" "${TYPST_NOTICE}" "${TYPST_VERSION_FILE}"
  DESTINATION "${CMAKE_INSTALL_PREFIX}/share/licenses/typst"
  COMPONENT Runtime)

install(PROGRAMS "${D2_EXECUTABLE}"
  DESTINATION "${CMAKE_INSTALL_PREFIX}/libexec/busymark"
  COMPONENT Runtime)

install(FILES
  "${D2_LICENSE}"
  "${D2_NOTICE}"
  "${D2_VERSION_FILE}"
  DESTINATION "${CMAKE_INSTALL_PREFIX}/share/licenses/d2"
  COMPONENT Runtime)

install(DIRECTORY "${VISUALIZATION_WEB_DIR}/"
  DESTINATION "${CMAKE_INSTALL_PREFIX}/share/busymark/visualization"
  COMPONENT Runtime)

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)

install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/io.busystack.busymark.desktop"
  DESTINATION "${CMAKE_INSTALL_PREFIX}/share/applications"
  COMPONENT Runtime)

install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/io.busystack.busymark.metainfo.xml"
  DESTINATION "${CMAKE_INSTALL_PREFIX}/share/metainfo"
  COMPONENT Runtime)

install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/../assets/branding/busymark_logo.svg"
  DESTINATION "${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/scalable/apps"
  RENAME "io.busystack.busymark.svg"
  COMPONENT Runtime)

install(FILES "${FLUTTER_ICU_DATA_FILE}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime)

foreach(bundled_library ${PLUGIN_BUNDLED_LIBRARIES})
  install(FILES "${bundled_library}"
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endforeach(bundled_library)

# Copy the native assets provided by the build.dart from all packages.
set(NATIVE_ASSETS_DIR "${PROJECT_BUILD_DIR}native_assets/linux/")
install(DIRECTORY "${NATIVE_ASSETS_DIR}"
   DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
   COMPONENT Runtime)

# Fully re-copy the assets directory on each build to avoid having stale files
# from a previous install.
set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
install(CODE "
  file(REMOVE_RECURSE \"${INSTALL_BUNDLE_DATA_DIR}/${FLUTTER_ASSET_DIR_NAME}\")
  " COMPONENT Runtime)
install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
  DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)

# Install the AOT library on non-Debug builds only.
if(NOT CMAKE_BUILD_TYPE MATCHES "Debug")
  install(FILES "${AOT_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endif()
