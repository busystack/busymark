# Set the default before dependency discovery: a failed first configure must
# not leave /usr/local cached as the prefix for a later successful build.
set(BUILD_BUNDLE_DIR "${PROJECT_BINARY_DIR}/bundle")
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH
    "BusyMark installation directory" FORCE)
endif()

function(busymark_clean_default_bundle)
  # Clean only our ordinary build bundle. Custom prefixes and DESTDIR installs
  # must preserve both their existing contents and the unstaged build bundle.
  # Evaluate the prefix and DESTDIR at installation time.
  install(CODE "
    if(CMAKE_INSTALL_PREFIX STREQUAL \"${BUILD_BUNDLE_DIR}\"
        AND \"\$ENV{DESTDIR}\" STREQUAL \"\")
      file(REMOVE_RECURSE \"${BUILD_BUNDLE_DIR}/\")
    endif()
    " COMPONENT Runtime)
endfunction()
