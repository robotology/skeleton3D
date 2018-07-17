clc;
close all;
clear all;

%% Plot Figure 6
tmin = 8.0;
tmax = 20.0;
path = 'datasets/data_1710/';    % reach a point with changing valence stiff on elbow from reactCtrl 26/09/2017 140-200(neutral) Fig 8 140-160

plot_2_joint = 1;
plot_dist_thres = 0;        % neutral
plot_dist_mod_thres = 0;    % reduced
plot_dist_inc_thres = 0;    % increased
plot_dist_elbow = 0;
ylim_distEE = 1.2;
ylimEE = 0.13;
PLOT_JOINT=0; 
process_keypoint_pps_reactCtrl

prompt = 'Press any key to continue \n';
export2files = input(prompt,'s');

clc;
close all;
clear all;

%% Plot Figure 6
tmin = 8.0;
tmax = 20.0;
path = 'datasets/data_1735/';    % reach a point with changing valence stiff on elbow from reactCtrl 26/09/2017 140-200(neutral) Fig 8 140-160

plot_2_joint = 1;
plot_dist_thres = 0;        % neutral
plot_dist_mod_thres = 0;    % reduced
plot_dist_inc_thres = 0;    % increased
plot_dist_elbow = 0;
ylim_distEE = 0.8;
ylimEE = 0.3;
PLOT_JOINT=0; 
process_keypoint_pps_reactCtrl

prompt = 'Press any key to continue \n';
export2files = input(prompt,'s');