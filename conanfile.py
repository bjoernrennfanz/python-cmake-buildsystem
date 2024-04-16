from conans import ConanFile
from conan.tools.cmake import CMake, CMakeDeps, CMakeToolchain

class CPythonOpenCVConan(ConanFile):
    name = "python-opencv-builtin"
    version = "3.9.17"
    url = "https://github.com/bjoernrennfanz/python-cmake-buildsystem"
    homepage = "https://www.python.org"
    description = "Python with OpenCV as built-in module"
    topics = ("python", "cpython", "language", "script", "opencv")
    generators = "cmake_find_package", "cmake_paths", "cmake"
    license = ("Python-2.0",)
    settings = "os", "arch", "compiler", "build_type"
    options = {
        "shared": [True, False],
        "with_extensions_as_builtin": [True, False],
        "with_documentation": [True, False],
        "with_gdbm": [True, False]
    }
    default_options = {
        "shared": False,
        "with_extensions_as_builtin": True,
        "with_documentation": False,
        "with_gdbm": False
    }

    def generate(self):
        tc = CMakeToolchain(self)
        tc.variables["BUILD_LIBPYTHON_SHARED"] = self.options.shared
        tc.variables["INSTALL_MANUAL"] = self.options.with_documentation
        tc.variables["BUILD_EXTENSIONS_AS_BUILTIN"] = self.options.with_extensions_as_builtin
        tc.variables["BUILD_WININST"] = False

        # Enable extensions
        tc.variables["ENABLE_GDBM"] = self.options.with_gdbm

        tc.generate()

    def requirements(self):
        self.requires("zlib/1.2.13")
        self.requires("openssl/1.1.1t")
        self.requires("expat/2.5.0")
        self.requires("xz_utils/5.4.5")
        self.requires("bzip2/1.0.8")
        self.requires("libffi/3.4.3")
        self.requires("tcl/8.6.10")
        self.requires("tk/8.6.10")
        self.requires("sqlite3/3.36.0")
        if self.options.with_gdbm:
            self.requires("gdbm/1.19")