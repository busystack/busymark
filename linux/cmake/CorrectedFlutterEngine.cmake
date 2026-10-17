# Generated config carries the actual Flutter tool's local-engine selection.
# Reject raw official-engine builds as well as missing/mixed cached modes.
# Flutter includes this config inside its subdirectory; its tool environment is
# not exported to this scope. Load the actual generated selection explicitly.
function(busymark_load_flutter_selection)
  include("${FLUTTER_MANAGED_DIR}/ephemeral/generated_config.cmake")
  set(FLUTTER_ROOT "${FLUTTER_ROOT}" PARENT_SCOPE)
  set(FLUTTER_TOOL_ENVIRONMENT "${FLUTTER_TOOL_ENVIRONMENT}" PARENT_SCOPE)
endfunction()
busymark_load_flutter_selection()
find_package(Python3 REQUIRED COMPONENTS Interpreter)
execute_process(
  COMMAND "${Python3_EXECUTABLE}"
    "${CMAKE_CURRENT_SOURCE_DIR}/../tools/flutter_engine/engine.py"
    check-cmake --mode "${CMAKE_BUILD_TYPE}" --framework "${FLUTTER_ROOT}"
    ${FLUTTER_TOOL_ENVIRONMENT}
  RESULT_VARIABLE BUSYMARK_ENGINE_CHECK
  OUTPUT_VARIABLE BUSYMARK_ENGINE_CHECK_OUTPUT
  ERROR_VARIABLE BUSYMARK_ENGINE_CHECK_ERROR
)
if(NOT BUSYMARK_ENGINE_CHECK EQUAL 0)
  message(FATAL_ERROR "${BUSYMARK_ENGINE_CHECK_OUTPUT}${BUSYMARK_ENGINE_CHECK_ERROR}")
endif()
add_custom_target(busymark_engine_verified
  COMMAND "${Python3_EXECUTABLE}"
    "${CMAKE_CURRENT_SOURCE_DIR}/../tools/flutter_engine/engine.py"
    check-cmake --mode "${CMAKE_BUILD_TYPE}" --framework "${FLUTTER_ROOT}"
    --ephemeral "${FLUTTER_MANAGED_DIR}/ephemeral"
    ${FLUTTER_TOOL_ENVIRONMENT}
  DEPENDS flutter_assemble
  VERBATIM
)
add_dependencies(flutter busymark_engine_verified)
