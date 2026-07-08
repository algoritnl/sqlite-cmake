cmake_minimum_required(VERSION 3.16...4.3)

project(PrintLibVersion VERSION 1.0.0 LANGUAGES C)

find_package(SQLite3 3.33.0 REQUIRED CONFIG)

add_executable(print_libversion print_libversion.c)
target_link_libraries(print_libversion SQLite3::SQLite3)

include(CTest)
add_test(NAME print_libversion COMMAND print_libversion)
set_property(
    TEST print_libversion
    PROPERTY PASS_REGULAR_EXPRESSION "${SQLite3_VERSION}"
)
