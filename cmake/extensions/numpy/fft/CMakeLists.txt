add_python_extension(_pocketfft_internal
  REQUIRES NUMPY_SRC_DIR
  SOURCES
    ${NUMPY_SRC_DIR}/numpy/fft/_pocketfft.c
  INCLUDEDIRS
    ${CMAKE_BINARY_DIR}/generated/numpy
    ${NUMPY_SRC_DIR}/numpy/core/include
    ${NUMPY_SRC_DIR}/numpy/core/src/common
  DEFINITIONS
    HAVE_NPY_CONFIG_H
    NPY_INTERNAL_BUILD
    NPY_DISABLE_OPTIMIZATION
)

# Install numpy fft files
set(_numpy_fft_python_sources
  ${NUMPY_SRC_DIR}/numpy/fft/__init__.py
  ${NUMPY_SRC_DIR}/numpy/fft/__init__.pyi
  ${NUMPY_SRC_DIR}/numpy/fft/_pocketfft.py
  ${NUMPY_SRC_DIR}/numpy/fft/_pocketfft.pyi
  ${NUMPY_SRC_DIR}/numpy/fft/helper.py
  ${NUMPY_SRC_DIR}/numpy/fft/helper.pyi
)
# Add wrapper for static builds
if(NOT BUILD_LIBPYTHON_SHARED)
  list(APPEND _numpy_fft_python_sources
    ${CMAKE_CURRENT_SOURCE_DIR}/_pocketfft_internal.py
  )
endif()

foreach(_numpy_fft_python_source ${_numpy_fft_python_sources})
  # Copy lib files to build tree
  file(MAKE_DIRECTORY ${PROJECT_BINARY_DIR}/${PYTHONHOME}/numpy/fft)
  file(COPY ${_numpy_fft_python_source} DESTINATION ${PROJECT_BINARY_DIR}/${PYTHONHOME}/numpy/fft)
  # Install
  install(FILES ${_numpy_fft_python_source} DESTINATION ${PYTHONHOME}/numpy/fft)
endforeach()

# Install numpy fft test files
set(_numpy_python_fft_source_dirs
  ${NUMPY_SRC_DIR}/numpy/fft/tests
)

foreach(_numpy_python_fft_source_dir ${_numpy_python_fft_source_dirs})
  # Copy lib files to build tree
  file(MAKE_DIRECTORY ${PROJECT_BINARY_DIR}/${PYTHONHOME}/numpy/fft)
  file(COPY ${_numpy_python_fft_source_dir} DESTINATION ${PROJECT_BINARY_DIR}/${PYTHONHOME}/numpy/fft)
  # Install
  install(DIRECTORY ${_numpy_python_fft_source_dir} DESTINATION ${PYTHONHOME}/numpy/fft)
endforeach()
