# SPDX-FileCopyrightText: 2020 AlgorIT Software Consultancy <https://github.com/algoritnl>
# SPDX-License-Identifier: CC0-1.0

cmake_minimum_required(VERSION 3.16...4.4)

file(
    STRINGS "${CMAKE_CURRENT_SOURCE_DIR}/source/sqlite3.h"
    _ver_line
    REGEX "^#define SQLITE_VERSION +\"([0-9]+\\.[0-9]+\\.[0-9]+)\""
    LIMIT_COUNT 1
)
string(REGEX MATCH "[0-9]+\\.[0-9]+\\.[0-9]+" SQLITE_VERSION ${_ver_line})
message(STATUS "SQLite library version: ${SQLITE_VERSION}")
unset(_ver_line)

project(
    sqlite
    VERSION ${SQLITE_VERSION}
    DESCRIPTION "SQLite: an embedded SQL database engine"
    HOMEPAGE_URL https://github.com/algoritnl/sqlite-cmake
    LANGUAGES C
)

if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    set(sqlite_IS_TOP_LEVEL TRUE)
else()
    set(sqlite_IS_TOP_LEVEL FALSE)
endif()

# -- Configuration Options -----------------------------------------------------

include("${CMAKE_CURRENT_LIST_DIR}/cmake/multiple-choice.cmake")

# gersemi: off
option(BUILD_TESTING "Build the testing tree." ${sqlite_IS_TOP_LEVEL})

option(SQLITE_BUILD_SHELL "Build the SQLite3 interactive shell." ${sqlite_IS_TOP_LEVEL})
option(SQLITE_BUILD_TESTING "Enable the interactive shell test." ${sqlite_IS_TOP_LEVEL})
option(SQLITE_ENABLE_API_ARMOR "This option activates extra code that attempts to detect misuse of the SQLite API." OFF)
option(SQLITE_ENABLE_COLUMN_METADATA "Enable some extra APIs that are required by some common systems, including Ruby-on-Rails." OFF)
option(SQLITE_ENABLE_DBSTAT_VTAB "This option enables the dbstat virtual table." OFF)
option(SQLITE_ENABLE_EXPLAIN_COMMENTS "This option adds extra logic to SQLite that inserts comment text into the output of EXPLAIN." OFF)
option(SQLITE_ENABLE_FTS3 "Enable version 3 of the full-text search engine." OFF)
option(SQLITE_ENABLE_FTS3_PARENTHESIS "Enable operators AND and NOT and allow nested parentheses." OFF)
option(SQLITE_ENABLE_FTS4 "Enable versions 3 and 4 of the full-text search engine." OFF)
option(SQLITE_ENABLE_FTS5 "Enable version 5 of the full-text search engine." OFF)
option(SQLITE_ENABLE_GEOPOLY "Enable the Geopoly extension." OFF)
option(SQLITE_ENABLE_ICU "Enable the ICU (International Components for Unicode) extension." OFF)
option(SQLITE_ENABLE_MATH_FUNCTIONS "Enable the built-in SQL math functions." OFF)
option(SQLITE_ENABLE_MEMSYS5 "This option includes code in SQLite that implements an alternative memory allocator" OFF)
option(SQLITE_ENABLE_NORMALIZE "Enable the sqlite3_normalized_sql() API." OFF)
option(SQLITE_ENABLE_PREUPDATE_HOOK "Enable the pre-update hook feature." OFF)
option(SQLITE_ENABLE_RBU "Enable the code that implements the RBU extension." OFF)
option(SQLITE_ENABLE_RTREE "This option causes SQLite to include support for the R*Tree index extension." OFF)
option(SQLITE_ENABLE_SESSION "Enable the session extension." OFF)
option(SQLITE_ENABLE_STMTVTAB "Enable the SQLITE_STMT virtual table logic." OFF)
option(SQLITE_LIKE_DOESNT_MATCH_BLOBS "Operators LIKE and GLOB always return FALSE if either operand is a BLOB." OFF)
option(SQLITE_OMIT_AUTOINIT "Omit calling sqlite3_initialize() automatically. The application is required to invoke it directly." OFF)
option(SQLITE_OMIT_COMPILEOPTION_DIAGS "Omit compile option interfaces." OFF)
option(SQLITE_OMIT_DECLTYPE "Omit the ability to return the declared type of columns from queries." OFF)
option(SQLITE_OMIT_DEPRECATED "Omit deprecated interfaces and features." OFF)
option(SQLITE_OMIT_DESERIALIZE "Omit sqlite3_serialize() and sqlite3_deserialize() interfaces." OFF)
option(SQLITE_OMIT_JSON "Omit the JSON SQL functions." OFF)
option(SQLITE_OMIT_LOAD_EXTENSION "Omit the extension loading mechanism." OFF)
option(SQLITE_OMIT_PROGRESS_CALLBACK "Omit the capability to issue progress callbacks." OFF)
option(SQLITE_OMIT_SHARED_CACHE "Omit support for shared-cache mode." OFF)
option(SQLITE_STRICT_SUBTYPE "This option helps to identify problems with application-defined SQL functions." ON)
option(SQLITE_USE_ALLOCA "Use alloca for memory allocations if possible." OFF)

multiple_choice(SQLITE_DEFAULT_MEMSTATUS HELP "Enable the SQLITE_CONFIG_MEMSTATUS features by default." VALID_VALUES 0 1 DEFAULT 1 DEFAULT_ON_ERROR)
multiple_choice(SQLITE_DEFAULT_SYNCHRONOUS HELP "Determine the default value of PRAGMA synchronous." VALID_VALUES 0 1 2 3 DEFAULT 2 DEFAULT_ON_ERROR)
multiple_choice(SQLITE_DEFAULT_WAL_SYNCHRONOUS HELP "Determine the default value of PRAGMA synchronous in WAL mode." VALID_VALUES 0 1 2 3 DEFAULT ${SQLITE_DEFAULT_SYNCHRONOUS} DEFAULT_ON_ERROR)
multiple_choice(SQLITE_DQS HELP "Enable DQS: 0 = None (recommended); 1 = DML; 2 = DDL; 3 = Both (default)." VALID_VALUES 0 1 2 3 DEFAULT 3 DEFAULT_ON_ERROR)
multiple_choice(SQLITE_THREADSAFE HELP "Select the thread model: 0 = single-threaded; 1 = serialized (default); 2 = multi-threaded." VALID_VALUES 0 1 2 DEFAULT 1 FATAL_ERROR)

set(SQLITE_MAX_ALLOCATION_SIZE -1 CACHE STRING "Set an upper bound on the size of memory allocations.")
set(SQLITE_MAX_EXPR_DEPTH -1 CACHE STRING "Set the maximum expression tree depth.")

if(NOT SQLITE_MAX_ALLOCATION_SIZE GREATER_EQUAL -1)
    message(SEND_ERROR "Configuration SQLITE_MAX_ALLOCATION_SIZE=${SQLITE_MAX_ALLOCATION_SIZE} is not valid.")
endif()
if(NOT SQLITE_MAX_EXPR_DEPTH GREATER_EQUAL -1)
    message(SEND_ERROR "Configuration SQLITE_MAX_EXPR_DEPTH=${SQLITE_MAX_EXPR_DEPTH} is not valid.")
endif()
if(SQLITE_ENABLE_COLUMN_METADATA AND SQLITE_OMIT_DECLTYPE)
    message(SEND_ERROR "Options SQLITE_ENABLE_COLUMN_META and SQLITE_OMIT_DECLTYPE are mutually exclusive.")
endif()
if(SQLITE_ENABLE_SESSION AND NOT SQLITE_ENABLE_PREUPDATE_HOOK)
    message(SEND_ERROR "Option SQLITE_ENABLE_SESSION requires option SQLITE_ENABLE_PREUPDATE_HOOK.")
endif()
# gersemi: on

# -- External Dependencies -----------------------------------------------------

if(NOT SQLITE_THREADSAFE STREQUAL 0)
    set(THREADS_PREFER_PTHREAD_FLAG TRUE)
    find_package(Threads QUIET REQUIRED)
endif()

if(SQLITE_ENABLE_ICU)
    find_package(ICU QUIET REQUIRED COMPONENTS uc i18n)
endif()

# -- Platform Capabilities -----------------------------------------------------

include(CheckIncludeFile)
include(CheckSymbolExists)
include(CheckTypeSize)
include(CMakePushCheckState)

cmake_push_check_state(RESET)

set(CMAKE_REQUIRED_QUIET ON)

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    list(APPEND CMAKE_REQUIRED_DEFINITIONS "-D_GNU_SOURCE")
    find_library(MATH_LIBRARY m)
    if(MATH_LIBRARY)
        list(APPEND CMAKE_REQUIRED_LIBRARIES ${MATH_LIBRARY})
    endif()
elseif(NOT DEFINED MATH_LIBRARY)
    set(MATH_LIBRARY "MATH_LIBRARY-NOTFOUND")
endif()

if(NOT SQLITE_OMIT_LOAD_EXTENSION)
    list(APPEND CMAKE_REQUIRED_LIBRARIES ${CMAKE_DL_LIBS})
endif()

check_include_file(inttypes.h HAVE_INTTYPES_H)
check_include_file(stdint.h HAVE_STDINT_H)
check_type_size(int8_t INT8_T)
check_type_size(int16_t INT16_T)
check_type_size(uint8_t UINT8_T)
check_type_size(uint16_t UINT16_T)
check_type_size(uint32_t UINT32_T)

check_include_file(malloc.h HAVE_MALLOC_H)
check_symbol_exists(malloc_usable_size malloc.h HAVE_MALLOC_USABLE_SIZE)

check_symbol_exists(fdatasync unistd.h HAVE_FDATASYNC)
check_symbol_exists(gethostuuid unistd.h HAVE_GETHOSTUUID)
check_symbol_exists(gmtime_r time.h HAVE_GMTIME_R)
check_symbol_exists(isnan math.h HAVE_ISNAN)
check_symbol_exists(localtime_r time.h HAVE_LOCALTIME_R)
check_symbol_exists(localtime_s time.h HAVE_LOCALTIME_S)
check_symbol_exists(log2 math.h HAVE_LOG2)
check_symbol_exists(log10 math.h HAVE_LOG10)
check_symbol_exists(lstat "fcntl.h;sys/stat.h" HAVE_LSTAT)
check_symbol_exists(nanosleep time.h HAVE_NANOSLEEP)
check_symbol_exists(posix_fallocate fcntl.h HAVE_POSIX_FALLOCATE)
check_symbol_exists(pread unistd.h HAVE_PREAD)
check_symbol_exists(pread64 unistd.h HAVE_PREAD64)
check_symbol_exists(pwrite unistd.h HAVE_PWRITE)
check_symbol_exists(pwrite64 unistd.h HAVE_PWRITE64)
check_symbol_exists(readlink unistd.h HAVE_READLINK)
check_symbol_exists(strchrnul string.h HAVE_STRCHRNUL)
check_symbol_exists(strerror_r string.h HAVE_STRERROR_R)
check_symbol_exists(usleep unistd.h HAVE_USLEEP)
check_symbol_exists(utime utime.h HAVE_UTIME)

cmake_pop_check_state()

# -- SQLite Library ------------------------------------------------------------

add_library(sqlite.library)
add_library(sqlite::sqlite ALIAS sqlite.library)

target_compile_features(sqlite.library PUBLIC c_std_99)

set_target_properties(
    sqlite.library
    PROPERTIES
        OUTPUT_NAME sqlite3
        EXPORT_NAME sqlite
        VERSION ${sqlite_VERSION}
        SOVERSION ${sqlite_VERSION_MAJOR}
        C_VISIBILITY_PRESET hidden
        DEFINE_SYMBOL ""
)

configure_file(
    "${CMAKE_CURRENT_LIST_DIR}/cmake/sqlite3cfg.h.in"
    "${CMAKE_CURRENT_BINARY_DIR}/sqlite3cfg.h"
    @ONLY
)

target_sources(
    sqlite.library
    PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/source/sqlite3.c"
)

target_include_directories(
    sqlite.library
    INTERFACE
        "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/source>"
        "$<INSTALL_INTERFACE:include>"
)

if(BUILD_SHARED_LIBS)
    target_compile_definitions(
        sqlite.library
        INTERFACE "$<$<PLATFORM_ID:Windows>:SQLITE_API=__declspec(dllimport)>"
        PRIVATE "$<$<PLATFORM_ID:Windows>:SQLITE_API=__declspec(dllexport)>"
        PUBLIC
            "$<$<NOT:$<PLATFORM_ID:Windows>>:SQLITE_API=__attribute__((visibility(\"default\")))>"
    )
endif()

target_compile_definitions(
    sqlite.library
    PRIVATE
        "$<$<PLATFORM_ID:Linux>:_GNU_SOURCE>"
        "$<$<PLATFORM_ID:Windows>:SQLITE_USE_SEH>"
)

target_compile_definitions(
    sqlite.library
    PRIVATE
        "SQLITE_DEFAULT_MEMSTATUS=${SQLITE_DEFAULT_MEMSTATUS}"
        "SQLITE_DEFAULT_SYNCHRONOUS=${SQLITE_DEFAULT_SYNCHRONOUS}"
        "SQLITE_DEFAULT_WAL_SYNCHRONOUS=${SQLITE_DEFAULT_WAL_SYNCHRONOUS}"
        "SQLITE_DQS=${SQLITE_DQS}"
        "SQLITE_THREADSAFE=${SQLITE_THREADSAFE}"
        "$<$<NOT:$<STREQUAL:${SQLITE_MAX_ALLOCATION_SIZE},-1>>:SQLITE_MAX_ALLOCATION_SIZE=${SQLITE_MAX_ALLOCATION_SIZE}>"
        "$<$<NOT:$<STREQUAL:${SQLITE_MAX_EXPR_DEPTH},-1>>:SQLITE_MAX_EXPR_DEPTH=${SQLITE_MAX_EXPR_DEPTH}>"
        "$<$<BOOL:${SQLITE_ENABLE_API_ARMOR}>:SQLITE_ENABLE_API_ARMOR>"
        "$<$<BOOL:${SQLITE_ENABLE_COLUMN_METADATA}>:SQLITE_ENABLE_COLUMN_METADATA>"
        "$<$<BOOL:${SQLITE_ENABLE_DBSTAT_VTAB}>:SQLITE_ENABLE_DBSTAT_VTAB>"
        "$<$<BOOL:${SQLITE_ENABLE_EXPLAIN_COMMENTS}>:SQLITE_ENABLE_EXPLAIN_COMMENTS>"
        "$<$<BOOL:${SQLITE_ENABLE_FTS3}>:SQLITE_ENABLE_FTS3>"
        "$<$<BOOL:${SQLITE_ENABLE_FTS3_PARENTHESIS}>:SQLITE_ENABLE_FTS3_PARENTHESIS>"
        "$<$<BOOL:${SQLITE_ENABLE_FTS4}>:SQLITE_ENABLE_FTS4>"
        "$<$<BOOL:${SQLITE_ENABLE_FTS5}>:SQLITE_ENABLE_FTS5>"
        "$<$<BOOL:${SQLITE_ENABLE_GEOPOLY}>:SQLITE_ENABLE_GEOPOLY>"
        "$<$<BOOL:${SQLITE_ENABLE_ICU}>:SQLITE_ENABLE_ICU>"
        "$<$<BOOL:${SQLITE_ENABLE_MATH_FUNCTIONS}>:SQLITE_ENABLE_MATH_FUNCTIONS>"
        "$<$<BOOL:${SQLITE_ENABLE_MEMSYS5}>:SQLITE_ENABLE_MEMSYS5>"
        "$<$<BOOL:${SQLITE_ENABLE_NORMALIZE}>:SQLITE_ENABLE_NORMALIZE>"
        "$<$<BOOL:${SQLITE_ENABLE_PREUPDATE_HOOK}>:SQLITE_ENABLE_PREUPDATE_HOOK>"
        "$<$<BOOL:${SQLITE_ENABLE_RBU}>:SQLITE_ENABLE_RBU>"
        "$<$<BOOL:${SQLITE_ENABLE_RTREE}>:SQLITE_ENABLE_RTREE>"
        "$<$<BOOL:${SQLITE_ENABLE_SESSION}>:SQLITE_ENABLE_SESSION>"
        "$<$<BOOL:${SQLITE_ENABLE_STMTVTAB}>:SQLITE_ENABLE_STMTVTAB>"
        "$<$<BOOL:${SQLITE_LIKE_DOESNT_MATCH_BLOBS}>:SQLITE_LIKE_DOESNT_MATCH_BLOBS>"
        "$<$<BOOL:${SQLITE_OMIT_AUTOINIT}>:SQLITE_OMIT_AUTOINIT>"
        "$<$<BOOL:${SQLITE_OMIT_COMPILEOPTION_DIAGS}>:SQLITE_OMIT_COMPILEOPTION_DIAGS>"
        "$<$<BOOL:${SQLITE_OMIT_DECLTYPE}>:SQLITE_OMIT_DECLTYPE>"
        "$<$<BOOL:${SQLITE_OMIT_DEPRECATED}>:SQLITE_OMIT_DEPRECATED>"
        "$<$<BOOL:${SQLITE_OMIT_DESERIALIZE}>:SQLITE_OMIT_DESERIALIZE>"
        "$<$<BOOL:${SQLITE_OMIT_JSON}>:SQLITE_OMIT_JSON>"
        "$<$<BOOL:${SQLITE_OMIT_LOAD_EXTENSION}>:SQLITE_OMIT_LOAD_EXTENSION>"
        "$<$<BOOL:${SQLITE_OMIT_PROGRESS_CALLBACK}>:SQLITE_OMIT_PROGRESS_CALLBACK>"
        "$<$<BOOL:${SQLITE_OMIT_SHARED_CACHE}>:SQLITE_OMIT_SHARED_CACHE>"
        "$<$<BOOL:${SQLITE_STRICT_SUBTYPE}>:SQLITE_STRICT_SUBTYPE=1>"
        "$<$<BOOL:${SQLITE_USE_ALLOCA}>:SQLITE_USE_ALLOCA>"
        "$<$<BOOL:${HAVE_INTTYPES_H}>:HAVE_INTTYPES_H>"
        "$<$<BOOL:${HAVE_STDINT_H}>:HAVE_STDINT_H>"
        "$<$<BOOL:${HAVE_INT8_T}>:HAVE_INT8_T>"
        "$<$<BOOL:${HAVE_INT16_T}>:HAVE_INT16_T>"
        "$<$<BOOL:${HAVE_UINT8_T}>:HAVE_UINT8_T>"
        "$<$<BOOL:${HAVE_UINT16_T}>:HAVE_UINT16_T>"
        "$<$<BOOL:${HAVE_UINT32_T}>:HAVE_UINT32_T>"
        "$<$<BOOL:${HAVE_MALLOC_H}>:HAVE_MALLOC_H>"
        "$<$<BOOL:${HAVE_MALLOC_USABLE_SIZE}>:HAVE_MALLOC_USABLE_SIZE>"
        "$<$<BOOL:${HAVE_FDATASYNC}>:HAVE_FDATASYNC>"
        "$<$<BOOL:${HAVE_GETHOSTUUID}>:HAVE_GETHOSTUUID>"
        "$<$<BOOL:${HAVE_GMTIME_R}>:HAVE_GMTIME_R>"
        "$<$<BOOL:${HAVE_ISNAN}>:HAVE_ISNAN>"
        "$<$<BOOL:${HAVE_LOCALTIME_R}>:HAVE_LOCALTIME_R>"
        "$<$<BOOL:${HAVE_LOCALTIME_S}>:HAVE_LOCALTIME_S>"
        "HAVE_LOG2=$<BOOL:${HAVE_LOG2}>"
        "HAVE_LOG10=$<BOOL:${HAVE_LOG10}>"
        "$<$<BOOL:${HAVE_LSTAT}>:HAVE_LSTAT>"
        "HAVE_NANOSLEEP=$<BOOL:${HAVE_NANOSLEEP}>"
        "$<$<BOOL:${HAVE_POSIX_FALLOCATE}>:HAVE_POSIX_FALLOCATE>"
        "$<$<BOOL:${HAVE_PREAD}>:HAVE_PREAD>"
        "$<$<BOOL:${HAVE_PREAD64}>:HAVE_PREAD64>"
        "$<$<BOOL:${HAVE_PWRITE}>:HAVE_PWRITE>"
        "$<$<BOOL:${HAVE_PWRITE64}>:HAVE_PWRITE64>"
        "$<$<BOOL:${HAVE_READLINK}>:HAVE_READLINK>"
        "$<$<BOOL:${HAVE_STRCHRNUL}>:HAVE_STRCHRNUL>"
        "$<$<BOOL:${HAVE_STRERROR_R}>:HAVE_STRERROR_R>"
        "$<$<BOOL:${HAVE_USLEEP}>:HAVE_USLEEP>"
        "$<$<BOOL:${HAVE_UTIME}>:HAVE_UTIME>"
)

target_link_libraries(
    sqlite.library
    PUBLIC
        "$<$<BOOL:${MATH_LIBRARY}>:m>"
        "$<$<NOT:$<STREQUAL:${SQLITE_THREADSAFE},0>>:Threads::Threads>"
        "$<$<NOT:$<BOOL:${SQLITE_OMIT_LOAD_EXTENSION}>>:${CMAKE_DL_LIBS}>"
        "$<$<BOOL:${SQLITE_ENABLE_ICU}>:ICU::uc;ICU::i18n>"
)

# -- Interactive Shell ---------------------------------------------------------

if(SQLITE_BUILD_SHELL OR (BUILD_TESTING AND SQLITE_BUILD_TESTING))
    add_executable(sqlite.shell)
    add_executable(sqlite::shell ALIAS sqlite.shell)

    set(_base "$<IF:$<PLATFORM_ID:Darwin>,@loader_path,$ORIGIN>")
    set_target_properties(
        sqlite.shell
        PROPERTIES
            OUTPUT_NAME sqlite3
            EXPORT_NAME Shell
            INSTALL_RPATH "${_base};${_base}/../lib"
    )
    unset(_base)

    target_sources(
        sqlite.shell
        PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/source/shell.c"
    )

    target_compile_definitions(
        sqlite.shell
        PRIVATE
            "$<$<BOOL:${SQLITE_ENABLE_NORMALIZE}>:SQLITE_ENABLE_NORMALIZE>"
            "$<$<BOOL:${SQLITE_ENABLE_SESSION}>:SQLITE_ENABLE_SESSION>"
            "$<$<BOOL:${SQLITE_OMIT_DESERIALIZE}>:SQLITE_OMIT_DESERIALIZE>"
            "$<$<BOOL:${SQLITE_OMIT_LOAD_EXTENSION}>:SQLITE_OMIT_LOAD_EXTENSION>"
    )

    target_link_libraries(sqlite.shell PRIVATE sqlite::sqlite)

    find_package(PkgConfig QUIET)
    if(PKG_CONFIG_FOUND)
        pkg_search_module(Readline QUIET IMPORTED_TARGET readline)
    endif()
    if(TARGET PkgConfig::Readline)
        target_compile_definitions(sqlite.shell PRIVATE HAVE_READLINE)
        target_link_libraries(sqlite.shell PRIVATE PkgConfig::Readline)
    endif()

    find_package(ZLIB QUIET)
    if(TARGET ZLIB::ZLIB)
        target_compile_definitions(sqlite.shell PRIVATE SQLITE_HAVE_ZLIB)
        target_link_libraries(sqlite.shell PRIVATE ZLIB::ZLIB)
    endif()
endif()

# -- Testing -------------------------------------------------------------------

if(BUILD_TESTING AND SQLITE_BUILD_TESTING)
    enable_testing()

    add_test(NAME sqlite.test.check_version COMMAND sqlite::shell -version)
    set_tests_properties(
        sqlite.test.check_version
        PROPERTIES PASS_REGULAR_EXPRESSION "${sqlite_VERSION}"
    )
endif()

# -- Install & Export ----------------------------------------------------------

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

install(TARGETS sqlite.library EXPORT sqlite-targets)
install(
    FILES
        "${CMAKE_CURRENT_SOURCE_DIR}/source/sqlite3.h"
        "${CMAKE_CURRENT_BINARY_DIR}/sqlite3cfg.h"
        "${CMAKE_CURRENT_SOURCE_DIR}/source/sqlite3ext.h"
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

if(SQLITE_BUILD_SHELL)
    install(TARGETS sqlite.shell EXPORT sqlite-targets)
endif()

install(
    EXPORT sqlite-targets
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/sqlite"
    NAMESPACE sqlite::
)

configure_package_config_file(
    "${CMAKE_CURRENT_LIST_DIR}/cmake/sqlite-config.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/sqlite-config.cmake"
    INSTALL_DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/sqlite"
    NO_SET_AND_CHECK_MACRO
)

write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/sqlite-config-version.cmake"
    COMPATIBILITY SameMajorVersion
)

install(
    FILES
        "${CMAKE_CURRENT_BINARY_DIR}/sqlite-config.cmake"
        "${CMAKE_CURRENT_BINARY_DIR}/sqlite-config-version.cmake"
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/sqlite"
)

# -- Packaging -----------------------------------------------------------------

if(sqlite_IS_TOP_LEVEL)
    include(InstallRequiredSystemLibraries)
    include(CPack)
endif()
