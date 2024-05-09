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

    def configure(self):
        self.options["opencv"].shared = False
        self.options["opencv"].parallel = False
        self.options["opencv"].freetype = False
        self.options["opencv"].sfm = False
        self.options["opencv"].with_ipp = False
        self.options["opencv"].gapi = True
        self.options["opencv"].with_jpeg = "libjpeg"
        self.options["opencv"].with_png = True
        self.options["opencv"].with_tiff = True
        self.options["opencv"].with_jpeg2000 = "jasper"
        self.options["opencv"].with_openexr = True
        self.options["opencv"].with_eigen = True
        self.options["opencv"].with_webp = True
        self.options["opencv"].with_quirc = True
        self.options["opencv"].with_cuda = False
        self.options["opencv"].with_cublas = False
        self.options["opencv"].with_cufft = False
        self.options["opencv"].with_cudnn = False
        self.options["opencv"].with_ffmpeg = False
        self.options["opencv"].with_imgcodec_hdr = False
        self.options["opencv"].with_imgcodec_pfm = False
        self.options["opencv"].with_imgcodec_pxm = False
        self.options["opencv"].with_imgcodec_sunraster = False
        self.options["opencv"].dnn = True
        self.options["opencv"].dnn_cuda = False
        self.options["opencv"].cuda_arch_bin = None
        self.options["opencv"].cpu_baseline = None
        self.options["opencv"].cpu_dispatch = None
        self.options["opencv"].nonfree = False
        self.options["opencv"].with_tesseract = False
        if self.settings.os == "Macos":
            self.options["opencv"].fPIC = True
        elif self.settings.os == "Linux":
            self.options["opencv"].fPIC = True
            self.options["opencv"].with_gtk = False
            self.options["opencv"].with_v4l = False
            
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
        # Requirements overrides for compatibility
        self.requires("zlib/1.2.13", override=True)
        self.requires("libpng/1.6.39", override=True)

        # Linux specific overrides for compatibility
        if self.settings.os == "Linux":
            self.requires("xkbcommon/1.5.0", override=True)
            self.requires("wayland/1.21.0", override=True)

        # Python requirements
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

        # Python OpenCV requirements
        self.requires("opencv/4.8.1")