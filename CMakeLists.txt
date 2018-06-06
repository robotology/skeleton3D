# Copyright: (C) 2017 iCub Facility - Istituto Italiano di Tecnologia
# Author: Nguyen Dong Hai Phuong <phuong.nguyen@iit.it>
# CopyPolicy: Released under the terms of the LGPLv2.1 or later, see LGPL.TXT

cmake_minimum_required(VERSION 2.8)

set(PROJECTNAME human-pose3D)
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
find_package(OpenCV REQUIRED)
# find_package(periPersonalSpace)
# find_package(TensorflowCC COMPONENTS Shared)

list(APPEND CMAKE_MODULE_PATH ${YARP_MODULE_PATH})
list(APPEND CMAKE_MODULE_PATH ${ICUB_MODULE_PATH})
list(APPEND CMAKE_MODULE_PATH ${ICUBCONTRIB_MODULE_PATH})

include(ICUBcontribHelpers)
include(ICUBcontribOptions)
icubcontrib_set_default_prefix()

add_definitions(${YARP_DEFINES})   # add yarp definitions - this contains also -D_REENTRANT
include(YarpInstallationHelpers)   # pick up yarp's cmake scripts

set(main_project_path ${CMAKE_CURRENT_SOURCE_DIR})
#set(main_project_name ${PROJECTNAME})


#add_subdirectory(modules)

add_subdirectory(app)
add_subdirectory(yetAnotherAvoidance)
#add_subdirectory(visuoTactileCalib)
add_subdirectory(skeleton3D)
add_subdirectory(icubCollaboration)

#set (lib_files          ${CMAKE_CURRENT_SOURCE_DIR}/lib/include/iCub/vtMappingTF/vtMappingTF.h
#                        ${CMAKE_CURRENT_SOURCE_DIR}/lib/src/vtMappingTF.cpp)


#set(idl_files    skeleton3D.thrift)

#yarp_add_idl(IDL_GEN_FILES skeleton3D.thrift)

#source_group("IDL Files" FILES ${idl_files})

#include_directories(    ${YARP_INCLUDE_DIRS}
#                        ${ICUB_INCLUDE_DIRS}
#                        ${kinectWrapper_INCLUDE_DIRS}
#                        ${CMAKE_CURRENT_SOURCE_DIR}
#                        ${CMAKE_CURRENT_SOURCE_DIR}/lib/include
#                        ${CMAKE_CURRENT_SOURCE_DIR}/lib/include/iCub/vtMappingTF
#                        ${CMAKE_CURRENT_SOURCE_DIR}/include)

#add_definitions(-D_USE_MATH_DEFINES)

#add_executable(${PROJECTNAME} ${SRC_LIST} ${source_files} ${include_files} ${IDL_GEN_FILES} ${idl_files} ${lib_files})
#target_link_libraries(${PROJECTNAME} ${YARP_LIBRARIES} ctrlLib ${icubclient_LIBRARIES} TensorflowCC::Shared)

#install (TARGETS ${PROJECTNAME} DESTINATION bin)

#icubcontrib_finalize_export(${PROJECTNAME})
icubcontrib_add_uninstall_target()

