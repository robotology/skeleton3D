# Copyright: (C) 2017 iCub Facility - Istituto Italiano di Tecnologia
# Author: Phuong Nguyen
# CopyPolicy: Released under the terms of the GNU GPL v2.0.

cmake_minimum_required(VERSION 2.8)
project(visuoTactileCalib)

file(GLOB source *.cpp)
file(GLOB header *.h)

include_directories(${YARP_INCLUDE_DIRS})
include_directories(${periPersonalSpace_INCLUDE_DIRS})
include_directories(${OpenCV_INCLUDE_DIRS})

source_group("Source Files" FILES ${source})
source_group("Header Files" FILES ${header})


add_executable(visuoTactileCalib ${source} ${header} )

target_link_libraries(visuoTactileCalib ${periPersonalSpace_LIBRARIES} ${YARP_LIBRARIES} ${OpenCV_LIBRARIES})

install(TARGETS visuoTactileCalib DESTINATION bin)

