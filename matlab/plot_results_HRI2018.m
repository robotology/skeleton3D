clc;
close all;
clear all;

%% Plot Figure 8
tmin = 142.0;
tmax = 155.0;
path = 'datasets/data_1650/';    % reach a point with changing valence stiff on elbow from reactCtrl 26/09/2017 140-200(neutral) Fig 8 140-160

plot_2_joint = 1;
plot_dist_thres = 1;        % neutral
plot_dist_mod_thres = 0;    % reduced
plot_dist_inc_thres = 0;    % increased
ylimEE = 0.03;
PLOT_JOINT=1 
process_keypoint_pps_reactCtrl

prompt = 'Press any key to continue \n';
export2files = input(prompt,'s');
%% Plot Figure 9
close all;
clear all;
tmin = 190.0;
tmax = 225.0;
path = 'datasets/data_1625/';    % reach a point with different valences for hand and head stiff on elbow from reactCtrl 170-240 Fig 9 190-225

plot_2_joint = 0;
plot_dist_thres = 0;        % neutral
plot_dist_mod_thres = 1;    % reduced
plot_dist_inc_thres = 1;    % increased
ylimEE = 0.08;
PLOT_JOINT=0
process_keypoint_pps_reactCtrl

prompt = 'Press any key to continue \n';
export2files = input(prompt,'s');
%% Plot Figure 10
close all;
clear all;
tmin = 110.0;
tmax = 130.0;
path = 'datasets/data_1655/';    % follow a circle with changing valence stiff on elbow from reactCtrl 26/09/2017 110-150 or 10-45 10-55 Fig 10 110-130

plot_2_joint = 0;
plot_dist_thres = 0;        % neutral
plot_dist_mod_thres = 1;    % reduced
plot_dist_inc_thres = 0;    % increased
ylimEE = 0.12;
PLOT_JOINT=1 
process_keypoint_pps_reactCtrl