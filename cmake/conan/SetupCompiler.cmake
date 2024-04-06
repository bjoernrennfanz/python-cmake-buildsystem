# Detect cross compiler
if(DEFINED ENV{CROSS_TRIPLE} AND UNIX AND NOT APPLE AND NOT PYTHON_CMAKE_CROSS_COMPILER_DEFINED)

  # Check if cross compiler is already setup
  set(PYTHON_CMAKE_CROSS_COMPILER_DEFINED TRUE)

  set(CMAKE_SYSTEM_NAME Linux)

  # Extract arch from triple
  string(REPLACE "-" ";" CROSS_TRIPLE_LIST $ENV{CROSS_TRIPLE})
  list(GET CROSS_TRIPLE_LIST 0 CROSS_TRIPLE_ARCH)
  set(CMAKE_SYSTEM_PROCESSOR ${CROSS_TRIPLE_ARCH})

  # Setup sysroot
  set(CMAKE_SYSROOT $ENV{CROSS_SYSROOT})
  set(CMAKE_STAGING_PREFIX $ENV{CROSS_SYSROOT})

  # Setup compiler
  set(CMAKE_C_COMPILER $ENV{CROSS_TRIPLE}-gcc)
  set(CMAKE_CXX_COMPILER $ENV{CROSS_TRIPLE}-g++)
endif()

# Detect system processor
if(UNIX AND NOT APPLE AND NOT PYTHON_CMAKE_CONAN_ARCH_DEFINED)

  # Check if workbench arch is already setup
  set(PYTHON_CMAKE_CONAN_ARCH_DEFINED TRUE)

  # Linux
  if(NOT CMAKE_SYSTEM_PROCESSOR)
    # Determine CMake system processor manually
    execute_process(COMMAND "uname" "-p"
                    OUTPUT_VARIABLE CMAKE_SYSTEM_PROCESSOR
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
  endif()

  if(CMAKE_SYSTEM_PROCESSOR MATCHES "amd64.*|x86_64.*|AMD64.*")
    set(PYTHON_CMAKE_CONAN_ARCH x86_64)
  elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "i686.*|i386.*|x86.*")
    set(PYTHON_CMAKE_CONAN_ARCH x86)
  elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64.*|AARCH64.*|arm64.*|ARM64.*)")
    set(PYTHON_CMAKE_CONAN_ARCH armv8)
  elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(arm.*|ARM.*)")
    set(PYTHON_CMAKE_CONAN_ARCH armv7hf)
  else()
    message( FATAL_ERROR "Unsupported cpu type!, CMake will exit." )
  endif()
elseif (APPLE)
  if(DEFINED CMAKE_OSX_ARCHITECTURES)
    list(LENGTH CMAKE_OSX_ARCHITECTURES _NUM_CMAKE_OSX_ARCHITECTURES)
    if (_NUM_CMAKE_OSX_ARCHITECTURES GREATER "2")
      message(FATAL_ERROR "Only one cpu type is supported!, CMake will exit.")
    endif()
    set(CMAKE_SYSTEM_PROCESSOR "${CMAKE_OSX_ARCHITECTURES}")
  endif()
  if(NOT CMAKE_SYSTEM_PROCESSOR)
    # Determine CMake system processor manually
    execute_process(COMMAND "uname" "-m"
                    OUTPUT_VARIABLE CMAKE_SYSTEM_PROCESSOR
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
  endif()
  if(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64")
    # macOS (x86_64)
    set(PYTHON_CMAKE_CONAN_ARCH x86_64)
  elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64.*|AARCH64.*|arm64.*|ARM64.*)")
    # macOS (arm64)
    set(PYTHON_CMAKE_CONAN_ARCH armv8)
  else()
    message( FATAL_ERROR "Unsupported cpu type!, CMake will exit." )
  endif()
  # Set CMAKE_OSX_ARCHITECTURES when not defined
  if (DEFINED CMAKE_OSX_ARCHITECTURES AND CMAKE_OSX_ARCHITECTURES STREQUAL "")
    set(CMAKE_OSX_ARCHITECTURES "${CMAKE_SYSTEM_PROCESSOR}")
  endif()
elseif (WIN32)
  # Windows
  if($ENV{VSCMD_ARG_TGT_ARCH} MATCHES "x64")
    # Windows 64 bits
    set(PYTHON_CMAKE_CONAN_ARCH x86_64)
  elseif($ENV{VSCMD_ARG_TGT_ARCH} MATCHES "x86")
    # Windows 32 bits
    set(PYTHON_CMAKE_CONAN_ARCH x86)
  elseif($ENV{VSCMD_ARG_TGT_ARCH} MATCHES "arm64")
    # Windows arm64
    set(PYTHON_CMAKE_CONAN_ARCH armv8)
  else()
    message( FATAL_ERROR "Unsupported cpu type!, CMake will exit." )
  endif()
else()
  message( FATAL_ERROR "Unsupported platform!, CMake will exit." )
endif()
