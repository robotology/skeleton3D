clear all;
cd ~/icub-workspace/skeleton3D/matlab
path_prefix = 'data_1800/';
path_prefix_dumper = '';

d_orig=importdata([path_prefix path_prefix_dumper 'keypoints/data.log']);

PACKET_ID_COLUMN = 1;
TIME_ABS_1_COLUMN = 2;
TIME_ABS_2_COLUMN = 3;

