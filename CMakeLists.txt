cmake_minimum_required(VERSION 3.10)

file(STRINGS ${CMAKE_CURRENT_SOURCE_DIR}/include/hpdf_version.h HPDF_VERSION_H_CONTENTS REGEX " HPDF_(MAJOR|MINOR|BUGFIX)_VERSION ")
string(REGEX MATCH "MAJOR_VERSION [0-9]+"  HPDF_MAJOR_VERSION  ${HPDF_VERSION_H_CONTENTS})
string(REGEX MATCH "MINOR_VERSION [0-9]+"  HPDF_MINOR_VERSION  ${HPDF_VERSION_H_CONTENTS})
string(REGEX MATCH "BUGFIX_VERSION [0-9]+" HPDF_BUGFIX_VERSION ${HPDF_VERSION_H_CONTENTS})
string(REGEX MATCH "[0-9]+" HPDF_MAJOR_VERSION  ${HPDF_MAJOR_VERSION})
string(REGEX MATCH "[0-9]+" HPDF_MINOR_VERSION  ${HPDF_MINOR_VERSION})
string(REGEX MATCH "[0-9]+" HPDF_BUGFIX_VERSION ${HPDF_BUGFIX_VERSION})

project(libharu
    VERSION ${HPDF_MAJOR_VERSION}.${HPDF_MINOR_VERSION}.${HPDF_BUGFIX_VERSION}
    DESCRIPTION "libHaru is a free, cross platform, open source library for generating PDF files."
    LANGUAGES C)

include(GNUInstallDirs)
include(FetchContent)

# Location where the haru cmake build system first looks for cmake modules
set(CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake/modules)

# =======================================================================
# command line options
# =======================================================================
option(BUILD_SHARED_LIBS "Build shared libraries (.dll/.so) instead of static ones (.lib/.a)" ON)
option(LIBHPDF_EXAMPLES "Build libharu examples" OFF)
option(LIBHPDF_DEBUG "Enable HPDF Debug")
option(LIBHPDF_DEBUG_TRACE "Enable HPDF Debug trace")
option(LIBHPDF_FETCH_DEPENDENCIES "Automatically download and build zlib and libpng if not found" ON)

# Enable exceptions on linux if required
# (eg if you are using libharu in a C++ environment,
# and you want your error-callback to throw an exception,
# you will need to enable this for the exception to be
# able to throw through the libharu callstack).
if (CMAKE_COMPILER_IS_GNUCC OR ("${CMAKE_C_COMPILER_ID}" STREQUAL "Clang"))
   option (LIBHPDF_ENABLE_EXCEPTIONS "Enable exceptions" NO)
   if (LIBHPDF_ENABLE_EXCEPTIONS)
      set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fexceptions")
   endif (LIBHPDF_ENABLE_EXCEPTIONS)
endif ()

include_directories(${PROJECT_SOURCE_DIR}/include)

# =======================================================================
# look for headers and libraries
# =======================================================================
include(summary)

# check zlib availability
find_package(ZLIB)

# If ZLIB not found and LIBHPDF_FETCH_DEPENDENCIES is ON, download it
if(NOT ZLIB_FOUND AND LIBHPDF_FETCH_DEPENDENCIES)
    message(STATUS "ZLIB not found. Downloading and building from source...")
    FetchContent_Declare(
        zlib
        URL https://github.com/madler/zlib/archive/refs/tags/v1.3.1.tar.gz
    )
    set(ZLIB_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
    set(SKIP_INSTALL_ALL ON CACHE BOOL "" FORCE)
    FetchContent_MakeAvailable(zlib)
    set(SKIP_INSTALL_ALL OFF CACHE BOOL "" FORCE)
    
    # Set ZLIB variables for libharu
    set(ZLIB_FOUND TRUE)
    set(ZLIB_INCLUDE_DIRS ${zlib_SOURCE_DIR} ${zlib_BINARY_DIR})
    set(ZLIB_INCLUDE_DIR ${zlib_SOURCE_DIR} CACHE PATH "" FORCE)
    set(ZLIB_LIBRARY $<TARGET_FILE:zlibstatic> CACHE FILEPATH "" FORCE)
    set(ZLIB_LIBRARIES zlibstatic)
    include_directories(${ZLIB_INCLUDE_DIRS})

    # Create ZLIB::ZLIB imported target for libpng
    if(NOT TARGET ZLIB::ZLIB)
        add_library(ZLIB::ZLIB ALIAS zlibstatic)
    endif()
endif()

# check png availability
find_package(PNG)

# If PNG not found and LIBHPDF_FETCH_DEPENDENCIES is ON, download it
if(NOT PNG_FOUND AND LIBHPDF_FETCH_DEPENDENCIES)
    message(STATUS "PNG not found. Downloading and building from source...")
    FetchContent_Declare(
        libpng
        URL https://github.com/glennrp/libpng/archive/refs/tags/v1.6.43.tar.gz
    )
    set(PNG_SHARED OFF CACHE BOOL "" FORCE)
    set(PNG_STATIC ON CACHE BOOL "" FORCE)
    set(PNG_TESTS OFF CACHE BOOL "" FORCE)
    set(PNG_BUILD_ZLIB OFF CACHE BOOL "" FORCE)
    set(SKIP_INSTALL_ALL ON CACHE BOOL "" FORCE)
    FetchContent_MakeAvailable(libpng)
    
    # Set PNG variables for libharu
    set(PNG_FOUND TRUE)
    set(PNG_INCLUDE_DIRS ${libpng_SOURCE_DIR} ${libpng_BINARY_DIR})
    set(PNG_LIBRARIES png_static)
    include_directories(${PNG_INCLUDE_DIRS})
endif()

# Find math library, sometimes needs to be explicitly linked against
find_library(M_LIB m)

# =======================================================================
# configure header files, add compiler flags
# =======================================================================
# add definitions and directories to include
#if(CMAKE_COMPILER_IS_GNUCC)
#  add_definitions("-Wall")
#endif(CMAKE_COMPILER_IS_GNUCC)
if(MSVC_VERSION GREATER 1399)
  add_definitions(-D_CRT_SECURE_NO_WARNINGS -D_CRT_SECURE_NO_DEPRECATE)
endif(MSVC_VERSION GREATER 1399)

# Will export symbols to a .lib file on Windows
set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS 1)

# support all of the different variations of LIBPNG defines in HARU
set (LIBHPDF_HAVE_LIBPNG ${PNG_FOUND})

# support different zlib defines
set (LIBHPDF_HAVE_ZLIB ${ZLIB_FOUND})

# create hpdf_config.h
configure_file(
  ${PROJECT_SOURCE_DIR}/include/hpdf_config.h.cmake
  ${PROJECT_BINARY_DIR}/include/hpdf_config.h
)
include_directories(${PROJECT_BINARY_DIR}/include)

# =======================================================================
# create library and demos
# =======================================================================
add_subdirectory(src)
if(LIBHPDF_EXAMPLES)
    add_subdirectory(demo)
endif(LIBHPDF_EXAMPLES)

# =======================================================================
# installation configuration
# =======================================================================
set(
  haru_HDRS
    include/hpdf.h
    include/hpdf_types.h
    include/hpdf_consts.h
    include/hpdf_annotation.h
    include/hpdf_catalog.h
    include/hpdf_conf.h
    include/hpdf_destination.h
    include/hpdf_doc.h
    include/hpdf_encoder.h
    include/hpdf_encrypt.h
    include/hpdf_encryptdict.h
    include/hpdf_error.h
    include/hpdf_ext_gstate.h
    include/hpdf_font.h
    include/hpdf_fontdef.h
    include/hpdf_gstate.h
    include/hpdf_image.h
    include/hpdf_info.h
    include/hpdf_list.h
    include/hpdf_mmgr.h
    include/hpdf_namedict.h
    include/hpdf_objects.h
    include/hpdf_outline.h
    include/hpdf_pages.h
    include/hpdf_page_label.h
    include/hpdf_streams.h
    include/hpdf_u3d.h
    include/hpdf_utils.h
    include/hpdf_pdfa.h
    include/hpdf_3dmeasure.h
    include/hpdf_exdata.h
    include/hpdf_version.h
    ${PROJECT_BINARY_DIR}/include/hpdf_config.h
)

# install header files
install(FILES ${haru_HDRS} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

# install various files
install(FILES README.md CHANGES INSTALL DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/libharu)
install(DIRECTORY bindings DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/libharu)

# =======================================================================
# print out some information
# =======================================================================
summary()