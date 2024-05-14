# Detect opencv source directory
set(_landmark_opencv "modules/core/include/opencv2/core/version.hpp") # CMake will look for this file.
if(NOT (OPENCV_SRC_DIR AND EXISTS ${OPENCV_SRC_DIR}/${_landmark_opencv}))
  foreach(dirname
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/opencv-${OPENCV_VERSION}
    ${CMAKE_CURRENT_BINARY_DIR}/../opencv-${OPENCV_VERSION})
    set(OPENCV_SRC_DIR ${dirname})
        if(EXISTS ${OPENCV_SRC_DIR}/${_landmark_opencv})
            break()
        endif()
    endforeach()
endif()

# Download opencv sources
set(_download_opencv_link "https://github.com/opencv/opencv/archive/refs/tags/${OPENCV_VERSION}.tar.gz")

# Set OpenCV 4.8.x md5 checksums
set(_download_opencv_4.8.1_md5 "7e3b6b5046e4e31226bbf4872091201c")
set(_download_opencv_4.8.0_md5 "1c915dc6c36dd4c674d9379e9470ff8b")

set(_extracted_opencv_dir "opencv-${OPENCV_VERSION}")

if(NOT EXISTS ${OPENCV_SRC_DIR}/${_landmark_opencv} AND DOWNLOAD_SOURCES)
    get_filename_component(_opencv_filename ${_download_opencv_link} NAME)
    set(_opencv_archive_filepath ${CMAKE_CURRENT_BINARY_DIR}/../opencv-${_opencv_filename})
    get_filename_component(_opencv_filename ${_opencv_archive_filepath} NAME)

    if(EXISTS "${_opencv_archive_filepath}")
      message(STATUS "${_opencv_archive_filepath} already downloaded")
    else()
      message(STATUS "Downloading ${_download_opencv_link}")
      if(NOT DEFINED _download_opencv_${OPENCV_VERSION}_md5)
        message(FATAL_ERROR "Selected OPENCV_VERSION [${OPENCV_VERSION}] is not associated with any checksum. Consider updating this CMakeLists.txt setting _download_opencv_${OPENCV_VERSION}_md5 variable")
      endif()
      file(
        DOWNLOAD ${_download_opencv_link} ${_opencv_archive_filepath}
        EXPECTED_MD5 ${_download_opencv_${OPENCV_VERSION}_md5}
        SHOW_PROGRESS
      )
    endif()

    message(STATUS "Extracting ${_opencv_filename}")
    execute_process(COMMAND ${CMAKE_COMMAND} -E tar xfz ${_opencv_archive_filepath}
      WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/..
      RESULT_VARIABLE rv
    )
    if(NOT rv EQUAL 0)
        message(FATAL_ERROR "error: extraction of '${_opencv_filename}' failed")
    endif()
    set(OPENCV_SRC_DIR ${CMAKE_CURRENT_BINARY_DIR}/../${_extracted_opencv_dir})
endif()

get_filename_component(OPENCV_SRC_DIR "${OPENCV_SRC_DIR}" ABSOLUTE)
if(NOT EXISTS ${OPENCV_SRC_DIR}/${_landmark_opencv})
    message(FATAL_ERROR "Failed to locate opencv source.
The searched locations were:
   <CMAKE_CURRENT_SOURCE_DIR>
   <CMAKE_CURRENT_SOURCE_DIR>/opencv-${OPENCV_VERSION}
   <CMAKE_CURRENT_BINARY_DIR>/../opencv-${OPENCV_VERSION}
   <SRC_DIR>
You could try to:
  1) download ${_download_opencv_link}
  2) extract the archive in folder: ${_parent_dir}
  3) Check that file \"${_parent_dir}/${_extracted_opencv_dir}/${_landmark_opencv}\" exists.
  4) re-configure.
If you already downloaded the source, you could try to re-configure this project passing -DOPENCV_SRC_DIR:PATH=/path/to/opencv-{OPENCV_VERSION} using cmake or adding an PATH entry named OPENCV_SRC_DIR from cmake-gui.")
endif()

# Split version into major, minor and patch versions
string(REPLACE "." ";" OPENCV_VERSION_SPLIT ${OPENCV_VERSION})
list(LENGTH OPENCV_VERSION_SPLIT OPENCV_VERSION_COUNT)
if(OPENCV_VERSION_COUNT GREATER_EQUAL 3)
  list(GET OPENCV_VERSION_SPLIT 2 OPENCV_VERSION_PATCH)
else()
  set(OPENCV_VERSION_PATCH 0)
endif()
if(OPENCV_VERSION_COUNT GREATER_EQUAL 2)
  list(GET OPENCV_VERSION_SPLIT 1 OPENCV_VERSION_MINOR)
else()
  set(OPENCV_VERSION_MINOR 0)
endif()
if(OPENCV_VERSION_COUNT GREATER_EQUAL 1)
  list(GET OPENCV_VERSION_SPLIT 0 OPENCV_VERSION_MAJOR)
else()
  set(OPENCV_VERSION_MAJOR 0)
endif()

message(STATUS "OPENCV_SRC_DIR: ${OPENCV_SRC_DIR}")
message(STATUS "OPENCV_VERSION: ${OPENCV_VERSION}")

set(opencv_patches_dir "${Python_SOURCE_DIR}/patches/opencv")

function(_apply_opencv_patches _subdir)
  if(NOT EXISTS ${opencv_patches_dir}/${_subdir})
    message(STATUS "Skipping patches: Directory '${opencv_patches_dir}/${_subdir}' does not exist")
    return()
  endif()
  file(GLOB _patches RELATIVE ${opencv_patches_dir} "${opencv_patches_dir}/${_subdir}/*.patch")
  if(NOT _patches)
    return()
  endif()
  message(STATUS "")
  list(SORT _patches)
  foreach(patch IN LISTS _patches)
    set(msg "Applying '${patch}'")
    message(STATUS "${msg}")
    set(applied ${OPENCV_SRC_DIR}/.patches/${patch}.applied)
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
      COMMAND ${PATCH_COMMAND} ${opencv_patches_dir}/${patch}
      WORKING_DIRECTORY ${OPENCV_SRC_DIR}
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
_apply_opencv_patches("${OPENCV_VERSION_MAJOR}.${OPENCV_VERSION_MINOR}")
_apply_opencv_patches("${OPENCV_VERSION}")