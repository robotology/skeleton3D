clc;
clear all;
close all;

%% Plot flags
PLOT_KEYPOINT_EVOLUTION = 0
idx_ppsEv_on_skin_act = 8;
FontSZ = 16;

%% Keypoints
path = 'data_1535/';
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

%% react-ctrl
addpath(genpath('./reactController/'));
analyze;

%% Convert time variables to the same reference
time0 = min([time0_kp,time0_pps, time0_jnts_torso, time0_jnts_lA, time0_reactCtrl]);
time_rel_kp = time_kp-time0;
time_rel_pps = time_pps-time0;
time_rel_jnts_torso = time_jnts_torso-time0;
time_rel_jnts_lA = time_jnts_lA-time0;
time_rel_reactCtrl = time_reactCtrl - time0;

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
posEB = [];
for i=1:id_max_jnt
    [T_Ro0_l, T_0n_l, J_l, G_sL8_l, G_sL10_l] = WaistLeftArmFwdKin(wtheta(i,:),latheta(i,:), 0);  % last 0 --> no display
    posEE = [posEE; T_0n_l(1:3,4)'];
    posEB = [posEB; G_sL8_l(1:3,4)'];
end

time_rel_jnt = time_rel_jnts_lA(1:id_max_jnt);

figure; plot3(posEE(:,1),posEE(:,2),posEE(:,3)); 
title('Evolution of EE over time','FontSize',14); grid on;
xlabel('x(m)','FontSize',FontSZ);
ylabel('y(m)','FontSize',FontSZ);
zlabel('z(m)','FontSize',FontSZ);

%% Find distance between visual events and average locus
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

%% Find distance between visual events and left arm
% End-effector
dist_head_EE=[];
dist_hR_EE=[];
dist_hL_EE=[];
for i=1:length(time_rel_reactCtrl)
    idx = max(find(time_rel_kp<=time_rel_reactCtrl(i)));
    if (~isempty(idx))
        dist_head_EE_cur = find_dist_kpEv_C(idx,head,i,EE_t);
        dist_head_EE = [dist_head_EE;dist_head_EE_cur];
        
        dist_hR_EE_cur = find_dist_kpEv_C(idx,hR,i,EE_t);
        dist_hR_EE = [dist_hR_EE;dist_hR_EE_cur];

        dist_hL_EE_cur = find_dist_kpEv_C(idx,hL,i,EE_t);
        dist_hL_EE = [dist_hL_EE;dist_hL_EE_cur];
    else
        dist_head_EE = [dist_head_EE;1000];
        dist_hR_EE = [dist_hR_EE;1000];
        dist_hL_EE = [dist_hL_EE;1000];
    end
end

% Elbow
dist_head_EB=[];
dist_hR_EB=[];
dist_hL_EB=[];
% for i=1:length(time_rel_reactCtrl)
%     idx = max(find(time_rel_kp<=time_rel_reactCtrl(i)));
%     if (~isempty(idx))
%         dist_head_EB_cur = find_dist_kpEv_C(idx,head,i,EB_t);
%         dist_head_EB = [dist_head_EB;dist_head_EB_cur];
%         
%         dist_hR_EB_cur = find_dist_kpEv_C(idx,hR,i,EB_t);
%         dist_hR_EB = [dist_hR_EB;dist_hR_EB_cur];
% 
%         dist_hL_EB_cur = find_dist_kpEv_C(idx,hL,i,EB_t);
%         dist_hL_EB = [dist_hL_EB;dist_hL_EB_cur];
%     else
%         dist_head_EB = [dist_head_EB;1000];
%         dist_hR_EB = [dist_hR_EB;1000];
%         dist_hL_EB = [dist_hL_EB;1000];
%     end
% end
for i=1:length(time_rel_jnt)
    idx = max(find(time_rel_kp<=time_rel_jnt(i)));
    if (~isempty(idx))
        dist_head_EB_cur = find_dist_kpEv_C(idx,head,i,posEB);
        dist_head_EB = [dist_head_EB;dist_head_EB_cur];
        
        dist_hR_EB_cur = find_dist_kpEv_C(idx,hR,i,posEB);
        dist_hR_EB = [dist_hR_EB;dist_hR_EB_cur];

        dist_hL_EB_cur = find_dist_kpEv_C(idx,hL,i,posEB);
        dist_hL_EB = [dist_hL_EB;dist_hL_EB_cur];
    else
        dist_head_EB = [dist_head_EB;1000];
        dist_hR_EB = [dist_hR_EB;1000];
        dist_hL_EB = [dist_hL_EB;1000];
    end
end

%% Plot
% Activation over time
plot_activation(time_rel_pps, part1(:,idx_ppsEv_on_skin_act),'left hand');
plot_activation(time_rel_pps, part2(:,idx_ppsEv_on_skin_act),'left forearm');
plot_activation(time_rel_pps, part4(:,idx_ppsEv_on_skin_act),'right hand');
plot_activation(time_rel_pps, part5(:,idx_ppsEv_on_skin_act),'right forearm');

% Distance of control points in an arm (hand, wrist, mid-arm, elbow) over time
plot_distance(time_rel_reactCtrl, dist_head_EE, 'head','EE');
plot_distance(time_rel_reactCtrl, dist_hR_EE, 'right hand','EE');
plot_distance(time_rel_reactCtrl, dist_hL_EE, 'left hand','EE');

% plot_distance(time_rel_reactCtrl, dist_head_EB, 'head','EB');
% plot_distance(time_rel_reactCtrl, dist_hR_EB, 'right hand','EB');
% plot_distance(time_rel_reactCtrl, dist_hL_EB, 'left hand','EB');

plot_distance(time_rel_jnt, dist_head_EB, 'head','EB');
plot_distance(time_rel_jnt, dist_hR_EB, 'right hand','EB');
plot_distance(time_rel_jnt, dist_hL_EB, 'left hand','EB');

% Distance & activation
figure;
    subplot(4,1,1); plot(time_rel_reactCtrl, dist_hL_EE); 
    ylabel({'DISTANCE (m)'; 'l\_hand(H) & EE(R)'},'FontSize',FontSZ);
    yticks(0:0.1:0.7); ylim([0 0.7]); grid on
    title('HUMAN LEFT HAND (H) VS. ROBOT LEFT ARM (R)','FontSize',FontSZ);
    subplot(4,1,2); plot(time_rel_jnt, dist_hL_EB); 
    ylabel({'DISTANCE (m)'; 'l\_hand(H) & EB(R)'},'FontSize',FontSZ);
    yticks(0:0.1:0.7); ylim([0 0.7]); grid on
    subplot(4,1,3); plot(time_rel_pps, part1(:,idx_ppsEv_on_skin_act),'*'); 
    ylabel({'ACTIVATION ON';'l\_hand(R)'},'FontSize',FontSZ);
    ylim([0.0 1.0]); grid on
    subplot(4,1,4); plot(time_rel_pps, part2(:,idx_ppsEv_on_skin_act),'*'); 
    ylabel({'ACTIVATION ON';'l\_forearm(R)'},'FontSize',FontSZ);
    ylim([0.0 1.0]); grid on
    xlabel('Time(s)','FontSize',FontSZ)

% Joints' limits
figure;
for j=7:chainActiveDOF
    subplot(4,1,j-6); hold on;
    plot(time_rel_reactCtrl,d(:,joint_info(j).vel_limit_min_avoid_column),'--c','Marker','v','MarkerSize',2); % current min joint vel limit set by avoidance handler
    plot(time_rel_reactCtrl,d(:,joint_info(j).vel_limit_max_avoid_column),'--m','Marker','^','MarkerSize',2); % current max joint vel limit set by avoidance handler
    plot([time_rel_reactCtrl(1) time_rel_reactCtrl(end)],[joint_info(j).vel_limit_min joint_info(j).vel_limit_min],'-.r'); % min joint vel limit
    plot([time_rel_reactCtrl(1) time_rel_reactCtrl(end)],[joint_info(j).vel_limit_max joint_info(j).vel_limit_max],'-.r'); % max joint vel limit   
    plot(time_rel_reactCtrl,d(:,joint_info(j).vel_column),'-k'); % current joint velocity
    ylim([(joint_info(j).vel_limit_min - 1) (joint_info(j).vel_limit_max + 1) ]);
    xlabel('t [s]');
    ylabel('joint velocity [deg/s]');
    title(joint_info(j).name);
    hold off;
end 

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
figure; plot3(hR(moment,1), hR(moment,2), hR(moment,3), '*--r', 'LineWidth',2); 
grid on; title('Position of right hand');

