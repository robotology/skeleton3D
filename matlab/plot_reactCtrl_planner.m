clc;
clear all;
close all;

%% Plot flags & Init
PLOT_KEYPOINT_EVOLUTION = 0;
PLOT_DISTANCE_SEPARATE = 0;
PLOT_ACTIVATION_SEPARATE = 0;
PLOT_SEPARATE_ALL = 0;
PLOT_DIST_EE = 0;

EXPORT_TO_FILES = 1;
results_path = './results';


FontSZ = 16;
LineSZ = 2;

% tmin = 142.0;
% tmax = 155.0;
% 
% % New format data
% % path = 'data_1425/';    % reach a point with changing valence stiff on elbow from reactCtrl     40-110
% % path = 'data_1430/';    % follow a circle with changing valence stiff on elbow from reactCtrl 10-130    65-100
% path = 'data_1625/';    % reach a point with different valences for hand and head stiff on elbow from reactCtrl 170-240 Fig 9 190-225
% path = 'data_1650/';    % reach a point with changing valence stiff on elbow from reactCtrl 26/09/2017 140-200(neutral) Fig 8 140-160
% % path = 'data_1655/';    % follow a circle with changing valence stiff on elbow from reactCtrl 26/09/2017 110-150 or 10-45 10-55 Fig 10 110-130
% % path = 'data_1755/';    % follow a circle with changing valence stiff on elbow from reactCtrl 26/09/2017 90-170
% path = 'datasets/planner/data_planner_reactCtrl_20181018_1325/';
 path = 'datasets/planner/data_planner_reactCtrl_20181018_1205/';
%path = 'datasets/planner/data_planner_reactCtrl_20181018_1450/';
 path = 'datasets/planner/data_planner_reactCtrl_20181018_1625/';
 %path = 'datasets/planner/data_planner_reactCtrl_20181018_1640/';
 path = 'datasets/planner/data_planner_reactCtrl_20181018_1710/';
 path = 'datasets/planner/data_planner_reactCtrl_20181019_1330/';
 path = 'datasets/planner/data_planner_reactCtrl_20181019_1505/';
 path = 'datasets/planner/data_planner_reactCtrl_20181019_1520/';
 path = 'datasets/planner/data_planner_reactCtrl_20181019_1600/';   % good EB   0.0129 +- 0.0065, 0.0104 +- 0.0061
 path = 'datasets/planner/data_planner_reactCtrl_20181019_1620/';   % bad EB    0.0112 +- 0.0065, 0.0173 +- 0.0146
 path = 'datasets/planner/data_planner_reactCtrl_20181019_1640/';   % normal    0.0101 +- 0.0076, 0.0104 +- 0.0089
 path = 'datasets/planner/data_planner_reactCtrl_20181019_1650/';   % bad       0.0066 +- 0.0044, 0.0360 +- 0.0289
 path = 'datasets/planner/data_planner_reactCtrl_20181019_1700/';   % bad       0.0061 +- 0.0030, 0.0255 +- 0.0173
 path = 'datasets/planner/data_planner_reactCtrl_20181019_1720/';   % good      0.0142 +- 0.0075, 0.0124 +- 0.0074
 path = 'datasets/planner/data_planner_reactCtrl_20181019_1730/';   % good      0.0107 +- 0.0074, 0.0229 +- 0.0162
 path = 'datasets/planner/data_planner_reactCtrl_20181019_1755/';   % bad       0.0107 +- 0.0062, 0.0186 +- 0.0183

%% react-ctrl
addpath(genpath('./reactController/'));
analyze;

time0 = time0_reactCtrl;
time_rel_reactCtrl = time_reactCtrl - time0;


%% Plot

figure; 
title('End-effector evolution');
% plot3(EE_t(:,1),EE_t(:,2),EE_t(:,3),'b', posEB(:,1),posEB(:,2),posEB(:,3),'r', hL(:,1), hL(:,2), hL(:,3), '*--'); 
% plot3(EE_t(:,1),EE_t(:,2),EE_t(:,3),'b', EB_t(:,1),EB_t(:,2),EB_t(:,3),'r'); % with modified reactCtrl dumping from 1400 19/09/2017
% title('Evolution of EE and EB over time','FontSize',FontSZ); grid on;
% xlabel('x(m)','FontSize',FontSZ);
% ylabel('y(m)','FontSize',FontSZ);
% zlabel('z(m)','FontSize',FontSZ);
dispEE = [];
for i=1:length(EE_t)
    dispEE = [dispEE; norm(EE_t(i,:) - EEd_t(i,:))];
end
mean_dispEE = mean(dispEE)
std_dispEE = std(dispEE)
max_dispEE = max(dispEE)

dispEB = [];
for i=1:length(EB_t)
    dispEB = [dispEB; norm(EB_t(i,:) - EBd_t(i,:))];
end
mean_dispEB = mean(dispEB)
std_dispEB = std(dispEB)
max_dispEB = max(dispEB)


lArm_t = [];
for i=1:length(EB_t)
    lArm_t = [lArm_t; norm(EB_t(i,:) - EE_t(i,:))];
end

lArm_d = [];
for i=1:length(EB_t)
    lArm_d = [lArm_d; norm(EBd_t(i,:) - EEd_t(i,:))];
end

for i=1:3
    subplot(3,1,i)
    plot(time_rel_reactCtrl, EE_t(:,i),'b',time_rel_reactCtrl, EEd_t(:,i),'r','LineWidth',LineSZ);
    switch i
        case 1,
            ylabel('x (m)','FontSize',FontSZ);
        case 2,
            ylabel('y (m)','FontSize',FontSZ);
        case 3,
            ylabel('z (m)','FontSize',FontSZ);
            xlabel('time (s)', 'FontSize',FontSZ);
    end
    grid on
end


figure;
title('Elbow evolution');
for i=1:3
    subplot(3,1,i)
    plot(time_rel_reactCtrl, EB_t(:,i),'b',time_rel_reactCtrl, EBd_t(:,i),'r','LineWidth',LineSZ);
        switch i
        case 1,
            ylabel('x (m)','FontSize',FontSZ);
        case 2,
            ylabel('y (m)','FontSize',FontSZ);
        case 3,
            ylabel('z (m)','FontSize',FontSZ);
            xlabel('time (s)', 'FontSize',FontSZ);
        end
    grid on
end

figure;
subplot(2,1,1); plot(time_rel_reactCtrl, dispEE,'b','LineWidth',LineSZ); ylabel('End-effector error (m)','FontSize',FontSZ);
subplot(2,1,2); plot(time_rel_reactCtrl, dispEB,'b','LineWidth',LineSZ); ylabel('Elbow error (m)','FontSize',FontSZ);
xlabel('time (s)', 'FontSize',FontSZ);

figure;
subplot(2,1,1); plot(time_rel_reactCtrl, lArm_d,'b','LineWidth',LineSZ); ylabel('Arm length desire (m)','FontSize',FontSZ);
subplot(2,1,2); plot(time_rel_reactCtrl, lArm_t,'b','LineWidth',LineSZ); ylabel('Arm length measure (m)','FontSize',FontSZ);
xlabel('time (s)', 'FontSize',FontSZ);