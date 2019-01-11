# Copyright: (C) 2017 iCub Facility - Istituto Italiano di Tecnologia
# Author: Phuong Nguyen
# CopyPolicy: Released under the terms of the GNU GPL v2.0.

cmake_minimum_required(VERSION 2.8)
project(skeleton3D)

#set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

#include(YarpIDL)

file(GLOB source *.cpp)
file(GLOB header *.h)

set (include_files	${CMAKE_CURRENT_SOURCE_DIR}/skeleton3D.h
                        ${CMAKE_CURRENT_SOURCE_DIR}/udp_client_server.h)
#                        ${main_project_path}/lib/include/iCub/vtMappingTF/vtMappingTF.h)

set (source_files 	${CMAKE_CURRENT_SOURCE_DIR}/skeleton3D.cpp
#                        ${main_project_path}/lib/src/vtMappingTF.cpp
                        ${CMAKE_CURRENT_SOURCE_DIR}/udp_client_server.cpp
                        ${CMAKE_CURRENT_SOURCE_DIR}/main.cpp)

include_directories(${OpenCV_INCLUDE_DIRS})
include_directories(${YARP_INCLUDE_DIRS}
                    ${ICUB_INCLUDE_DIRS}
                    ${kinectWrapper_INCLUDE_DIRS})
include_directories(${main_project_path}/lib/include)
#                    ${main_project_path}/lib/include/iCub/vtMappingTF)

source_group("Source Files" FILES ${source})
source_group("Header Files" FILES ${header})

set(idl_files    skeleton3D.thrift)

yarp_add_idl(IDL_GEN_FILES skeleton3D.thrift)

source_group("IDL Files" FILES ${idl_files})

add_definitions(-D_USE_MATH_DEFINES)

add_executable(skeleton3D ${source} ${header} ${source_files} ${include_files} ${IDL_GEN_FILES} ${idl_files}) #${lib_files})# ${source_files} ${include_files} )

target_link_libraries(skeleton3D ${YARP_LIBRARIES} ${icubclient_LIBRARIES} ${OpenCV_LIBRARIES} ctrlLib)# TensorflowCC::Shared)

install(TARGETS skeleton3D DESTINATION bin)

