# Detect numpy source directory
set(_landmark_numpy "numpy/core/include/numpy/_numpyconfig.h.in") # CMake will look for this file.
if(NOT (NUMPY_SRC_DIR AND EXISTS ${NUMPY_SRC_DIR}/${_landmark_numpy}))
    foreach(dirname
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${CMAKE_CURRENT_SOURCE_DIR}/numpy-${NUMPY_VERSION}
        ${CMAKE_CURRENT_BINARY_DIR}/../numpy-${NUMPY_VERSION})
        set(NUMPY_SRC_DIR ${dirname})
        if(EXISTS ${SRC_DIR}/${_landmark_numpy})
            break()
        endif()
    endforeach()
endif()

# Download numpy sources
set(_download_numpy_link "https://github.com/numpy/numpy/releases/download/v${NUMPY_VERSION}/numpy-${NUMPY_VERSION}.tar.gz")

# Set numpy 1.26.x md5 checksums
set(_download_numpy_1.26.4_md5 "19550cbe7bedd96a928da9d4ad69509d")
set(_download_numpy_1.26.3_md5 "1c915dc6c36dd4c674d9379e9470ff8b")
set(_download_numpy_1.26.2_md5 "8f6446a32e47953a03f8fe8533e21e98")
set(_download_numpy_1.26.1_md5 "2d770f4c281d405b690c4bcb3dbe99e2")

# Set wanted c api versions
set(_numpy_1.26_c_api_version "11")

set(_extracted_numpy_dir "numpy-${NUMPY_VERSION}")

if(NOT EXISTS ${NUMPY_SRC_DIR}/${_landmark_numpy} AND DOWNLOAD_SOURCES)
    get_filename_component(_numpy_filename ${_download_numpy_link} NAME)
    set(_numpy_archive_filepath ${CMAKE_CURRENT_BINARY_DIR}/../${_numpy_filename})
    if(EXISTS "${_numpy_archive_filepath}")
      message(STATUS "${_numpy_archive_filepath} already downloaded")
    else()
      message(STATUS "Downloading ${_download_numpy_link}")
      if(NOT DEFINED _download_numpy_${NUMPY_VERSION}_md5)
        message(FATAL_ERROR "Selected NUMPY_VERSION [${NUMPY_VERSION}] is not associated with any checksum. Consider updating this CMakeLists.txt setting _download_numpy_${NUMPY_VERSION}_md5 variable")
      endif()
      file(
        DOWNLOAD ${_download_numpy_link} ${_numpy_archive_filepath}
        EXPECTED_MD5 ${_download_numpy_${NUMPY_VERSION}_md5}
        SHOW_PROGRESS
      )
    endif()

    message(STATUS "Extracting ${_numpy_filename}")
    execute_process(COMMAND ${CMAKE_COMMAND} -E tar xfz ${_numpy_archive_filepath}
      WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/..
      RESULT_VARIABLE rv
    )
    if(NOT rv EQUAL 0)
        message(FATAL_ERROR "error: extraction of '${_numpy_filename}' failed")
    endif()
    set(NUMPY_SRC_DIR ${CMAKE_CURRENT_BINARY_DIR}/../${_extracted_numpy_dir})
endif()

get_filename_component(NUMPY_SRC_DIR "${NUMPY_SRC_DIR}" ABSOLUTE)
if(NOT EXISTS ${NUMPY_SRC_DIR}/${_landmark_numpy})
    message(FATAL_ERROR "Failed to locate numpy source.
The searched locations were:
   <CMAKE_CURRENT_SOURCE_DIR>
   <CMAKE_CURRENT_SOURCE_DIR>/numpy-${NUMPY_VERSION}
   <CMAKE_CURRENT_BINARY_DIR>/../numpy-${NUMPY_VERSION}
   <SRC_DIR>
You could try to:
  1) download ${_download_numpy_link}
  2) extract the archive in folder: ${_parent_dir}
  3) Check that file \"${_parent_dir}/${_extracted_numpy_dir}/${_landmark_numpy}\" exists.
  4) re-configure.
If you already downloaded the source, you could try to re-configure this project passing -DNUMPY_SRC_DIR:PATH=/path/to/numpy-{NUMPY_VERSION} using cmake or adding an PATH entry named NUMPY_SRC_DIR from cmake-gui.")
endif()

# Split version into major, minor and patch versions
string(REPLACE "." ";" NUMPY_VERSION_SPLIT ${NUMPY_VERSION})
list(LENGTH NUMPY_VERSION_SPLIT NUMPY_VERSION_COUNT)
if(NUMPY_VERSION_COUNT GREATER_EQUAL 3)
  list(GET NUMPY_VERSION_SPLIT 2 NUMPY_VERSION_PATCH)
else()
  set(NUMPY_VERSION_PATCH 0)
endif()
if(NUMPY_VERSION_COUNT GREATER_EQUAL 2)
  list(GET NUMPY_VERSION_SPLIT 1 NUMPY_VERSION_MINOR)
else()
  set(NUMPY_VERSION_MINOR 0)
endif()
if(NUMPY_VERSION_COUNT GREATER_EQUAL 1)
  list(GET NUMPY_VERSION_SPLIT 0 NUMPY_VERSION_MAJOR)
else()
  set(NUMPY_VERSION_MAJOR 0)
endif()

if(NOT DEFINED _numpy_${NUMPY_VERSION_MAJOR}.${NUMPY_VERSION_MINOR}_c_api_version)
  message(FATAL_ERROR "Selected NUMPY_VERSION [${NUMPY_VERSION}] is not associated with any c api version. Consider updating this CMakeLists.txt setting _numpy_${NUMPY_VERSION_MAJOR}.${NUMPY_VERSION_MINOR}_c_api_version variable")
endif()
set(NUMPY_C_API_VERSION "${_numpy_${NUMPY_VERSION_MAJOR}.${NUMPY_VERSION_MINOR}_c_api_version}")

message(STATUS "NUMPY_SRC_DIR: ${NUMPY_SRC_DIR}")
message(STATUS "NUMPY_VERSION: ${NUMPY_VERSION}")
message(STATUS "NUMPY_C_API_VERSION: ${NUMPY_C_API_VERSION}")

# Check numpy version
if(NOT DEFINED _download_numpy_${NUMPY_VERSION}_md5)
  message(WARNING "warning: selected numpy version '${NUMPY_VERSION}' is not tested. Tested versions `1.26.[1-4]`")
endif()

# We need an external python and cython to build
if (DEFINED ENV{USEPYTHONVERSION_PYTHONLOCATION})
  # Find python used by Azure DevOps CI
  find_program(Python3_EXECUTABLE
    NAMES
      python3 python
    HINTS
      $ENV{USEPYTHONVERSION_PYTHONLOCATION}/bin
      $ENV{USEPYTHONVERSION_PYTHONLOCATION}
  )
else()
  find_package(Python3 COMPONENTS Interpreter)
endif()
find_package(Cython)

# Generate source file for numpy builds
function(numpy_generate_src GENERATED_SRC_FILES)
  foreach(_current_file ${ARGN})
    get_filename_component(_abs_file ${_current_file} ABSOLUTE)
    get_filename_component(_generated_file ${_abs_file} NAME_WE)
    get_filename_component(_generated_file_last_ext ${_abs_file} LAST_EXT)
    get_filename_component(_generated_file_ext ${_abs_file} EXT)
    string(REPLACE "${_generated_file_last_ext}" "" _generated_file_ext "${_generated_file_ext}")
    get_source_file_property(output_location ${_abs_file} OUTPUT_LOCATION)
    if(output_location)
      file(MAKE_DIRECTORY "${output_location}")
      set(_generated_file "${output_location}/${_generated_file}${_generated_file_ext}")
    else()
      set(_generated_file "${CMAKE_BINARY_DIR}/generated/numpy/${_generated_file}${_generated_file_ext}")
    endif()
    if(BUILD_LIBPYTHON_SHARED)
      add_custom_command(OUTPUT ${_generated_file}
        COMMAND "${Python3_EXECUTABLE}"
        ARGS ${NUMPY_SRC_DIR}/numpy/_build_utils/process_src_template.py ${_abs_file} -o ${_generated_file}
        DEPENDS ${_abs_file} VERBATIM
      )
    else()
      file(RELATIVE_PATH _generated_file_rel ${CMAKE_BINARY_DIR} ${_generated_file})
      message(STATUS "NumPy: Generate ${_generated_file_rel}")
      execute_process(
        COMMAND ${Python3_EXECUTABLE} ${NUMPY_SRC_DIR}/numpy/_build_utils/process_src_template.py ${_abs_file} -o ${_generated_file}
        RESULT_VARIABLE _numpy_generate_src_result
      )
      if (_numpy_generate_src_result)
        message(ERROR "process_src_template.py failed with output: ${_numpy_generate_src_result}")
      endif()
    endif()
    list(APPEND _generated_files ${_generated_file})
  endforeach()
  set(${GENERATED_SRC_FILES} ${_generated_files} PARENT_SCOPE)
endfunction()

function(numpy_generate_using_script GENERATED_SRC_FILES)
  set(options)
  set(oneValueArgs SCRIPT OUTPUT_DIR)
  set(multiValueArgs OUTPUT EXTRA_ARGS)
  cmake_parse_arguments(NUMPY_GENERATE_SCRIPT
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  # Check for unparsed arguments (unknown)
  if(NUMPY_GENERATE_SCRIPT_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "numpy_generate_using_script had unparsed arguments")
  endif()

  # Build output filenames
  foreach(_current_file ${NUMPY_GENERATE_SCRIPT_OUTPUT})
    if(NUMPY_GENERATE_SCRIPT_OUTPUT_DIR)
      file(MAKE_DIRECTORY "${NUMPY_GENERATE_SCRIPT_OUTPUT_DIR}")
      set(_generated_file "${NUMPY_GENERATE_SCRIPT_OUTPUT_DIR}/${_current_file}")
    else()
      set(_generated_file "${CMAKE_BINARY_DIR}/generated/numpy/${_current_file}")
    endif()
    list(APPEND _generated_files ${_generated_file})
  endforeach()

  # Find output directory and generation mode
  list(LENGTH NUMPY_GENERATE_SCRIPT_OUTPUT NUMPY_GENERATE_SCRIPT_OUTPUT_COUNT)
  set(_generated_output "${_generated_file}")
  if(NUMPY_GENERATE_SCRIPT_OUTPUT_COUNT GREATER 1)
    get_filename_component(_generated_file_dir ${_generated_file} DIRECTORY)
    set(_generated_output "${_generated_file_dir}")
  endif()

  if(BUILD_LIBPYTHON_SHARED)
    add_custom_command(OUTPUT ${_generated_files}
      COMMAND "${Python3_EXECUTABLE}"
      ARGS ${NUMPY_GENERATE_SCRIPT_SCRIPT} -o ${_generated_output} ${NUMPY_GENERATE_SCRIPT_EXTRA_ARGS}
      VERBATIM
    )
  else()
    foreach(_generated_file ${_generated_files})
      file(RELATIVE_PATH _generated_file_rel ${CMAKE_BINARY_DIR} ${_generated_file})
      message(STATUS "NumPy: Generate ${_generated_file_rel}")
    endforeach()
    execute_process(
      COMMAND ${Python3_EXECUTABLE} ${NUMPY_GENERATE_SCRIPT_SCRIPT} -o ${_generated_output} ${NUMPY_GENERATE_SCRIPT_EXTRA_ARGS}
      RESULT_VARIABLE _numpy_generate_src_result
    )
    if (_numpy_generate_src_result)
      get_filename_component(_numpy_generate_script ${NUMPY_GENERATE_SCRIPT_SCRIPT} NAME)
      message(ERROR "${_numpy_generate_script} failed with output: ${_numpy_generate_src_result}")
    endif()
  endif()

  set(${GENERATED_SRC_FILES} ${_generated_files} PARENT_SCOPE)
endfunction()

function(numpy_generate_tempita GENERATED_FILES)
  foreach(_current_file ${ARGN})
    get_filename_component(_abs_file ${_current_file} ABSOLUTE)
    get_filename_component(_generated_file ${_abs_file} NAME_WE)
    get_filename_component(_generated_file_last_ext ${_abs_file} LAST_EXT)
    get_filename_component(_generated_file_ext ${_abs_file} EXT)
    string(REPLACE "${_generated_file_last_ext}" "" _generated_file_ext "${_generated_file_ext}")
    get_source_file_property(output_location ${_abs_file} OUTPUT_LOCATION)
    if(output_location)
      file(MAKE_DIRECTORY "${output_location}")
      set(_generated_file "${output_location}/${_generated_file}${_generated_file_ext}")
    else()
      set(_generated_file "${CMAKE_BINARY_DIR}/generated/numpy/${_generated_file}${_generated_file_ext}")
    endif()
    if(BUILD_LIBPYTHON_SHARED)
      add_custom_command(OUTPUT ${_generated_file}
              COMMAND "${Python3_EXECUTABLE}"
              ARGS ${NUMPY_SRC_DIR}/numpy/_build_utils/tempita.py ${_abs_file} -o ${_generated_file}
              DEPENDS ${_abs_file} VERBATIM
      )
    else()
      file(RELATIVE_PATH _generated_file_rel ${CMAKE_BINARY_DIR} ${_generated_file})
      message(STATUS "NumPy: Generate ${_generated_file_rel}")
      execute_process(
              COMMAND ${Python3_EXECUTABLE} ${NUMPY_SRC_DIR}/numpy/_build_utils/tempita.py ${_abs_file} -o ${_generated_file}
              RESULT_VARIABLE _numpy_generate_src_result
      )
      if (_numpy_generate_src_result)
        message(ERROR "tempita.py failed with output: ${_numpy_generate_src_result}")
      endif()
    endif()
    list(APPEND _generated_files ${_generated_file})
  endforeach()
  set(${GENERATED_FILES} ${_generated_files} PARENT_SCOPE)
endfunction()

function(numpy_generate_cython GENERATED_C_FILE)
  set(options C CXX PY2 PY3)
  set(oneValueArgs PYX_FILE MODULE_NAME)
  set(multiValueArgs)
  cmake_parse_arguments(NUMPY_GENERATE_CYTHON
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  # Check for unparsed arguments (unknown)
  if(NUMPY_GENERATE_CYTHON_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "numpy_generate_cython had unparsed arguments")
  endif()

  if(NUMPY_GENERATE_CYTHON_C)
    set(_output_syntax "C")
  endif()

  if(NUMPY_GENERATE_CYTHON_CXX)
    set(_output_syntax "CXX")
  endif()

  if(NUMPY_GENERATE_CYTHON_PY2)
    set(_input_syntax "PY2")
  endif()

  if(NUMPY_GENERATE_CYTHON_PY3)
    set(_input_syntax "PY3")
  endif()



    get_filename_component(_abs_file ${NUMPY_GENERATE_CYTHON_PYX_FILE} ABSOLUTE)
    get_filename_component(_generated_file ${_abs_file} NAME_WE)
    get_filename_component(_generated_file_last_ext ${_abs_file} LAST_EXT)
    get_filename_component(_generated_file_ext ${_abs_file} EXT)
    string(REPLACE "${_generated_file_last_ext}" "" _generated_file_ext "${_generated_file_ext}")
    get_source_file_property(output_location ${_abs_file} OUTPUT_LOCATION)
    if(output_location)
      file(MAKE_DIRECTORY "${output_location}")
      set(_generated_file "${output_location}/${_generated_file}${_generated_file_ext}")
    else()
      set(_generated_file "${CMAKE_BINARY_DIR}/generated/numpy/${_generated_file}${_generated_file_ext}")
    endif()
    if(BUILD_LIBPYTHON_SHARED)
      add_custom_command(OUTPUT ${_generated_file}
              COMMAND "${Python3_EXECUTABLE}"
              ARGS ${NUMPY_SRC_DIR}/numpy/_build_utils/tempita.py ${_abs_file} -o ${_generated_file}
              DEPENDS ${_abs_file} VERBATIM
      )
    else()
      file(RELATIVE_PATH _generated_file_rel ${CMAKE_BINARY_DIR} ${_generated_file})
      message(STATUS "NumPy: Generate ${_generated_file_rel}")
      execute_process(
              COMMAND ${Python3_EXECUTABLE} ${NUMPY_SRC_DIR}/numpy/_build_utils/tempita.py ${_abs_file} -o ${_generated_file}
              RESULT_VARIABLE _numpy_generate_src_result
      )
      if (_numpy_generate_src_result)
        message(ERROR "tempita.py failed with output: ${_numpy_generate_src_result}")
      endif()
    endif()

  set(${GENERATED_C_FILE} ${_generated_file} PARENT_SCOPE)
endfunction()



set(numpy_patches_dir "${Python_SOURCE_DIR}/patches/numpy")

function(_apply_numpy_patches _subdir)
  if(NOT EXISTS ${numpy_patches_dir}/${_subdir})
    message(STATUS "Skipping patches: Directory '${numpy_patches_dir}/${_subdir}' does not exist")
    return()
  endif()
  file(GLOB _patches RELATIVE ${numpy_patches_dir} "${numpy_patches_dir}/${_subdir}/*.patch")
  if(NOT _patches)
    return()
  endif()
  message(STATUS "")
  list(SORT _patches)
  foreach(patch IN LISTS _patches)
    set(msg "Applying '${patch}'")
    message(STATUS "${msg}")
    set(applied ${NUMPY_SRC_DIR}/.patches/${patch}.applied)
    # Handle case where source tree was patched using the legacy approach.
    set(legacy_applied ${PROJECT_BINARY_DIR}/CMakeFiles/patches/${patch}.applied)
    if(EXISTS ${legacy_applied})
      set(applied ${legacy_applied})
    endif()
    if(EXISTS ${applied})
      message(STATUS "${msg} - skipping (already applied)")
      continue()
    endif()
    execute_process(
      COMMAND ${PATCH_COMMAND} ${numpy_patches_dir}/${patch}
      WORKING_DIRECTORY ${NUMPY_SRC_DIR}
      RESULT_VARIABLE result
      ERROR_VARIABLE error
      ERROR_STRIP_TRAILING_WHITESPACE
      OUTPUT_VARIABLE output
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(result EQUAL 0)
      message(STATUS "${msg} - done")
      #get_filename_component(_dir ${applied} DIRECTORY)
      get_filename_component(_dir ${applied} PATH)
      execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${_dir})
      execute_process(COMMAND ${CMAKE_COMMAND} -E touch ${applied})
    else()
      message(STATUS "${msg} - failed")
      message(FATAL_ERROR "${output}\n${error}")
    endif()
  endforeach()
  message(STATUS "")
endfunction()

# Apply patches
_apply_numpy_patches("${NUMPY_VERSION_MAJOR}.${NUMPY_VERSION_MINOR}")
_apply_numpy_patches("${NUMPY_VERSION}")
