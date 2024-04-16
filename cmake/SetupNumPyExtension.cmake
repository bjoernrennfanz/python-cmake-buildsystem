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

# numpy 1.26.x
set(_download_numpy_1.26.4_md5 "19550cbe7bedd96a928da9d4ad69509d")
set(_download_numpy_1.26.3_md5 "1c915dc6c36dd4c674d9379e9470ff8b")
set(_download_numpy_1.26.2_md5 "8f6446a32e47953a03f8fe8533e21e98")
set(_download_numpy_1.26.1_md5 "2d770f4c281d405b690c4bcb3dbe99e2")

set(_extracted_numpy_dir "numpy-${NUMPY_VERSION}")

if(NOT EXISTS ${NUMPY_SRC_DIR}/${_landmark_numpy} AND DOWNLOAD_SOURCES)
    get_filename_component(_numpy_filename ${_download_numpy_link} NAME)
    set(_numpy_archive_filepath ${CMAKE_CURRENT_BINARY_DIR}/../${_numpy_filename})
    if(EXISTS "${_numpy_archive_filepath}")
      message(STATUS "${_numpy_archive_filepath} already downloaded")
    else()
      message(STATUS "Downloading ${_download_numpy_link}")
      if(NOT DEFINED _download_numpy_${NUMPY_VERSION}_md5)
        message(FATAL_ERROR "Selected PY_VERSION [${PY_VERSION}] is not associated with any checksum. Consider updating this CMakeLists.txt setting _download_${PY_VERSION}_md5 variable")
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

message(STATUS "NUMPY_SRC_DIR: ${NUMPY_SRC_DIR}")
message(STATUS "NUMPY_VERSION: ${NUMPY_VERSION}")

# Check numpy version
if(NOT DEFINED _download_numpy_${NUMPY_VERSION}_md5)
  message(WARNING "warning: selected numpy version '${NUMPY_VERSION}' is not tested. Tested versions `1.26.[1-4]`")
endif()