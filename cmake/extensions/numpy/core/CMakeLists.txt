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
  PUBLIC ${_numpy_c_args_common}
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
    ${_numpy_c_args_common}
  LIBRARIES
    $<TARGET_FILE:npymath>
)

# Build multiarray_tests module
numpy_generate_src(_generated_src_multiarray_tests
  ${NUMPY_SRC_DIR}/numpy/core/src/multiarray/_multiarray_tests.c.src
  ${NUMPY_SRC_DIR}/numpy/core/src/common/templ_common.h.src
)
add_python_extension(_multiarray_tests
  REQUIRES NUMPY_SRC_DIR
  SOURCES
    ${_generated_src_multiarray_tests}
    ${NUMPY_SRC_DIR}/numpy/core/src/common/mem_overlap.c
    ${NUMPY_SRC_DIR}/numpy/core/src/common/npy_argparse.c
    ${NUMPY_SRC_DIR}/numpy/core/src/common/npy_hashtable.c
  INCLUDEDIRS
    ${CMAKE_BINARY_DIR}/generated/numpy
    ${NUMPY_SRC_DIR}/numpy/core/include
    ${NUMPY_SRC_DIR}/numpy/core/src/common
    ${NUMPY_SRC_DIR}/numpy/core/src/multiarray
    ${NUMPY_SRC_DIR}/numpy/core/src/npymath
  DEFINITIONS
    ${_numpy_c_args_common}
  LIBRARIES
    $<TARGET_FILE:npymath>
)

numpy_generate_src(_generated_src_umath_tests
  ${NUMPY_SRC_DIR}/numpy/core/src/umath/_umath_tests.c.src
)
add_python_extension(_umath_tests
  REQUIRES NUMPY_SRC_DIR
  SOURCES
    ${_generated_src_umath_tests}
    ${NUMPY_SRC_DIR}/numpy/core/src/common/npy_cpu_features.c
    ${NUMPY_SRC_DIR}/numpy/core/src/umath/_umath_tests.dispatch.c
  INCLUDEDIRS
    ${CMAKE_BINARY_DIR}/generated/numpy
    ${NUMPY_SRC_DIR}/numpy/core/include
    ${NUMPY_SRC_DIR}/numpy/core/src/common
    ${NUMPY_SRC_DIR}/numpy/core/src/multiarray
    ${NUMPY_SRC_DIR}/numpy/core/src/npymath
  DEFINITIONS
    ${_numpy_c_args_common}
)

add_python_extension(_rational_tests
  REQUIRES NUMPY_SRC_DIR
  SOURCES
    ${NUMPY_SRC_DIR}/numpy/core/src/umath/_rational_tests.c
  INCLUDEDIRS
    ${CMAKE_BINARY_DIR}/generated/numpy
    ${NUMPY_SRC_DIR}/numpy/core/include
    ${NUMPY_SRC_DIR}/numpy/core/src/common
    ${NUMPY_SRC_DIR}/numpy/core/src/multiarray
    ${NUMPY_SRC_DIR}/numpy/core/src/npymath
  DEFINITIONS
    ${_numpy_c_args_common}
)

add_python_extension(_struct_ufunc_tests
  REQUIRES NUMPY_SRC_DIR
  SOURCES
    ${NUMPY_SRC_DIR}/numpy/core/src/umath/_struct_ufunc_tests.c
  INCLUDEDIRS
    ${CMAKE_BINARY_DIR}/generated/numpy
    ${NUMPY_SRC_DIR}/numpy/core/include
    ${NUMPY_SRC_DIR}/numpy/core/src/common
    ${NUMPY_SRC_DIR}/numpy/core/src/multiarray
    ${NUMPY_SRC_DIR}/numpy/core/src/npymath
  DEFINITIONS
    ${_numpy_c_args_common}
)

add_python_extension(_operand_flag_tests
  REQUIRES NUMPY_SRC_DIR
  SOURCES
    ${NUMPY_SRC_DIR}/numpy/core/src/umath/_operand_flag_tests.c
  INCLUDEDIRS
    ${CMAKE_BINARY_DIR}/generated/numpy
    ${NUMPY_SRC_DIR}/numpy/core/include
    ${NUMPY_SRC_DIR}/numpy/core/src/common
    ${NUMPY_SRC_DIR}/numpy/core/src/multiarray
    ${NUMPY_SRC_DIR}/numpy/core/src/npymath
  DEFINITIONS
    ${_numpy_c_args_common}
)

# Build SIMD module
numpy_generate_src(_generated_src_simd
  ${NUMPY_SRC_DIR}/numpy/core/src/_simd/_simd_inc.h.src
  ${NUMPY_SRC_DIR}/numpy/core/src/_simd/_simd_data.inc.src
  ${NUMPY_SRC_DIR}/numpy/core/src/_simd/_simd.dispatch.c.src
)
add_python_extension(_simd
  REQUIRES NUMPY_SRC_DIR
  SOURCES
    ${_generated_src_simd}
    ${NUMPY_SRC_DIR}/numpy/core/src/common/npy_cpu_features.c
    ${NUMPY_SRC_DIR}/numpy/core/src/_simd/_simd.c
  INCLUDEDIRS
    ${CMAKE_BINARY_DIR}/generated/numpy
    ${NUMPY_SRC_DIR}/numpy/core/include
    ${NUMPY_SRC_DIR}/numpy/core/src/common
    ${NUMPY_SRC_DIR}/numpy/core/src/_simd
    ${NUMPY_SRC_DIR}/numpy/core/src/npymath
  DEFINITIONS
    ${_numpy_c_args_common}
)

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
# Add wrapper for static builds
if(NOT BUILD_LIBPYTHON_SHARED)
  list(APPEND _numpy_core_python_sources
    ${CMAKE_CURRENT_SOURCE_DIR}/_multiarray_tests.py
    ${CMAKE_CURRENT_SOURCE_DIR}/_multiarray_umath.py
    ${CMAKE_CURRENT_SOURCE_DIR}/_operand_flag_tests.py
    ${CMAKE_CURRENT_SOURCE_DIR}/_rational_tests.py
    ${CMAKE_CURRENT_SOURCE_DIR}/_simd.py
    ${CMAKE_CURRENT_SOURCE_DIR}/_struct_ufunc_tests.py
    ${CMAKE_CURRENT_SOURCE_DIR}/_umath_tests.py
  )
endif()

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
