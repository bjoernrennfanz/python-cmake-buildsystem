# Determine python type sizes
set(CMAKE_EXTRA_INCLUDE_FILES Python.h)
set(CMAKE_REQUIRED_INCLUDES "${SRC_DIR}/Include" "${CMAKE_BINARY_DIR}/bin")
check_type_size("Py_intptr_t" NPY_SIZEOF_PY_INTPTR_T)
check_type_size("PY_LONG_LONG" NPY_SIZEOF_PY_LONG_LONG)

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
  set(NPY_VISIBILITY_HIDDEN "")
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
set(NPY_SIZEOF_PY_INTPTR_T ${NPY_SIZEOF_PY_INTPTR_T})
set(NPY_SIZEOF_OFF_T ${SIZEOF_OFF_T})
set(NPY_SIZEOF_PY_LONG_LONG ${NPY_SIZEOF_PY_LONG_LONG})
set(NPY_SIZEOF_LONGLONG ${SIZEOF_LONG_LONG})

# Generate config files
configure_file(config.h.in ${CMAKE_BINARY_DIR}/generated/numpy/config.h @ONLY)
configure_file(_numpyconfig.h.in ${CMAKE_BINARY_DIR}/generated/numpy/_numpyconfig.h @ONLY)

# Build npymath static library
numpy_generate_src(numpy_npymath_sources
  ${NUMPY_SRC_DIR}/numpy/core/src/npymath/npy_math_internal.h.src
  ${NUMPY_SRC_DIR}/numpy/core/src/npymath/ieee754.c.src
  ${NUMPY_SRC_DIR}/numpy/core/src/npymath/npy_math_complex.c.src
)

add_library(npymath STATIC
  ${numpy_npymath_sources}
  ${NUMPY_SRC_DIR}/numpy/core/src/npymath/halffloat.cpp
  ${NUMPY_SRC_DIR}/numpy/core/src/npymath/npy_math.c
)

target_include_directories(npymath
  PUBLIC
    ${CMAKE_BINARY_DIR}/generated/numpy
    ${NUMPY_SRC_DIR}/numpy/core/include
    ${NUMPY_SRC_DIR}/numpy/core/src/npymath
    ${NUMPY_SRC_DIR}/numpy/core/src/common
)

target_compile_definitions(npymath
  PUBLIC
    HAVE_NPY_CONFIG_H
    NPY_INTERNAL_BUILD
    NPY_DISABLE_OPTIMIZATION
)

# Generate NumPy C API sources
numpy_generate_using_script(_generated_src_umath_api_c
  SCRIPT ${NUMPY_SRC_DIR}/numpy/core/code_generators/generate_umath.py
  OUTPUT __umath_generated.c
)

numpy_generate_using_script(_generated_src_umath_doc_h
  SCRIPT ${NUMPY_SRC_DIR}/numpy/core/code_generators/generate_umath_doc.py
  OUTPUT _umath_doc_generated.h
)

numpy_generate_using_script(_generated_src_multiarray_api
  SCRIPT ${NUMPY_SRC_DIR}/numpy/core/code_generators/generate_numpy_api.py
  OUTPUT
    __multiarray_api.c
    __multiarray_api.h
  EXTRA_ARGS
    --ignore
    ${_generated_src_umath_api_c}
)
list(FILTER _generated_src_multiarray_api EXCLUDE REGEX "^.*__multiarray_api.c")

numpy_generate_using_script(_generated_src_ufunc_api
  SCRIPT ${NUMPY_SRC_DIR}/numpy/core/code_generators/generate_ufunc_api.py
  OUTPUT
    __ufunc_api.c
    __ufunc_api.h
)
list(FILTER _generated_src_ufunc_api EXCLUDE REGEX "^.*__ufunc_api.c")

# Build _multiarray_umath module
numpy_generate_src(_generated_src_multiarray_umath_common
  ${NUMPY_SRC_DIR}/numpy/core/src/common/templ_common.h.src
)
list(APPEND _generated_src_multiarray_umath_common
  ${NUMPY_SRC_DIR}/numpy/core/src/common/array_assign.c
  ${NUMPY_SRC_DIR}/numpy/core/src/common/mem_overlap.c
  ${NUMPY_SRC_DIR}/numpy/core/src/common/npy_argparse.c
  ${NUMPY_SRC_DIR}/numpy/core/src/common/npy_hashtable.c
  ${NUMPY_SRC_DIR}/numpy/core/src/common/npy_longdouble.c
  ${NUMPY_SRC_DIR}/numpy/core/src/common/ucsnarrow.c
  ${NUMPY_SRC_DIR}/numpy/core/src/common/ufunc_override.c
  ${NUMPY_SRC_DIR}/numpy/core/src/common/numpyos.c
  ${NUMPY_SRC_DIR}/numpy/core/src/common/npy_cpu_features.c
)

numpy_generate_src(_generated_src_multiarray
  ${NUMPY_SRC_DIR}/numpy/core/src/common/npy_sort.h.src
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/arraytypes.h.src
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/arraytypes.c.src
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/einsum.c.src
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/einsum_sumprod.c.src
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/lowlevel_strided_loops.c.src
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/nditer_templ.c.src
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/scalartypes.c.src
  # Multiarray dispatch-able sources
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/argfunc.dispatch.c.src
)
list(APPEND _generated_src_multiarray
  # ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/argfunc.dispatch.h
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/abstractdtypes.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/alloc.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/arrayobject.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/array_coercion.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/array_method.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/array_assign_scalar.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/array_assign_array.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/arrayfunction_override.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/buffer.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/calculation.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/compiled_base.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/common.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/common_dtype.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/convert.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/convert_datatype.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/conversion_utils.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/ctors.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/datetime.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/datetime_strings.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/datetime_busday.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/datetime_busdaycal.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/descriptor.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/dlpack.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/dtypemeta.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/dragon4.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/dtype_transfer.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/dtype_traversal.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/experimental_public_dtype_api.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/flagsobject.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/getset.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/hashdescr.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/item_selection.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/iterators.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/legacy_dtype_implementation.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/mapping.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/methods.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/multiarraymodule.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/nditer_api.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/nditer_constr.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/nditer_pywrap.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/number.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/refcount.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/sequence.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/shape.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/scalarapi.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/strfuncs.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/temp_elide.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/typeinfo.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/usertypes.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/vdot.c
  ${NUMPY_SRC_DIR}/numpy/core/src/npysort/quicksort.cpp
  ${NUMPY_SRC_DIR}/numpy/core/src/npysort/mergesort.cpp
  ${NUMPY_SRC_DIR}/numpy/core/src/npysort/timsort.cpp
  ${NUMPY_SRC_DIR}/numpy/core/src/npysort/heapsort.cpp
  ${NUMPY_SRC_DIR}/numpy/core/src/npysort/radixsort.cpp
  ${NUMPY_SRC_DIR}/numpy/core/src/common/npy_partition.h
  ${NUMPY_SRC_DIR}/numpy/core/src/npysort/selection.cpp
  ${NUMPY_SRC_DIR}/numpy/core/src/common/npy_binsearch.h
  ${NUMPY_SRC_DIR}/numpy/core/src/npysort/binsearch.cpp
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/textreading/conversions.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/textreading/field_types.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/textreading/growth.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/textreading/readtext.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/textreading/rows.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/textreading/stream_pyobject.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/textreading/str_to_int.c
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/textreading/tokenize.cpp
  # Remove this `arm64_exports.c` file once scipy macos arm64 build correctly
  # links to the arm64 npymath library, see gh-22673
  ${NUMPY_SRC_DIR}/numpy/core/src/npymath/arm64_exports.c
)

numpy_generate_src(_generated_src_umath
  ${NUMPY_SRC_DIR}/numpy/core/src/umath/loops.h.src
  ${NUMPY_SRC_DIR}/numpy/core/src/umath/loops_utils.h.src
  ${NUMPY_SRC_DIR}/numpy/core/src/umath/funcs.inc.src
  ${NUMPY_SRC_DIR}/numpy/core/src/umath/loops.c.src
  ${NUMPY_SRC_DIR}/numpy/core/src/umath/matmul.c.src
  ${NUMPY_SRC_DIR}/numpy/core/src/umath/matmul.h.src
  ${NUMPY_SRC_DIR}/numpy/core/src/umath/scalarmath.c.src
  # Umath dispatch-able sources
  ${NUMPY_SRC_DIR}/numpy/core/src/umath/loops_arithm_fp.dispatch.c.src
  ${NUMPY_SRC_DIR}/numpy/core/src/umath/loops_arithmetic.dispatch.c.src
  ${NUMPY_SRC_DIR}/numpy/core/src/umath/loops_comparison.dispatch.c.src
  ${NUMPY_SRC_DIR}/numpy/core/src/umath/loops_exponent_log.dispatch.c.src
  ${NUMPY_SRC_DIR}/numpy/core/src/umath/loops_hyperbolic.dispatch.c.src
  ${NUMPY_SRC_DIR}/numpy/core/src/umath/loops_logical.dispatch.c.src
  ${NUMPY_SRC_DIR}/numpy/core/src/umath/loops_minmax.dispatch.c.src
  ${NUMPY_SRC_DIR}/numpy/core/src/umath/loops_modulo.dispatch.c.src
  ${NUMPY_SRC_DIR}/numpy/core/src/umath/loops_trigonometric.dispatch.c.src
  ${NUMPY_SRC_DIR}/numpy/core/src/umath/loops_umath_fp.dispatch.c.src
  ${NUMPY_SRC_DIR}/numpy/core/src/umath/loops_unary.dispatch.c.src
  ${NUMPY_SRC_DIR}/numpy/core/src/umath/loops_unary_fp.dispatch.c.src
  ${NUMPY_SRC_DIR}/numpy/core/src/umath/loops_unary_fp_le.dispatch.c.src
  ${NUMPY_SRC_DIR}/numpy/core/src/umath/loops_unary_complex.dispatch.c.src
  ${NUMPY_SRC_DIR}/numpy/core/src/umath/loops_autovec.dispatch.c.src
)
list(APPEND _generated_src_umath
  ${NUMPY_SRC_DIR}/numpy/core/src/umath/ufunc_type_resolution.c
  ${NUMPY_SRC_DIR}/numpy/core/src/umath/clip.cpp
  ${NUMPY_SRC_DIR}/numpy/core/src/umath/clip.h
  ${NUMPY_SRC_DIR}/numpy/core/src/umath/dispatching.c
  ${NUMPY_SRC_DIR}/numpy/core/src/umath/extobj.c
  ${NUMPY_SRC_DIR}/numpy/core/src/umath/legacy_array_method.c
  ${NUMPY_SRC_DIR}/numpy/core/src/umath/override.c
  ${NUMPY_SRC_DIR}/numpy/core/src/umath/reduction.c
  ${NUMPY_SRC_DIR}/numpy/core/src/umath/ufunc_object.c
  ${NUMPY_SRC_DIR}/numpy/core/src/umath/umathmodule.c
  ${NUMPY_SRC_DIR}/numpy/core/src/umath/string_ufuncs.cpp
  ${NUMPY_SRC_DIR}/numpy/core/src/umath/wrapping_array_method.c
  # For testing. Eventually, should use public API and be separate:
  ${NUMPY_SRC_DIR}/numpy/core/src/umath/_scaled_float_dtype.c
)

add_python_extension(_multiarray_umath
  REQUIRES NUMPY_SRC_DIR
  SOURCES
    ${_generated_src_umath_doc_h}
    ${_generated_src_multiarray_api}
    ${_generated_src_ufunc_api}
    ${_generated_src_multiarray_umath_common}
    ${_generated_src_multiarray}
    ${_generated_src_umath}
  INCLUDEDIRS
    ${CMAKE_BINARY_DIR}/generated/numpy
    ${NUMPY_SRC_DIR}/numpy/core/include
    ${NUMPY_SRC_DIR}/numpy/core/src/common
    ${NUMPY_SRC_DIR}/numpy/core/src/multiarray
    ${NUMPY_SRC_DIR}/numpy/core/src/npymath
    ${NUMPY_SRC_DIR}/numpy/core/src/umath
  DEFINITIONS
    HAVE_NPY_CONFIG_H
    NPY_INTERNAL_BUILD
    NPY_DISABLE_OPTIMIZATION
  LIBRARIES
    $<TARGET_FILE:npymath>
)

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

# Install numpy core files
set(_numpy_core_python_sources
  ${NUMPY_SRC_DIR}/numpy/core/__init__.py
  ${NUMPY_SRC_DIR}/numpy/core/__init__.pyi
  ${NUMPY_SRC_DIR}/numpy/core/_add_newdocs.py
  ${NUMPY_SRC_DIR}/numpy/core/_add_newdocs_scalars.py
  ${NUMPY_SRC_DIR}/numpy/core/_asarray.py
  ${NUMPY_SRC_DIR}/numpy/core/_asarray.pyi
  ${NUMPY_SRC_DIR}/numpy/core/_dtype.py
  ${NUMPY_SRC_DIR}/numpy/core/_dtype_ctypes.py
  ${NUMPY_SRC_DIR}/numpy/core/_exceptions.py
  ${NUMPY_SRC_DIR}/numpy/core/_internal.py
  ${NUMPY_SRC_DIR}/numpy/core/_internal.pyi
  ${NUMPY_SRC_DIR}/numpy/core/_machar.py
  ${NUMPY_SRC_DIR}/numpy/core/_methods.py
  ${NUMPY_SRC_DIR}/numpy/core/_string_helpers.py
  ${NUMPY_SRC_DIR}/numpy/core/_type_aliases.py
  ${NUMPY_SRC_DIR}/numpy/core/_type_aliases.pyi
  ${NUMPY_SRC_DIR}/numpy/core/_ufunc_config.py
  ${NUMPY_SRC_DIR}/numpy/core/_ufunc_config.pyi
  ${NUMPY_SRC_DIR}/numpy/core/arrayprint.py
  ${NUMPY_SRC_DIR}/numpy/core/arrayprint.pyi
  ${NUMPY_SRC_DIR}/numpy/core/cversions.py
  ${NUMPY_SRC_DIR}/numpy/core/defchararray.py
  ${NUMPY_SRC_DIR}/numpy/core/defchararray.pyi
  ${NUMPY_SRC_DIR}/numpy/core/einsumfunc.py
  ${NUMPY_SRC_DIR}/numpy/core/einsumfunc.pyi
  ${NUMPY_SRC_DIR}/numpy/core/fromnumeric.py
  ${NUMPY_SRC_DIR}/numpy/core/fromnumeric.pyi
  ${NUMPY_SRC_DIR}/numpy/core/function_base.py
  ${NUMPY_SRC_DIR}/numpy/core/function_base.pyi
  ${NUMPY_SRC_DIR}/numpy/core/getlimits.py
  ${NUMPY_SRC_DIR}/numpy/core/getlimits.pyi
  ${NUMPY_SRC_DIR}/numpy/core/memmap.py
  ${NUMPY_SRC_DIR}/numpy/core/memmap.pyi
  ${NUMPY_SRC_DIR}/numpy/core/multiarray.py
  ${NUMPY_SRC_DIR}/numpy/core/multiarray.pyi
  ${NUMPY_SRC_DIR}/numpy/core/numeric.py
  ${NUMPY_SRC_DIR}/numpy/core/numeric.pyi
  ${NUMPY_SRC_DIR}/numpy/core/numerictypes.py
  ${NUMPY_SRC_DIR}/numpy/core/numerictypes.pyi
  ${NUMPY_SRC_DIR}/numpy/core/overrides.py
  ${NUMPY_SRC_DIR}/numpy/core/records.py
  ${NUMPY_SRC_DIR}/numpy/core/records.pyi
  ${NUMPY_SRC_DIR}/numpy/core/shape_base.py
  ${NUMPY_SRC_DIR}/numpy/core/shape_base.pyi
  ${NUMPY_SRC_DIR}/numpy/core/umath.py
  ${NUMPY_SRC_DIR}/numpy/core/umath_tests.py
)

foreach(_numpy_core_python_source ${_numpy_core_python_sources})
  # Copy lib files to build tree
  file(MAKE_DIRECTORY ${PROJECT_BINARY_DIR}/${PYTHONHOME}/numpy/core)
  file(COPY ${_numpy_core_python_source} DESTINATION ${PROJECT_BINARY_DIR}/${PYTHONHOME}/numpy/core)
  # Install
  install(FILES ${_numpy_core_python_source} DESTINATION ${PYTHONHOME}/numpy/core)
endforeach()

# Install numpy core test files
set(_numpy_python_core_source_dirs
  ${NUMPY_SRC_DIR}/numpy/core/tests
)

foreach(_numpy_python_core_source_dir ${_numpy_python_core_source_dirs})
  # Copy lib files to build tree
  file(MAKE_DIRECTORY ${PROJECT_BINARY_DIR}/${PYTHONHOME}/numpy/core)
  file(COPY ${_numpy_python_core_source_dir} DESTINATION ${PROJECT_BINARY_DIR}/${PYTHONHOME}/numpy/core)
  # Install
  install(DIRECTORY ${_numpy_python_core_source_dir} DESTINATION ${PYTHONHOME}/numpy/core)
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