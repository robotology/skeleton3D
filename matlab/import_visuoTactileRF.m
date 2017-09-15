clear all;

path_prefix = '../data_1400/';

d_orig=importdata([path_prefix path_prefix_dumper 'ppsEvents/data.log']);

PACKET_ID_COLUMN = 1;
TIME_ABS_1_COLUMN = 2;
TIME_ABS_2_COLUMN = 3;

