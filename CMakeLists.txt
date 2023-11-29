
cmake_minimum_required(VERSION 3.1)
project(Fullerenes)

set(CMAKE_CXX_STANDARD 17)
set(FULLERENE_DATABASE_PATH ${CMAKE_CURRENT_LIST_DIR}/database/ CACHE PATH "Path to fullerene database root")
set(FORTRAN_NMAX 5000 CACHE STRING "Maximum vertex count for Fortran routines using statically allocated memory")

set(BLA_VENDOR Intel10_64lp_seq)
find_package(BLAS)
find_package(LAPACK)
find_package(GSL)
include(CheckLanguage)
check_language(CUDA)

# Get the current working branch
execute_process(
  COMMAND git rev-parse --abbrev-ref HEAD
  WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
  OUTPUT_VARIABLE GIT_BRANCH
  OUTPUT_STRIP_TRAILING_WHITESPACE
)

# Get the latest abbreviated commit hash of the working branch
execute_process(
  COMMAND git log -1 --format=%h
  WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
  OUTPUT_VARIABLE GIT_COMMIT_HASH
  OUTPUT_STRIP_TRAILING_WHITESPACE
)

# C++ configure file
configure_file(
  ${CMAKE_CURRENT_LIST_DIR}/include/fullerenes/config.hh.in
  ${CMAKE_BINARY_DIR}/include/fullerenes/config.hh
  )

# Fortran configure file
configure_file(
  ${CMAKE_CURRENT_LIST_DIR}/include/fullerenes/config.f.in
  ${CMAKE_CURRENT_LIST_DIR}/src/fortran/config.f
)


include_directories(AFTER SYSTEM include)
include_directories(${CMAKE_BINARY_DIR}/include/)


# Fortran compiler flags
set(CMAKE_Fortran_FLAGS "-fPIC -cpp -O3 -m64")
# C++ compiler flags
set(CMAKE_CXX_FLAGS "-std=c++1z -fPIC -O3 -m64 -pthread")

add_subdirectory(src/c++)
add_subdirectory(src/fortran)
add_subdirectory(src/contrib)
add_subdirectory(playground)
add_subdirectory(programs)
add_subdirectory(benchmarks)
add_subdirectory(tests)
add_subdirectory(unit-tests)








