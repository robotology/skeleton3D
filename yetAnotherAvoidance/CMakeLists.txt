# Copyright: (C) 2017 iCub Facility - Istituto Italiano di Tecnologia
# Author: Phuong Nguyen (based on demoAvoidance of Alessandro Roncone)
# CopyPolicy: Released under the terms of the GNU GPL v2.0.

cmake_minimum_required(VERSION 2.8)
project(yetAnotherAvoidance)

include_directories(${YARP_INCLUDE_DIRS})
include_directories(${ICUB_INCLUDE_DIRS})

set(sources yetAnotherAvoidance.cpp)
source_group("Source Files" FILES ${sources})

add_executable(yetAnotherAvoidance ${sources})
target_link_libraries(yetAnotherAvoidance ${YARP_LIBRARIES} ctrlLib)
install(TARGETS yetAnotherAvoidance DESTINATION bin)

