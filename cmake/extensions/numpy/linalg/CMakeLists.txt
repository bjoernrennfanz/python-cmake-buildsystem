set(_numpy_linalg_python_xerbla_sources
  ${NUMPY_SRC_DIR}/numpy/linalg/lapack_lite/python_xerbla.c
)

set(_numpy_linalg_lapack_lite_sources
  ${NUMPY_SRC_DIR}/numpy/linalg/lapack_lite/f2c.c
  ${NUMPY_SRC_DIR}/numpy/linalg/lapack_lite/f2c_c_lapack.c
  ${NUMPY_SRC_DIR}/numpy/linalg/lapack_lite/f2c_d_lapack.c
  ${NUMPY_SRC_DIR}/numpy/linalg/lapack_lite/f2c_s_lapack.c
  ${NUMPY_SRC_DIR}/numpy/linalg/lapack_lite/f2c_z_lapack.c
  ${NUMPY_SRC_DIR}/numpy/linalg/lapack_lite/f2c_blas.c
  ${NUMPY_SRC_DIR}/numpy/linalg/lapack_lite/f2c_config.c
  ${NUMPY_SRC_DIR}/numpy/linalg/lapack_lite/f2c_lapack.c
)

add_python_extension(lapack_lite
  REQUIRES NUMPY_SRC_DIR
  SOURCES
    ${NUMPY_SRC_DIR}/numpy/linalg/lapack_litemodule.c
    ${_numpy_linalg_python_xerbla_sources}
    ${_numpy_linalg_lapack_lite_sources}
  INCLUDEDIRS
    ${CMAKE_BINARY_DIR}/generated/numpy
    ${NUMPY_SRC_DIR}/numpy/core/include
    ${NUMPY_SRC_DIR}/numpy/core/src/common
  DEFINITIONS
    HAVE_NPY_CONFIG_H
    NPY_INTERNAL_BUILD
    NPY_DISABLE_OPTIMIZATION
)

add_python_extension(_umath_linalg
  REQUIRES NUMPY_SRC_DIR
  SOURCES
    ${NUMPY_SRC_DIR}/numpy/linalg/umath_linalg.cpp
    ${_numpy_linalg_python_xerbla_sources}
    ${_numpy_linalg_lapack_lite_sources}
  INCLUDEDIRS
    ${CMAKE_BINARY_DIR}/generated/numpy
    ${NUMPY_SRC_DIR}/numpy/core/include
    ${NUMPY_SRC_DIR}/numpy/core/src/common
  DEFINITIONS
    HAVE_NPY_CONFIG_H
    NPY_INTERNAL_BUILD
    NPY_DISABLE_OPTIMIZATION
)

# Install numpy linalg files
set(_numpy_linalg_python_sources
  ${NUMPY_SRC_DIR}/numpy/linalg/__init__.py
  ${NUMPY_SRC_DIR}/numpy/linalg/__init__.pyi
  ${NUMPY_SRC_DIR}/numpy/linalg/linalg.py
  ${NUMPY_SRC_DIR}/numpy/linalg/linalg.pyi
)
# Add wrapper for static builds
if(NOT BUILD_LIBPYTHON_SHARED)
  list(APPEND _numpy_linalg_python_sources
    ${CMAKE_CURRENT_SOURCE_DIR}/_umath_linalg.py
    ${CMAKE_CURRENT_SOURCE_DIR}/lapack_lite.py
  )
endif()

foreach(_numpy_linalg_python_source ${_numpy_linalg_python_sources})
  # Copy lib files to build tree
  file(MAKE_DIRECTORY ${PROJECT_BINARY_DIR}/${PYTHONHOME}/numpy/linalg)
  file(COPY ${_numpy_linalg_python_source} DESTINATION ${PROJECT_BINARY_DIR}/${PYTHONHOME}/numpy/linalg)
  # Install
  install(FILES ${_numpy_linalg_python_source} DESTINATION ${PYTHONHOME}/numpy/linalg)
endforeach()

# Install numpy fft test files
set(_numpy_python_fft_source_dirs
  ${NUMPY_SRC_DIR}/numpy/linalg/tests
)

foreach(_numpy_python_fft_source_dir ${_numpy_python_fft_source_dirs})
  # Copy lib files to build tree
  file(MAKE_DIRECTORY ${PROJECT_BINARY_DIR}/${PYTHONHOME}/numpy/linalg)
  file(COPY ${_numpy_python_fft_source_dir} DESTINATION ${PROJECT_BINARY_DIR}/${PYTHONHOME}/numpy/linalg)
  # Install
  install(DIRECTORY ${_numpy_python_fft_source_dir} DESTINATION ${PYTHONHOME}/numpy/linalg)
endforeach()
