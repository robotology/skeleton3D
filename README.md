skeleton3D [![Build Status](https://travis-ci.org/towardthesea/skeleton3D.svg?branch=feature%2Fadd-avoidance-module)](https://travis-ci.org/towardthesea/skeleton3D)
===

# Introduction
Bridge between 2D human pose estimation and 3D estimation from stereovision

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


# Build
Build and Install normally, i.e.
```
mkdir build && cd build
ccmake ..
make install
```

# Launch
- Open the [application with openpose](https://github.com/robotology/skeleton3D/blob/master/app/script/PPS_modulation_iCub_skeleton3D_openpose.xml) or [application with deepcut](https://github.com/robotology/skeleton3D/blob/master/app/script/PPS_modulation_iCub_skeleton3D.xml) in yarpmanager. Note that application with deeperCut provides more responsive robot's actions. 
- Launch all module and connect
- Move the icub's neck to look down about 20 degree, e.g. with **yarpmotorgui**
- Connect to the *rpc service* of *react-controller*, and make the *controlled arm* (left by default) move 
	- To a fix position: in this mode, robot tries to keep its end-effector at a fix position, e.g. (-0.3,-0.15,0.1), while avoiding the approaching red ball
	```
	yarp rpc /reactController/rpc:i  
	set_xd (-0.3 -0.15 0.1)
	```
	- In a circle: in this mode, robot moves its end-effector along a circle trajectory in the y and z axes, relative to the current end-effector position, while avoiding the approaching red ball. The first command moves robot's arm to a tested *safe* initial position for the circle trajectory.
	```
	set_xd (-0.3 -0.15 0.1)
	set_relative_circular_xd 0.08 0.27
	```

- Note: users can tune the workspace parameters in [configuration file](https://github.com/robotology/skeleton3D/blob/master/app/conf/skeleton3D.ini) to constrain the robot's partner. The module currently works with only one partner at a time.

# References:
```
D. H. P. Nguyen, M. Hoffmann, A. Roncone, U. Pattacini, and G. Metta, “Compact Real-time Avoidance on a Humanoid Robot for Human-robot Interaction,” in Proceedings of the 2018 ACM/IEEE International Conference on Human-Robot Interaction, 2018, pp. 416–424.

```
```
P. D. Nguyen, F. Bottarel, U. Pattacini, H. Matej, L. Natale, and G. Metta, “Merging physical and social interaction for effective human-robot collaboration,” in Humanoid Robots (Humanoids), 2018 IEEE-RAS 18th International Conference on, 2018, pp. 710–717.
```




