# Find binary build package
find_package(OpenCV ${OPENCV_VERSION} REQUIRED)

# Look for enable opencv modules in header
file(STRINGS "${opencv_INCLUDE_DIRS}/opencv2/opencv_modules.hpp" _opencv_module_define_statements
  REGEX "#define HAVE_OPENCV_.*$"
)
foreach(statement ${_opencv_module_define_statements})
  string(REGEX REPLACE "#define HAVE_OPENCV_([A-Z0-9_]+).*" "\\1" module_name "${statement}")
  message(STATUS "${module_name}")
endforeach()


add_python_extension(cv2
  REQUIRES 
    OPENCV_SRC_DIR
    NUMPY_SRC_DIR
  SOURCES
    ${OPENCV_SRC_DIR}/modules/python/src2/cv2.cpp
    ${OPENCV_SRC_DIR}/modules/python/src2/cv2_util.cpp
    ${OPENCV_SRC_DIR}/modules/python/src2/cv2_numpy.cpp
    ${OPENCV_SRC_DIR}/modules/python/src2/cv2_convert.cpp
    ${OPENCV_SRC_DIR}/modules/python/src2/cv2_highgui.cpp
  INCLUDEDIRS
    # ${CMAKE_BINARY_DIR}/generated/numpy
    ${NUMPY_SRC_DIR}/numpy/core/include
    ${opencv_INCLUDE_DIRS}
    ${OPENCV_SRC_DIR}/modules/core/include
  DEFINITIONS
    ${_numpy_c_args_common}
)
