# Copyright: (C) 2017 iCub Facility - Istituto Italiano di Tecnologia
# Author: Phuong Nguyen
# CopyPolicy: Released under the terms of the GNU GPL v2.0.

cmake_minimum_required(VERSION 2.8)
project(visuoTactileCalib)

file(GLOB source *.cpp)
file(GLOB header *.h)

set (include_files	${CMAKE_CURRENT_SOURCE_DIR}/vtCalib.h
                        ${main_project_path}/lib/include/iCub/vtMappingTF/vtMappingTF.h)

set (source_files 	${CMAKE_CURRENT_SOURCE_DIR}/vtCalib.cpp
                        ${main_project_path}/lib/src/vtMappingTF.cpp
                        ${CMAKE_CURRENT_SOURCE_DIR}/vtCalibModule.cpp)

include_directories(${YARP_INCLUDE_DIRS})
include_directories(${periPersonalSpace_INCLUDE_DIRS})
include_directories(${OpenCV_INCLUDE_DIRS})
include_directories(${main_project_path}/lib/include
                    ${main_project_path}/lib/include/iCub/vtMappingTF)

source_group("Source Files" FILES ${source})
source_group("Header Files" FILES ${header})


add_executable(visuoTactileCalib ${source} ${header} ${source_files} ${include_files} )

target_link_libraries(visuoTactileCalib ${periPersonalSpace_LIBRARIES} ${YARP_LIBRARIES} ${icubclient_LIBRARIES} TensorflowCC::Shared)

install(TARGETS visuoTactileCalib DESTINATION bin)

