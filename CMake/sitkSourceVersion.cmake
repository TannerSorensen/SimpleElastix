#
# This CMake code extracts the information from the git repository,
# and automatically causes a reconfigure if the git HEAD changes. The
# following variable may defined after execution:
#
# _GIT_VERSION_HASH - the SHA1 hash of the current HEAD
#
# Based on the most recent tag starting with the letter "v" for
# version, which is expected to be of the form
# vN.N[.N[.N][(a|b|c|rc[N])] the following is extracted or undefined:
#
# _GIT_VERSION_MAJOR
# _GIT_VERSION_MINOR
# _GIT_VERSION_PATCH
# _GIT_VERSION_TWEAK
# _GIT_VERSION_RC
#
# If the current projects version ( defiend by
# ${CMAKE_PROJECT_NAME}_VERSION_MAJOR and MINOR and PATCH and TWEAK
# match that of the tag, then it'll be considered the project is in
# post release mode otherwise it's considered underdevelopment.
#
# One of the following variables will be defined as number of commits
# since the projects Version.cmake file has been modified.
#
# _GIT_VERSION_POST
# _GIT_VERSION_DEV
#


include(GetGitRevisionDescription)

get_git_head_revision(GIT_REFSPEC _GIT_VERSION_HASH)

if(_GIT_VERSION_HASH MATCHES "[a-fA-F0-9]+")
  string(SUBSTRING "${_GIT_VERSION_HASH}" 0 5 _GIT_VERSION_HASH)
endif()

# find the closest anotated tag with the v prefix for version
git_describe(_GIT_TAG "--match=v*" "--abbrev=0")

git_commits_since("${PROJECT_SOURCE_DIR}/Version.cmake" _GIT_VERSION_COUNT)

set(VERSION_REGEX "^v([0-9]+)\\.([0-9]+)+(\\.([0-9]+))?(\\.([0-9]+))?((a|b|c|rc)([0-9]+))?")

string(REGEX MATCH "${VERSION_REGEX}" _out "${_GIT_TAG}")

if("${_out}" STREQUAL "")
  message(WARNING "git tag: \"${_GIT_TAG}\" does not match expected version format!")
  return()
endif()

set(_GIT_VERSION_MAJOR "${CMAKE_MATCH_1}")
set(_GIT_VERSION_MINOR "${CMAKE_MATCH_2}")
if(NOT "${CMAKE_MATCH_4}" STREQUAL "")
  set(_GIT_VERSION_PATCH "${CMAKE_MATCH_4}")
endif()
if(NOT "${CMAKE_MATCH_6}" STREQUAL "")
  set(_GIT_VERSION_TWEAK "${CMAKE_MATCH_6}")
endif()
if(NOT "${CMAKE_MATCH_7}" STREQUAL "")
  set(_GIT_VERSION_RC "${CMAKE_MATCH_7}" ) # a,b,rc01 etc
endif()

set(_GIT_VERSION "${_GIT_VERSION_MAJOR}.${_GIT_VERSION_MINOR}")
if(DEFINED _GIT_VERSION_PATCH)
  set(_GIT_VERSION "${_GIT_VERSION}.${_GIT_VERSION_PATCH}")
  if(DEFINED _GIT_VERSION_TWEAK)
    set(_GIT_VERSION "${_GIT_VERSION}.${_GIT_VERSION_TWEAK}")
  endif()
endif()


set(_${CMAKE_PROJECT_NAME}_VERSION "${${CMAKE_PROJECT_NAME}_VERSION_MAJOR}.${${CMAKE_PROJECT_NAME}_VERSION_MINOR}")
if(DEFINED ${CMAKE_PROJECT_NAME}_VERSION_PATCH)
  set(_${CMAKE_PROJECT_NAME}_VERSION "${_${CMAKE_PROJECT_NAME}_VERSION}.${${CMAKE_PROJECT_NAME}_VERSION_PATCH}")
  if(DEFINED ${CMAKE_PROJECT_NAME}_VERSION_TWEAK)
    set(_${CMAKE_PROJECT_NAME}_VERSION "${_${CMAKE_PROJECT_NAME}_VERSION}.${${CMAKE_PROJECT_NAME}_VERSION_TWEAK}")
  endif()
endif()


if(_GIT_VERSION VERSION_EQUAL _${CMAKE_PROJECT_NAME}_VERSION)
  if(_GIT_VERSION_COUNT) #ignore if 0
    set(_GIT_VERSION_POST "${_GIT_VERSION_COUNT}")
  endif()
else()
  # The first commit after a tag should increase the project version
  # number in Version.cmake and be "dev1"
  MATH(EXPR _GIT_VERSION_COUNT "${_GIT_VERSION_COUNT}+1")
  set(_GIT_VERSION_DEV "${_GIT_VERSION_COUNT}")
endif()
