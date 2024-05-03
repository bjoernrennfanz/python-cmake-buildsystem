if(WIN32)
  set(SIZEOF_SHORT 2)
  set(SIZEOF_INT 4)
  set(SIZEOF_LONG 4)
  set(SIZEOF_LONG_LONG 8)
  set(SIZEOF_DOUBLE 8)
  set(SIZEOF_LONG_DOUBLE 8)
  set(SIZEOF_FLOAT 4)
  set(SIZEOF_OFF_T 4)
  set(SIZEOF_PY_INTPTR_T 8)
  set(SIZEOF_PY_LONG_LONG 8)
else()
  # Determine python type sizes
  set(CMAKE_EXTRA_INCLUDE_FILES Python.h)
  set(CMAKE_REQUIRED_INCLUDES "${SRC_DIR}/Include" "${CMAKE_BINARY_DIR}/bin")
  check_type_size("Py_intptr_t" SIZEOF_PY_INTPTR_T)
  check_type_size("PY_LONG_LONG" SIZEOF_PY_LONG_LONG)
endif()

# Enable UNIX large file support on 32-bit systems 
# (64 bit off_t, lseek -> lseek64, etc.)
set(_numpy_cflags_large_file_support
  "_FILE_OFFSET_BITS=64"
  "_LARGEFILE_SOURCE=1"
  "_LARGEFILE64_SOURCE=1"
)

# Set common build flags for C and C++ code
set(_numpy_c_args_common
  HAVE_NPY_CONFIG_H
  NPY_INTERNAL_BUILD
  NPY_DISABLE_OPTIMIZATION
  ${_numpy_cflags_large_file_support}
)

# Determine complex types
check_include_files(complex.h HAVE_COMPLEX_H)
if(HAVE_COMPLEX_H)
  set(NPY_USE_C99_COMPLEX True)
  set(CMAKE_EXTRA_INCLUDE_FILES complex.h)
  if(MSVC)
    check_type_size("_Fcomplex" NPY_HAVE_COMPLEX_FLOAT)
    check_type_size("_Dcomplex" NPY_HAVE_COMPLEX_DOUBLE)
    check_type_size("_Lcomplex" NPY_HAVE_COMPLEX_LONG_DOUBLE)
  else()
    check_type_size("complex float" NPY_HAVE_COMPLEX_FLOAT)
    check_type_size("complex double" NPY_HAVE_COMPLEX_DOUBLE)
    check_type_size("complex long double" NPY_HAVE_COMPLEX_LONG_DOUBLE)
  endif()
  if(NPY_HAVE_COMPLEX_FLOAT)
    check_type_size("struct {float __x\; float __y\;}" NPY_SIZEOF_COMPLEX_FLOAT)
  endif()
  if(NPY_HAVE_COMPLEX_DOUBLE)
    check_type_size("struct {double __x\; double __y\;}" NPY_SIZEOF_COMPLEX_DOUBLE)
  endif()
  if(NPY_HAVE_COMPLEX_LONG_DOUBLE)
    check_type_size("struct {long double __x\; long double __y\;}" NPY_SIZEOF_COMPLEX_LONGDOUBLE)
  endif()
endif()

# Determine format of long double
set(_numpy_longdouble_msg "Checking long double format")
try_run(LONGDOUBLE_RUN LONGDOUBLE_COMPILE
  ${PROJECT_BINARY_DIR} ${PROJECT_SOURCE_DIR}/cmake/extensions/numpy/longdoubleformat.c
  RUN_OUTPUT_VARIABLE LONGDOUBLE_FORMAT
)
if(NOT LONGDOUBLE_COMPILE)
  message(FATAL_ERROR "Unknown long double format of size: ${SIZEOF_LONG_DOUBLE}")
endif()
set(HAVE_LDOUBLE_${LONGDOUBLE_FORMAT} True)

message(STATUS "${_numpy_longdouble_msg} - ${LONGDOUBLE_FORMAT}")

# Looking for C99 complex functions
set(_numpy_complex_funcs
  "cabs" "cacos" "cacosh" "carg" "casin" "casinh" "catan"
  "catanh" "cexp" "clog" "cpow" "csqrt"
  # The long double variants (like csinl)  should be mandatory on C11,
  # but are missing in FreeBSD. Issue gh-22850
  "csin" "csinh" "ccos" "ccosh" "ctan" "ctanh"
)
foreach(_numpy_complex_func ${_numpy_complex_funcs})
  string(TOUPPER ${_numpy_complex_func} _numpy_complex_func_upper)
  check_symbol_exists(${_numpy_complex_func} complex.h HAVE_${_numpy_complex_func_upper})
  check_symbol_exists(${_numpy_complex_func}f complex.h HAVE_${_numpy_complex_func_upper}F)
  check_symbol_exists(${_numpy_complex_func}l complex.h HAVE_${_numpy_complex_func_upper}L)
endforeach()

# Check numpy c api version is compatible
execute_process(
  COMMAND "${Python3_EXECUTABLE}" ${NUMPY_SRC_DIR}/numpy/core/code_generators/verify_c_api_version.py --api-version ${NUMPY_C_API_VERSION}
  RESULT_VARIABLE _numpy_verify_c_api_version_result
)
if (_numpy_verify_c_api_version_result)
  message(ERROR "verify_c_api_version.py failed with output: ${_numpy_verify_c_api_version_result}")
endif()
set(NPY_ABI_VERSION "0x${NUMPY_C_API_VERSION}")
set(NPY_API_VERSION "0x${NUMPY_C_API_VERSION}")

# Set visibility attributes
if (HAVE_HIDDEN_VISIBILITY_ATTRIBUTE)
  set(NPY_VISIBILITY_HIDDEN "__attribute__((visibility(\"hidden\")))")
else()
  set(NPY_VISIBILITY_HIDDEN " ")
endif()

# Detect other headers
set(NPY_HAVE_ENDIAN_H ${HAVE_ENDIAN_H})
set(NPY_HAVE_SYS_ENDIAN_H ${HAVE_SYS_ENDIAN_H})
if(MSVC)
  set(NPY_NO_SIGNAL True)
endif()
set(CMAKE_EXTRA_INCLUDE_FILES inttypes.h)
check_type_size("PRIdPTR" NPY_USE_C99_FORMATS)

# Set sizes of used data types
set(NPY_SIZEOF_SHORT ${SIZEOF_SHORT})
set(NPY_SIZEOF_INT ${SIZEOF_INT})
set(NPY_SIZEOF_LONG ${SIZEOF_LONG})
set(NPY_SIZEOF_FLOAT ${SIZEOF_FLOAT})
set(NPY_SIZEOF_COMPLEX_FLOAT ${SIZEOF_COMPLEX_FLOAT})
set(NPY_SIZEOF_DOUBLE ${SIZEOF_DOUBLE})
set(NPY_SIZEOF_COMPLEX_DOUBLE ${SIZEOF_COMPLEX_DOUBLE})
set(NPY_SIZEOF_LONGDOUBLE ${SIZEOF_LONG_DOUBLE})
set(NPY_SIZEOF_COMPLEX_LONGDOUBLE ${SIZEOF_COMPLEX_LONGDOUBLE})
set(NPY_SIZEOF_PY_INTPTR_T ${SIZEOF_PY_INTPTR_T})
set(NPY_SIZEOF_OFF_T ${SIZEOF_OFF_T})
set(NPY_SIZEOF_PY_LONG_LONG ${SIZEOF_PY_LONG_LONG})
set(NPY_SIZEOF_LONGLONG ${SIZEOF_LONG_LONG})

# Generate config files
configure_file(config.h.in ${CMAKE_BINARY_DIR}/generated/numpy/config.h @ONLY)
configure_file(_numpyconfig.h.in ${CMAKE_BINARY_DIR}/generated/numpy/_numpyconfig.h @ONLY)

# Copy the main numpy files
set(_numpy_python_sources
  ${NUMPY_SRC_DIR}/numpy/__init__.cython-30.pxd
  ${NUMPY_SRC_DIR}/numpy/__init__.pxd
  ${NUMPY_SRC_DIR}/numpy/__init__.py
  ${NUMPY_SRC_DIR}/numpy/__init__.pyi
  ${NUMPY_SRC_DIR}/numpy/_distributor_init.py
  ${NUMPY_SRC_DIR}/numpy/_globals.py
  ${NUMPY_SRC_DIR}/numpy/_pytesttester.py
  ${NUMPY_SRC_DIR}/numpy/_pytesttester.pyi
  ${NUMPY_SRC_DIR}/numpy/conftest.py
  ${NUMPY_SRC_DIR}/numpy/ctypeslib.py
  ${NUMPY_SRC_DIR}/numpy/ctypeslib.pyi
  ${NUMPY_SRC_DIR}/numpy/exceptions.py
  ${NUMPY_SRC_DIR}/numpy/exceptions.pyi
  ${NUMPY_SRC_DIR}/numpy/dtypes.py
  ${NUMPY_SRC_DIR}/numpy/dtypes.pyi
  ${NUMPY_SRC_DIR}/numpy/matlib.py
  ${NUMPY_SRC_DIR}/numpy/py.typed
)

foreach(_numpy_python_source ${_numpy_python_sources})
  # Copy lib files to build tree
  file(MAKE_DIRECTORY ${PROJECT_BINARY_DIR}/${PYTHONHOME}/numpy)
  file(COPY ${_numpy_python_source} DESTINATION ${PROJECT_BINARY_DIR}/${PYTHONHOME}/numpy)
  # Install
  install(FILES ${_numpy_python_source} DESTINATION ${PYTHONHOME}/numpy)
endforeach()

# Copy the main numpy directories
set(_numpy_python_source_dirs
  ${NUMPY_SRC_DIR}/numpy/_pyinstaller
  ${NUMPY_SRC_DIR}/numpy/_typing
  ${NUMPY_SRC_DIR}/numpy/_utils
  ${NUMPY_SRC_DIR}/numpy/_core
  ${NUMPY_SRC_DIR}/numpy/array_api
  ${NUMPY_SRC_DIR}/numpy/compat
  ${NUMPY_SRC_DIR}/numpy/doc
  ${NUMPY_SRC_DIR}/numpy/f2py
  ${NUMPY_SRC_DIR}/numpy/lib
  ${NUMPY_SRC_DIR}/numpy/ma
  ${NUMPY_SRC_DIR}/numpy/matrixlib
  ${NUMPY_SRC_DIR}/numpy/polynomial
  ${NUMPY_SRC_DIR}/numpy/testing
  ${NUMPY_SRC_DIR}/numpy/tests
  ${NUMPY_SRC_DIR}/numpy/typing
)

if(PY_VERSION VERSION_LESS "3.12")
  list(APPEND _numpy_python_source_dirs ${NUMPY_SRC_DIR}/numpy/distutils)
endif()

foreach(_numpy_python_source_dir ${_numpy_python_source_dirs})
  # Copy lib files to build tree
  file(MAKE_DIRECTORY ${PROJECT_BINARY_DIR}/${PYTHONHOME}/numpy)
  file(COPY ${_numpy_python_source_dir} DESTINATION ${PROJECT_BINARY_DIR}/${PYTHONHOME}/numpy)
  # Install
  install(DIRECTORY ${_numpy_python_source_dir} DESTINATION ${PYTHONHOME}/numpy)
endforeach()

# Generate and install version.py
execute_process(
  COMMAND ${Python3_EXECUTABLE} ${NUMPY_SRC_DIR}/numpy/_build_utils/gitversion.py --write ${PROJECT_BINARY_DIR}/${PYTHONHOME}/numpy/version.py
  RESULT_VARIABLE _numpy_generate_version_py_result
)
if (_numpy_generate_version_py_result)
  message(ERROR "gitversion.py failed with output: ${_numpy_generate_version_py_result}")
endif()
install(FILES ${PROJECT_BINARY_DIR}/${PYTHONHOME}/numpy/version.py DESTINATION ${PYTHONHOME}/numpy)

# Generate and install __config__.py
set(C_COMP ${CMAKE_C_COMPILER_ID})
set(C_COMP_VERSION ${CMAKE_C_COMPILER_VERSION})
set(C_COMP_LINKER_ID ${CMAKE_C_COMPILER_ID})
get_filename_component(C_COMP_CMD_ARRAY ${CMAKE_C_COMPILER} NAME)

set(CPP_COMP ${CMAKE_CXX_COMPILER_ID})
set(CPP_COMP_VERSION ${CMAKE_CXX_COMPILER_VERSION})
set(CPP_COMP_LINKER_ID ${CMAKE_CXX_COMPILER_ID})
get_filename_component(CPP_COMP_CMD_ARRAY ${CMAKE_CXX_COMPILER} NAME)

test_big_endian(_numpy_big_endian)
if(_numpy_big_endian)
  set(HOST_CPU_ENDIAN big)
  set(BUILD_CPU_ENDIAN big)
else()
  set(HOST_CPU_ENDIAN little)
  set(BUILD_CPU_ENDIAN little)
endif()

set(CROSS_COMPILED False)

string(TOLOWER ${CMAKE_HOST_SYSTEM_PROCESSOR} HOST_CPU)
string(TOLOWER ${CMAKE_HOST_SYSTEM_PROCESSOR} HOST_CPU_FAMILY)

string(TOLOWER ${CMAKE_SYSTEM_PROCESSOR} BUILD_CPU)
string(TOLOWER ${CMAKE_SYSTEM_PROCESSOR} BUILD_CPU_FAMILY)

string(TOLOWER ${CMAKE_SYSTEM_NAME} BUILD_CPU_SYSTEM)
string(TOLOWER ${CMAKE_HOST_SYSTEM_NAME} HOST_CPU_SYSTEM)

configure_file(${NUMPY_SRC_DIR}/numpy/__config__.py.in ${PROJECT_BINARY_DIR}/${PYTHONHOME}/numpy/__config__.py @ONLY)

add_subdirectory(core)
add_subdirectory(fft)
add_subdirectory(linalg)