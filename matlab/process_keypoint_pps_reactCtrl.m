clc;
clear all;
close all;

%% Plot flags
PLOT_KEYPOINT_EVOLUTION = 0
idx_ppsEv_on_skin_act = 8;

%% Keypoints
path = 'data_1800/';
filename_keypoints = 'keypoints/data.log';
filename = strcat(path,filename_keypoints);
[time_kp,head, hR, hL, eR, eL, sR, sL, sp] = importfile_keypoints(filename);
time0_kp = time_kp(1);

%% Joints
filename_joints_torso = 'joints_torso/data.log';
filename = strcat(path, filename_joints_torso);
[time_jnts_torso, jnts_torso] = importfile_joints_torso(filename);
time0_jnts_torso = time_jnts_torso(1);

filename_joints_lA = 'joints_leftArm/data.log';
filename = strcat(path, filename_joints_lA);
[time_jnts_lA, jnts_lA, jnts_lH] = importfile_joints_arm(filename);
time0_jnts_lA = time_jnts_lA(1);

% Balance the nb of member of torso and arm joints dataset
time0_jnts = max([time0_jnts_torso, time0_jnts_lA]);
id_remove_jnts_torso = find(time_jnts_torso<time0_jnts);
time_jnts_torso(id_remove_jnts_torso,:) = [];
jnts_torso(id_remove_jnts_torso,:) = [];
time0_jnts_torso = time_jnts_torso(1);

id_remove_jnts_lA = find(time_jnts_lA<time0_jnts);
time_jnts_lA(id_remove_jnts_lA,:) = [];
jnts_lA(id_remove_jnts_lA,:) = [];
jnts_lH(id_remove_jnts_lA,:) = [];
time0_jnts_lA = time_jnts_lA(1);

%% pps
process_ppsEvents

%% Convert time variables to the same reference
time0 = min([time0_kp,time0_pps, time0_jnts_torso, time0_jnts_lA]);
time_rel_kp = time_kp-time0;
time_rel_pps = time_pps-time0;
time_rel_jnts_torso = time_jnts_torso-time0;
time_rel_jnts_lA = time_jnts_lA-time0;

time_delta_kp = [];
for i=2:length(time_rel_kp)
    delta = time_rel_kp(i)-time_rel_kp(i-1);
    time_delta_kp = [time_delta_kp;delta];
end

%% Forward Kinematics
addpath(genpath('./ICubFwdKin/'));
wtheta = jnts_torso*pi/180;
latheta = jnts_lA * pi/180;
id_max_jnt = min(length(wtheta),length(latheta));
posEE = [];
for i=1:id_max_jnt
    [T_Ro0_l, T_0n_l, J_l, G_sL8_l, G_sL10_l] = WaistLeftArmFwdKin(wtheta(i,:),latheta(i,:), 0);  % last 0 --> no display
    posEE = [posEE; T_0n_l(1:3,4)'];
end
figure; plot3(posEE(:,1),posEE(:,2),posEE(:,3)); title('Evolution of EE over time','FontSize',14); grid on;

%% Find distance between visual events and average taxel
dist_head=[];
dist_hR=[];
dist_hL=[];
for i=1:length(time_rel_pps)
    idx = max(find(time_rel_kp<=time_rel_pps(i)));
    if (~isempty(idx))
        dist_head_cur = find_dist_kpEv_skin_part(idx,head,i,part1,part2,part4,part5);
        dist_head = [dist_head;min(dist_head_cur)];
        
        dist_hR_cur = find_dist_kpEv_skin_part(idx,hR,i,part1,part2,part4,part5);
        dist_hR = [dist_hR;min(dist_hR_cur)];

        dist_hL_cur = find_dist_kpEv_skin_part(idx,hL,i,part1,part2,part4,part5);
        dist_hL = [dist_hL;min(dist_hL_cur)];
    else
        dist_head = [dist_head;1000];
        dist_hR = [dist_hR;1000];
        dist_hL = [dist_hL;1000];
    end
end

%% Find the closest distance of the whole operation and draw the relation of event & taxel in 3D
[dist_hL_min, dist_hL_id_pps] = min(dist_hL);
dist_hL_id_kp = max(find(time_rel_kp<=time_rel_pps(dist_hL_id_pps-5)));
% plot_kp_skinPart_3d(dist_hL_id_kp,hL,'hand left', dist_hL_id_pps-5,part1,part2,part4,part5);

[dist_hR_min, dist_hR_id_pps] = min(dist_hR);
dist_hR_id_kp = max(find(time_rel_kp<=time_rel_pps(dist_hR_id_pps)));
% plot_kp_skinPart_3d(dist_hR_id_kp,hR,'hand right', dist_hR_id_pps,part1,part2,part4,part5);

%% Plot
% Activation over time
plot_activation(time_rel_pps, part1(:,idx_ppsEv_on_skin_act),'left hand');
plot_activation(time_rel_pps, part2(:,idx_ppsEv_on_skin_act),'left forearm');
plot_activation(time_rel_pps, part4(:,idx_ppsEv_on_skin_act),'right hand');
plot_activation(time_rel_pps, part5(:,idx_ppsEv_on_skin_act),'right forearm');
% Distance of an arm locus (hand, wrist, mid-arm, elbow) over time

% Keypoint evolution
if PLOT_KEYPOINT_EVOLUTION
    keep = find(time_rel_kp>11.0 & time_rel_kp<42.0);
    keep = find(time_rel_kp>0.0);

    plot_keypoint(time_rel_kp(keep), head(keep,:), 'head');
    plot_keypoint(time_rel_kp(keep), hR(keep,:), 'hand right');
    plot_keypoint(time_rel_kp(keep), hL(keep,:), 'hand left');
    plot_keypoint(time_rel_kp(keep), eR(keep,:), 'elbow right');
    plot_keypoint(time_rel_kp(keep), eL(keep,:), 'elbow left');
    plot_keypoint(time_rel_kp(keep), sR(keep,:), 'shoulder right');
    plot_keypoint(time_rel_kp(keep), sL(keep,:), 'shoulder left');
end

moment = find(abs(time_rel_kp-20.0)<1.0 & abs(time_rel_kp-20.0)>=0.0);
figure; plot3(head(moment,1), head(moment,2), head(moment,3), '*--r', 'LineWidth',2); grid on; 

