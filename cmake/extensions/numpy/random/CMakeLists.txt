# Build npyrandom static library
add_library(npyrandom STATIC
  ${NUMPY_SRC_DIR}/numpy/random/src/distributions/logfactorial.c
  ${NUMPY_SRC_DIR}/numpy/random/src/distributions/distributions.c
  ${NUMPY_SRC_DIR}/numpy/random/src/distributions/random_mvhg_count.c
  ${NUMPY_SRC_DIR}/numpy/random/src/distributions/random_mvhg_marginals.c
  ${NUMPY_SRC_DIR}/numpy/random/src/distributions/random_hypergeometric.c
)

target_include_directories(npyrandom
  PUBLIC
    ${CMAKE_BINARY_DIR}/generated/numpy
    ${NUMPY_SRC_DIR}/numpy/core/include
    ${NUMPY_SRC_DIR}/numpy/core/src/npymath
    ${NUMPY_SRC_DIR}/numpy/core/src/common
)

target_compile_definitions(npyrandom
  PUBLIC ${_numpy_c_args_common}
)

# Build Cython extensions for numpy.random
set_source_files_properties(
  ${NUMPY_SRC_DIR}/numpy/random/_bounded_integers.pxd.in
  ${NUMPY_SRC_DIR}/numpy/random/_bounded_integers.pyx.in
  PROPERTIES
    OUTPUT_LOCATION ${CMAKE_BINARY_DIR}/generated/numpy/random
)

numpy_generate_tempita(_generated_numpy_random_bounded_integers_pyd
  ${NUMPY_SRC_DIR}/numpy/random/_bounded_integers.pxd.in
)

numpy_generate_tempita(_generated_numpy_random_bounded_integers_pyx
  ${NUMPY_SRC_DIR}/numpy/random/_bounded_integers.pyx.in
)

numpy_generate_cython(_generated_numpy_random_bounded_integers
  PYX_FILE ${_generated_numpy_random_bounded_integers_pyx}
  MODULE_NAME _bounded_integers
  PY3 C
)

add_python_extension(_bounded_integers
  REQUIRES NUMPY_SRC_DIR
  SOURCES
    ${_generated_numpy_random_bounded_integers}
  INCLUDEDIRS
    ${CMAKE_BINARY_DIR}/generated/numpy
    ${NUMPY_SRC_DIR}/numpy/core/include
    ${NUMPY_SRC_DIR}/numpy/random
  DEFINITIONS
    NPY_NO_DEPRECATED_API=0
  LIBRARIES
    $<TARGET_FILE:npymath>
    $<TARGET_FILE:npyrandom>
)

numpy_generate_cython(_generated_numpy_random_common
  PYX_FILE ${NUMPY_SRC_DIR}/numpy/random/_common.pyx
  MODULE_NAME _common
  PY3 C
)

add_python_extension(_common
  REQUIRES NUMPY_SRC_DIR
  SOURCES
    ${_generated_numpy_random_common}
  INCLUDEDIRS
    ${CMAKE_BINARY_DIR}/generated/numpy
    ${NUMPY_SRC_DIR}/numpy/core/include
    ${NUMPY_SRC_DIR}/numpy/random
  DEFINITIONS
    NPY_NO_DEPRECATED_API=0
  LIBRARIES
    $<TARGET_FILE:npyrandom>
)

numpy_generate_cython(_generated_numpy_random_mt19937
  PYX_FILE ${NUMPY_SRC_DIR}/numpy/random/_mt19937.pyx
  MODULE_NAME _mt19937
  PY3 C
)

add_python_extension(_mt19937
  REQUIRES NUMPY_SRC_DIR
  SOURCES
    ${_generated_numpy_random_mt19937}
    ${NUMPY_SRC_DIR}/numpy/random/src/mt19937/mt19937.c
    ${NUMPY_SRC_DIR}/numpy/random/src/mt19937/mt19937-jump.c
  INCLUDEDIRS
    ${CMAKE_BINARY_DIR}/generated/numpy
    ${NUMPY_SRC_DIR}/numpy/core/include
    ${NUMPY_SRC_DIR}/numpy/random
  DEFINITIONS
    NPY_NO_DEPRECATED_API=0
  LIBRARIES
    $<TARGET_FILE:npyrandom>
)

numpy_generate_cython(_generated_numpy_random_philox
  PYX_FILE ${NUMPY_SRC_DIR}/numpy/random/_philox.pyx
  MODULE_NAME _philox
  PY3 C
)

add_python_extension(_philox
  REQUIRES NUMPY_SRC_DIR
  SOURCES
    ${_generated_numpy_random_philox}
    ${NUMPY_SRC_DIR}/numpy/random/src/philox/philox.c
  INCLUDEDIRS
    ${CMAKE_BINARY_DIR}/generated/numpy
    ${NUMPY_SRC_DIR}/numpy/core/include
    ${NUMPY_SRC_DIR}/numpy/random
  DEFINITIONS
    NPY_NO_DEPRECATED_API=0
  LIBRARIES
    $<TARGET_FILE:npyrandom>
)

numpy_generate_cython(_generated_numpy_random_pcg64
  PYX_FILE ${NUMPY_SRC_DIR}/numpy/random/_pcg64.pyx
  MODULE_NAME _pcg64
  PY3 C
)

add_python_extension(_pcg64
  REQUIRES NUMPY_SRC_DIR
  SOURCES
    ${_generated_numpy_random_pcg64}
    ${NUMPY_SRC_DIR}/numpy/random/src/pcg64/pcg64.c
  INCLUDEDIRS
    ${CMAKE_BINARY_DIR}/generated/numpy
    ${NUMPY_SRC_DIR}/numpy/core/include
    ${NUMPY_SRC_DIR}/numpy/random
  DEFINITIONS
    NPY_NO_DEPRECATED_API=0
  LIBRARIES
    $<TARGET_FILE:npyrandom>
)

numpy_generate_cython(_generated_numpy_random_sfc64
  PYX_FILE ${NUMPY_SRC_DIR}/numpy/random/_sfc64.pyx
  MODULE_NAME _sfc64
  PY3 C
)

add_python_extension(_sfc64
  REQUIRES NUMPY_SRC_DIR
  SOURCES
    ${_generated_numpy_random_sfc64}
    ${NUMPY_SRC_DIR}/numpy/random/src/sfc64/sfc64.c
  INCLUDEDIRS
    ${CMAKE_BINARY_DIR}/generated/numpy
    ${NUMPY_SRC_DIR}/numpy/core/include
    ${NUMPY_SRC_DIR}/numpy/random
  DEFINITIONS
    NPY_NO_DEPRECATED_API=0
  LIBRARIES
    $<TARGET_FILE:npyrandom>
)

numpy_generate_cython(_generated_numpy_random_bit_generator
  PYX_FILE ${NUMPY_SRC_DIR}/numpy/random/bit_generator.pyx
  MODULE_NAME bit_generator
  PY3 C
)

add_python_extension(bit_generator
  REQUIRES NUMPY_SRC_DIR
  SOURCES
    ${_generated_numpy_random_bit_generator}
  INCLUDEDIRS
    ${CMAKE_BINARY_DIR}/generated/numpy
    ${NUMPY_SRC_DIR}/numpy/core/include
    ${NUMPY_SRC_DIR}/numpy/random
  DEFINITIONS
    NPY_NO_DEPRECATED_API=0
  LIBRARIES
    $<TARGET_FILE:npyrandom>
)

# The COPY usage here is needed because these .pyx files are imports
# from _bounded_integers, and its pxd file is only present in the build directory
file(COPY
  ${NUMPY_SRC_DIR}/numpy/random/__init__.py
  ${NUMPY_SRC_DIR}/numpy/random/__init__.pxd
  ${NUMPY_SRC_DIR}/numpy/random/_common.pxd
  ${NUMPY_SRC_DIR}/numpy/random/bit_generator.pxd
  ${NUMPY_SRC_DIR}/numpy/random/c_distributions.pxd
  ${NUMPY_SRC_DIR}/numpy/random/_generator.pyx
  ${NUMPY_SRC_DIR}/numpy/random/mtrand.pyx
  DESTINATION ${CMAKE_BINARY_DIR}/generated/numpy/random
)

numpy_generate_cython(_generated_numpy_random_generator
  PYX_FILE ${CMAKE_BINARY_DIR}/generated/numpy/random/_generator.pyx
  MODULE_NAME _generator
  PY3 C
)

add_python_extension(_generator
  REQUIRES NUMPY_SRC_DIR
  SOURCES
    ${_generated_numpy_random_generator}
  INCLUDEDIRS
    ${CMAKE_BINARY_DIR}/generated/numpy
    ${NUMPY_SRC_DIR}/numpy/core/include
    ${NUMPY_SRC_DIR}/numpy/random
  DEFINITIONS
    NPY_NO_DEPRECATED_API=0
  LIBRARIES
    $<TARGET_FILE:npymath>
    $<TARGET_FILE:npyrandom>
)

numpy_generate_cython(_generated_numpy_random_mtrand
  PYX_FILE ${CMAKE_BINARY_DIR}/generated/numpy/random/mtrand.pyx
  MODULE_NAME mtrand
  PY3 C
)

add_python_extension(mtrand
  REQUIRES NUMPY_SRC_DIR
  SOURCES
    ${_generated_numpy_random_mtrand}
    ${NUMPY_SRC_DIR}/numpy/random/src/distributions/distributions.c
    ${NUMPY_SRC_DIR}/numpy/random/src/legacy/legacy-distributions.c
  INCLUDEDIRS
    ${CMAKE_BINARY_DIR}/generated/numpy
    ${NUMPY_SRC_DIR}/numpy/core/include
    ${NUMPY_SRC_DIR}/numpy/random
  DEFINITIONS
    NP_RANDOM_LEGACY=1
    NPY_NO_DEPRECATED_API=0
  LIBRARIES
    $<TARGET_FILE:npymath>
)

# Install numpy random files
set(_numpy_random_python_sources
  ${NUMPY_SRC_DIR}/numpy/random/__init__.pxd
  ${NUMPY_SRC_DIR}/numpy/random/__init__.py
  ${NUMPY_SRC_DIR}/numpy/random/__init__.pyi
  ${NUMPY_SRC_DIR}/numpy/random/_common.pxd
  ${NUMPY_SRC_DIR}/numpy/random/_generator.pyi
  ${NUMPY_SRC_DIR}/numpy/random/_mt19937.pyi
  ${NUMPY_SRC_DIR}/numpy/random/_pcg64.pyi
  ${NUMPY_SRC_DIR}/numpy/random/_pickle.py
  ${NUMPY_SRC_DIR}/numpy/random/_philox.pyi
  ${NUMPY_SRC_DIR}/numpy/random/_sfc64.pyi
  ${NUMPY_SRC_DIR}/numpy/random/bit_generator.pxd
  ${NUMPY_SRC_DIR}/numpy/random/bit_generator.pyi
  ${NUMPY_SRC_DIR}/numpy/random/c_distributions.pxd
  ${NUMPY_SRC_DIR}/numpy/random/LICENSE.md
  ${NUMPY_SRC_DIR}/numpy/random/mtrand.pyi
)

# Add wrapper for static builds
if(NOT BUILD_LIBPYTHON_SHARED)
  list(APPEND _numpy_random_python_sources
    ${CMAKE_CURRENT_SOURCE_DIR}/_common.py
    ${CMAKE_CURRENT_SOURCE_DIR}/_sfc64.py
    ${CMAKE_CURRENT_SOURCE_DIR}/_mt19937.py
    ${CMAKE_CURRENT_SOURCE_DIR}/_generator.py
    ${CMAKE_CURRENT_SOURCE_DIR}/_philox.py
    ${CMAKE_CURRENT_SOURCE_DIR}/_pcg64.py
    ${CMAKE_CURRENT_SOURCE_DIR}/mtrand.py
    ${CMAKE_CURRENT_SOURCE_DIR}/_bounded_integers.py
    ${CMAKE_CURRENT_SOURCE_DIR}/bit_generator.py
  )
endif()

foreach(_numpy_random_python_source ${_numpy_random_python_sources})
  # Copy lib files to build tree
  file(MAKE_DIRECTORY ${PROJECT_BINARY_DIR}/${PYTHONHOME}/numpy/random)
  file(COPY ${_numpy_random_python_source} DESTINATION ${PROJECT_BINARY_DIR}/${PYTHONHOME}/numpy/random)
  # Install
  install(FILES ${_numpy_random_python_source} DESTINATION ${PYTHONHOME}/numpy/random)
endforeach()

set(_numpy_random_test_python_sources
  ${NUMPY_SRC_DIR}/numpy/random/tests/__init__.py
  ${NUMPY_SRC_DIR}/numpy/random/tests/test_direct.py
  ${NUMPY_SRC_DIR}/numpy/random/tests/test_extending.py
  ${NUMPY_SRC_DIR}/numpy/random/tests/test_generator_mt19937.py
  ${NUMPY_SRC_DIR}/numpy/random/tests/test_generator_mt19937_regressions.py
  ${NUMPY_SRC_DIR}/numpy/random/tests/test_random.py
  ${NUMPY_SRC_DIR}/numpy/random/tests/test_randomstate.py
  ${NUMPY_SRC_DIR}/numpy/random/tests/test_randomstate_regression.py
  ${NUMPY_SRC_DIR}/numpy/random/tests/test_regression.py
  ${NUMPY_SRC_DIR}/numpy/random/tests/test_seed_sequence.py
  ${NUMPY_SRC_DIR}/numpy/random/tests/test_smoke.py
)

foreach(_numpy_random_test_python_source ${_numpy_random_test_python_sources})
  # Copy lib files to build tree
  file(MAKE_DIRECTORY ${PROJECT_BINARY_DIR}/${PYTHONHOME}/numpy/random/tests)
  file(COPY ${_numpy_random_test_python_source} DESTINATION ${PROJECT_BINARY_DIR}/${PYTHONHOME}/numpy/random/tests)
  # Install
  install(FILES ${_numpy_random_test_python_source} DESTINATION ${PYTHONHOME}/numpy/random/tests)
endforeach()

set(_numpy_random_test_data_python_sources
  ${NUMPY_SRC_DIR}/numpy/random/tests/data/__init__.py
  ${NUMPY_SRC_DIR}/numpy/random/tests/data/mt19937-testset-1.csv
  ${NUMPY_SRC_DIR}/numpy/random/tests/data/mt19937-testset-2.csv
  ${NUMPY_SRC_DIR}/numpy/random/tests/data/pcg64-testset-1.csv
  ${NUMPY_SRC_DIR}/numpy/random/tests/data/pcg64-testset-2.csv
  ${NUMPY_SRC_DIR}/numpy/random/tests/data/pcg64dxsm-testset-1.csv
  ${NUMPY_SRC_DIR}/numpy/random/tests/data/pcg64dxsm-testset-2.csv
  ${NUMPY_SRC_DIR}/numpy/random/tests/data/philox-testset-1.csv
  ${NUMPY_SRC_DIR}/numpy/random/tests/data/philox-testset-2.csv
  ${NUMPY_SRC_DIR}/numpy/random/tests/data/sfc64-testset-1.csv
  ${NUMPY_SRC_DIR}/numpy/random/tests/data/sfc64-testset-2.csv
)

foreach(_numpy_random_test_data_python_source ${_numpy_random_test_data_python_sources})
  # Copy lib files to build tree
  file(MAKE_DIRECTORY ${PROJECT_BINARY_DIR}/${PYTHONHOME}/numpy/random/tests/data)
  file(COPY ${_numpy_random_test_data_python_source} DESTINATION ${PROJECT_BINARY_DIR}/${PYTHONHOME}/numpy/random/tests/data)
  # Install
  install(FILES ${_numpy_random_test_data_python_source} DESTINATION ${PYTHONHOME}/numpy/random/tests/data)
endforeach()