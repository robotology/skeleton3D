skeleton3D [![Build Status](https://travis-ci.org/towardthesea/skeleton3D.svg?branch=feature%2Fadd-avoidance-module)](https://travis-ci.org/towardthesea/skeleton3D)
===

# Introduction
Bridge between 2D human pose estimation and 3D estimation from stereovision

# Table of Contents
1. [Dependencies](#dependencies)  
2. [Results](#results)
3. [Build](#build)
4. [How-to](#how-to)
5. [References](#references)

# Dependencies
- [YARP](https://github.com/robotology/yarp)
- [iCub](https://github.com/robotology/icub-main)
- [icub-contrib-common](https://github.com/robotology/icub-contrib-common)
- [icub-hri](https://github.com/robotology/icub-hri)
- [objectsPropertiesCollector](http://wiki.icub.org/brain/group__objectsPropertiesCollector.html) (OPC): a robot's working memory.
- [stereo-vision](https://github.com/robotology/stereo-vision): 3D estimation from stereo-vision camera
- [deeperCut based skeleton2D](https://github.com/towardthesea/pose-tensorflow) or [yarpOpenPose](https://github.com/robotology/human-sensing/tree/master/yarpOpenPose): 2D human pose tracking
- Optional modules: for human-robot interaction demos
	- [Peripersonal Space](https://github.com/robotology/peripersonal-space)
	- [react-ctrl](https://github.com/robotology/react-control)
	- [modified onthefly-recognition](https://github.com/towardthesea/onthefly-recognition): the built module's name is changed, so there will be no conflict with the official module.
	- [cardinal-points-grasp](https://github.com/robotology/cardinal-points-grasp)

# Results
## Safe HRI demo
[![Safe pHRI](https://img.youtube.com/vi/A9Por3anPJ8/0.jpg)](https://www.youtube.com/watch?v=A9Por3anPJ8)

## Hand-over demo
[![Hand-over](https://img.youtube.com/vi/zNbLCC10qX4/0.jpg)](https://www.youtube.com/watch?v=zNbLCC10qX4)

# Build
Build and Install normally, i.e.
```
mkdir build && cd build
ccmake ..
make install
```

# How-to

## Safe HRI demo
1. Open the application with openpose, [PS_modulation_iCub_skeleton3D_openpose](https://github.com/robotology/skeleton3D/blob/master/app/script/PPS_modulation_iCub_skeleton3D_openpose.xml), or application with deepcut, [PPS_modulation_iCub_skeleton3D](https://github.com/robotology/skeleton3D/blob/master/app/script/PPS_modulation_iCub_skeleton3D.xml) in **yarpmanager**. Note that application with deeperCut provides more responsive robot's actions. 
2. Launch all module and connect. 
3. (Optional) If you want to use application with deeperCut, you have to run **skeleton2D.py** in terminal rather than yarpmanager. The possibility to run python script from yarp manager is broken now.
	```
	# Open a terminal and ssh to machine with GPU, e.g. `icub-cuda`
	ssh icub-cuda
	skeleton2D.py --des /skeleton2D --gpu 0.7
	```
4. Users can log into *rpc service* of the module to set the parameters by:
	```
	yarp rpc /skeleton3D/rpc
	# help function by typing:
	help
	```
5. Move the icub's neck to look down about 23 degree, e.g. with **yarpmotorgui**. If you run **icubCollaboration** (see below), this step is not necessary.
6. Connect to the *rpc service* of *react-controller*, and make the **controlled arm** (left by default) move: 
	- To a fix position: in this mode, robot tries to keep its end-effector at a fix position, e.g. (-0.3,-0.15,0.1) for **left_arm** of icub, while avoiding human's body parts
	```
	yarp rpc /reactController/rpc:i  
	# for the *left_arm*
	set_xd (-0.3 -0.15 0.1)

	# or for the *right_arm*
	set_xd (-0.3 0.15 0.1)

	# to stop typing:
	stop
	```
	- In a circle: in this mode, robot moves its end-effector along a circle trajectory in the y and z axes, relative to the current end-effector position, while avoiding human's body parts. The first command moves robot's arm to a tested *safe* initial position for the circle trajectory.
	```
	set_xd (-0.3 -0.15 0.1)
	set_relative_circular_xd 0.08 0.27

	# to stop typing:
	stop
	```

- Note: users can tune the workspace parameters in [configuration file](https://github.com/robotology/skeleton3D/blob/master/app/conf/skeleton3D.ini) to constrain the robot's partner. The module currently works with only one partner at a time.

## Hand-over demo
1. First, do all the above step
2. Open the application script, [ontheflyRecognition_PPS_both](https://github.com/robotology/skeleton3D/blob/master/app/script/ontheflyRecognition_PPS_both.xml), in **yarpmanager**. This app allows on-hand object training and on-hand object recognition.
	```
	# Connect to **skeleton3D**:
	yarp rpc /skeleton3D/rpc
	enable_tool_training right

	# Connect to **onTheFlyRecognition_right**
	yarp rpc /onTheFlyRecognition_right/human:io
	# Hold object on the right hand and type:	
	train <object_name> 0

	# The whole procedure can be applied for the left hand also
	```	
3. Open the application script, [iolVM_Phuong](https://github.com/robotology/skeleton3D/blob/master/app/script/iolVM_Phuong.xml), in **yarpmanager**. This app allows on-table object recognition for grasping
4. Open the application script, [grasp-processor](https://github.com/robotology/cardinal-points-grasp/blob/master/app/scripts/grasp-processor.xml.template), in **yarpmanager**. This app allows robot to grasp recognized object on the table.
5. Run module [icubCollaboration](https://github.com/robotology/skeleton3D/tree/master/icubCollaboration). Currently, all connections to other modules are internally, so it needs to run after all others.
6. Connect all ports.
	```
	# the robot arm using for **icubCollaboration** needs to be the same as **react-ctrl** above
	icubCollaboration --robot icub --part <right_arm/left_arm>
	
	# rpc access to the module
	yarp rpc /icubCollaboration/rpc

	# type help for all support commands
	help

	# hold a trained object (within the robot's reachable area) and type:
	receive <object_name> 
	# robot should detect the object, take-over it and put it on the table (see the video)

	# ask robot to give the object on the table
	pre_grasp_pos
	hand_over_object <object_name> <handRight/handLeft>
	
	```

# References

> D. H. P. Nguyen, M. Hoffmann, A. Roncone, U. Pattacini, and G. Metta, [“Compact Real-time Avoidance on a Humanoid Robot for Human-robot Interaction,”](https://dl.acm.org/citation.cfm?id=3171245) in Proceedings of the 2018 ACM/IEEE International Conference on Human-Robot Interaction, 2018, pp. 416–424.

> P. D. Nguyen, F. Bottarel, U. Pattacini, H. Matej, L. Natale, and G. Metta, [“Merging physical and social interaction for effective human-robot collaboration,”](https://www.researchgate.net/publication/328314301_Merging_physical_and_social_interaction_for_effective_human-robot_collaboration) in Humanoid Robots (Humanoids), 2018 IEEE-RAS 18th International Conference on, 2018, pp. 710–717.





