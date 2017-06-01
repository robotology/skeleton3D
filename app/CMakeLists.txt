# Copyright: (C) 2017 iCub Facility - Istituto Italiano di Tecnologia
# Author: NGUYEN Dong Hai Phuong <phuong.nguyen@iit.it>
# CopyPolicy: Released under the terms of the GNU GPL v2.0.

file(GLOB conf 	${CMAKE_CURRENT_SOURCE_DIR}/conf/*.ini)

yarp_install(FILES ${conf} DESTINATION ${ICUBCONTRIB_CONTEXTS_INSTALL_DIR}/${PROJECTNAME})


