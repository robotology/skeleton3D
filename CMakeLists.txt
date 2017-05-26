# Copyright: (C) 2017 iCub Facility - Istituto Italiano di Tecnologia
# Author: Nguyen Dong Hai Phuong
# CopyPolicy: Released under the terms of the LGPLv2.1 or later, see LGPL.TXT

cmake_minimum_required(VERSION 2.8)

set(PROJECTNAME skeleton3D)
project(${PROJECTNAME})
#list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/lib/cmake)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

list(APPEND CMAKE_MODULE_PATH ${YARP_MODULE_PATH})

aux_source_directory(. SRC_LIST)

find_package(YARP REQUIRED)
find_package(ICUB REQUIRED)
find_package(ICUBcontrib REQUIRED)
find_package(icubclient)
find_package(kinectWrapper)

list(APPEND CMAKE_MODULE_PATH ${YARP_MODULE_PATH})
list(APPEND CMAKE_MODULE_PATH ${ICUB_MODULE_PATH})
list(APPEND CMAKE_MODULE_PATH ${ICUBCONTRIB_MODULE_PATH})

include(ICUBcontribHelpers)
include(ICUBcontribOptions)
icubcontrib_set_default_prefix()

add_definitions(${YARP_DEFINES})   # add yarp definitions - this contains also -D_REENTRANT
include(YarpInstallationHelpers)   # pick up yarp's cmake scripts

#set(main_project_path ${CMAKE_CURRENT_SOURCE_DIR})
#set(main_project_name ${PROJECTNAME})


#add_subdirectory(modules)

#add_subdirectory(app)

#include(YarpIDL)

set (include_files	${CMAKE_CURRENT_SOURCE_DIR}/include/skeleton3D.h)

set (source_files 	${CMAKE_CURRENT_SOURCE_DIR}/src/skeleton3D.cpp
		 	${CMAKE_CURRENT_SOURCE_DIR}/src/main.cpp)

#set(idl_files    skeleton3D.thrift)

#yarp_add_idl(IDL_GEN_FILES skeleton3D.thrift)

#source_group("IDL Files" FILES ${idl_files})

include_directories(    ${YARP_INCLUDE_DIRS}
                        ${ICUB_INCLUDE_DIRS}
                        ${kinectWrapper_INCLUDE_DIRS}
                        ${CMAKE_CURRENT_SOURCE_DIR}
                        ${CMAKE_CURRENT_SOURCE_DIR}/include)

add_definitions(-D_USE_MATH_DEFINES)

add_executable(${PROJECTNAME} ${SRC_LIST} ${lib_files} ${source_files} ${include_files} )#${IDL_GEN_FILES} ${idl_files})
target_link_libraries(${PROJECTNAME} ${YARP_LIBRARIES} ctrlLib ${icubclient_LIBRARIES})

install (TARGETS ${PROJECTNAME} DESTINATION bin)

#icubcontrib_finalize_export(${PROJECTNAME})
icubcontrib_add_uninstall_target()

