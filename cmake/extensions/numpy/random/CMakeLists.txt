# Build npyrandom static library

numpy_generate_tempita(numpy_bounded_integers_pyd
  ${NUMPY_SRC_DIR}/numpy/random/_bounded_integers.pxd.in
)

numpy_generate_tempita(numpy_bounded_integers_pyx
  ${NUMPY_SRC_DIR}/numpy/random/_bounded_integers.pyx.in
)

#numpy_generate_cython(_generated_numpy_bounded_integers
#  PYX_FILE ${numpy_bounded_integers_pyx}
#  MODULE_NAME _bounded_integers
#  PY3 C
#)
