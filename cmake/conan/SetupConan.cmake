find_program(conanexecutable "conan")

if (NOT conanexecutable)
  message(WARNING "Tool conan is not installed. Check README.md for build instructions without conan.")
else()
  message(STATUS "Found conan. Installing dependencies.")
  include(${CMAKE_CURRENT_LIST_DIR}/ConanWrapper.cmake)

  # Check if CONAN_EXPORTED set by cmake generator
  if (NOT CONAN_EXPORTED)
    # Development case, conan is called from cmake
    conan_cmake_autodetect(settings)

    # Filter conan setting compiler.cppstd, because its experimental yet.
    list(FILTER settings EXCLUDE REGEX "^compiler\\.cppstd=.*")

    # Check if build missing conan packages enabled
    if (PYTHON_CMAKE_BUILD_CONAN)
      set(_BUILD "BUILD;missing")
    endif()

    # Let Release with Debug Info configuration use Release packages
    if(${CMAKE_BUILD_TYPE} MATCHES "RelWithDebInfo")
      list(FILTER settings EXCLUDE REGEX "^build_type=.*")
      list(APPEND settings "build_type=Release")
    endif()

    conan_cmake_install(
      UPDATE
      PATH_OR_REFERENCE ${CMAKE_SOURCE_DIR}
      INSTALL_FOLDER ${CMAKE_BINARY_DIR}
      SETTINGS ${settings} arch=${PYTHON_CMAKE_CONAN_ARCH}
      ${_PROFILE_BUILD}
      ${_PROFILE_HOST}
      ${_BUILD}
    )
    
  endif() # NOT CONAN_EXPORTED

  include(${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
  conan_basic_setup(TARGETS NO_OUTPUT_DIRS KEEP_RPATHS SKIP_STD SKIP_FPIC)

  include(${CMAKE_BINARY_DIR}/conan_paths.cmake)
endif() # NOT conanexecutable