clc;
clear all;
close all;

%% Plot flags & Init
PLOT_KEYPOINT_EVOLUTION = 0;
PLOT_DISTANCE_SEPARATE = 0;
PLOT_ACTIVATION_SEPARATE = 0;
PLOT_DIST_EE = 0;

EXPORT_TO_FILES = 1;
results_path = './results';

idx_ppsEv_on_skin_act = 8;
FontSZ = 16;
LineSZ = 2;

tmin = 110.0;
tmax = 150.0;

% path = 'data_1535/';    % reach a point
% path = 'data_1725/';    % reach a point with changing valence
% path = 'data_1740/';    % follow a circle with changing valence
% path = 'data_1120/';    % follow a circle with changing valence stiff on

% New format data
path = 'data_1425/';    % reach a point with changing valence stiff on elbow from reactCtrl     40-110
path = 'data_1430/';    % follow a circle with changing valence stiff on elbow from reactCtrl 10-130    65-100
path = 'data_1625/';    % reach a point with different valences for hand and head stiff on elbow from reactCtrl 160-240
%path = 'data_1650/';    % reach a point with changing valence stiff on elbow from reactCtrl 26/09/2017 10-110 200-240 21-75
path = 'data_1655/';    % follow a circle with changing valence stiff on elbow from reactCtrl 26/09/2017 110-150
% path = 'data_1755/';    % follow a circle with changing valence stiff on elbow from reactCtrl 26/09/2017 90-170

%% Keypoints
filename_keypoints = 'keypoints/data.log';
filename = strcat(path,filename_keypoints);
[time_kp,head, hR, hL, eR, eL, sR, sL, sp] = importfile_keypoints(filename);
time0_kp = time_kp(1);

hL_valence05m = find(hL(:,5)==-0.5);
hL_valence0 = find(hL(:,5)==0);
hL_valence1 = find(hL(:,5)==1);


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

EB_t  = d(:,elbow_x.column:elbow_z.column); % with modified reactCtrl dummping from 1400 19/09/2017

%% Convert time variables to the same reference
time0 = min([time0_kp,time0_pps, time0_jnts_torso, time0_jnts_lA, time0_reactCtrl]);
time_rel_kp = time_kp-time0;
time_rel_pps = time_pps-time0;
time_rel_jnts_torso = time_jnts_torso-time0;
time_rel_jnts_lA = time_jnts_lA-time0;
time_rel_reactCtrl = time_reactCtrl - time0;

time_rel_kp_valence_0 = [time_rel_kp(min(hL_valence0)) time_rel_kp(max(hL_valence0))];
time_rel_kp_valence_1 = [time_rel_kp(min(hL_valence1)) time_rel_kp(max(hL_valence1))];

% time_rel_pps_valence_0 = [min(find(time_rel_pps>=time_rel_kp_valence_0(1))) max(find(time_rel_pps<=time_rel_kp_valence_0(2)))];
% time_rel_pps_valence_1 = [min(find(time_rel_pps>=time_rel_kp_valence_1(1))) max(find(time_rel_pps<=time_rel_kp_valence_1(2)))];

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
    posEE = [posEE; G_sL10_l(1:3,4)'];
    posEB = [posEB; G_sL8_l(1:3,4)'];
end
len_forearm = posEE-posEB;
time_rel_jnt = time_rel_jnts_lA(1:id_max_jnt);



%% Find distance between visual events and average locus
dist_head=[];
dist_hR=[];
dist_hL=[];
dist_head_l_locus=[];
dist_hR_l_locus=[];
dist_hL_l_locus=[];
dist_l_locus = [];
for i=1:length(time_rel_pps)
    idx = max(find(time_rel_kp<=time_rel_pps(i)));
    if (~isempty(idx))
        dist_head_cur = find_dist_kpEv_skin_part(idx,head,i,part1,part2,part4,part5);
        dist_head = [dist_head;min(dist_head_cur)];
        dist_head_l_locus = [dist_head_l_locus;dist_head_cur(1:2)]; %part1 -l_hand, part2 - l_forearm
        
        dist_hR_cur = find_dist_kpEv_skin_part(idx,hR,i,part1,part2,part4,part5);
        dist_hR = [dist_hR;min(dist_hR_cur)];
        dist_hR_l_locus = [dist_hR_l_locus;dist_hR_cur(1:2)];

        dist_hL_cur = find_dist_kpEv_skin_part(idx,hL,i,part1,part2,part4,part5);
        dist_hL = [dist_hL;min(dist_hL_cur)];
        dist_hL_l_locus = [dist_hL_l_locus;dist_hL_cur(1:2)];
    else
        dist_head = [dist_head;1000];
        dist_hR = [dist_hR;1000];
        dist_hL = [dist_hL;1000];
        dist_head_l_locus = [dist_head_l_locus;1000,1000];
        dist_hR_l_locus = [dist_hR_l_locus;1000,1000];
        dist_hL_l_locus = [dist_hL_l_locus;1000,1000];
    end
    dist_l_locus = [dist_l_locus;   min([dist_head_l_locus(i,1),dist_hR_l_locus(i,1),dist_hL_l_locus(i,1)]),...
                                    min([dist_head_l_locus(i,2),dist_hR_l_locus(i,2),dist_hL_l_locus(i,2)])];
end
idx
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
for i=1:length(time_rel_reactCtrl)
    idx = max(find(time_rel_kp<=time_rel_reactCtrl(i)));
    if (~isempty(idx))
        dist_head_EB_cur = find_dist_kpEv_C(idx,head,i,EB_t);
        dist_head_EB = [dist_head_EB;dist_head_EB_cur];
        
        dist_hR_EB_cur = find_dist_kpEv_C(idx,hR,i,EB_t);
        dist_hR_EB = [dist_hR_EB;dist_hR_EB_cur];

        dist_hL_EB_cur = find_dist_kpEv_C(idx,hL,i,EB_t);
        dist_hL_EB = [dist_hL_EB;dist_hL_EB_cur];
    else
        dist_head_EB = [dist_head_EB;1000];
        dist_hR_EB = [dist_hR_EB;1000];
        dist_hL_EB = [dist_hL_EB;1000];
    end
end
% for i=1:length(time_rel_jnt)
%     idx = max(find(time_rel_kp<=time_rel_jnt(i)));
%     if (~isempty(idx))
%         dist_head_EB_cur = find_dist_kpEv_C(idx,head,i,posEB);
%         dist_head_EB = [dist_head_EB;dist_head_EB_cur];
%         
%         dist_hR_EB_cur = find_dist_kpEv_C(idx,hR,i,posEB);
%         dist_hR_EB = [dist_hR_EB;dist_hR_EB_cur];
% 
%         dist_hL_EB_cur = find_dist_kpEv_C(idx,hL,i,posEB);
%         dist_hL_EB = [dist_hL_EB;dist_hL_EB_cur];
%     else
%         dist_head_EB = [dist_head_EB;1000];
%         dist_hR_EB = [dist_hR_EB;1000];
%         dist_hL_EB = [dist_hL_EB;1000];
%     end
% end

%% Plot

figure; 
% plot3(EE_t(:,1),EE_t(:,2),EE_t(:,3),'b', posEB(:,1),posEB(:,2),posEB(:,3),'r', hL(:,1), hL(:,2), hL(:,3), '*--'); 
plot3(EE_t(:,1),EE_t(:,2),EE_t(:,3),'b', EB_t(:,1),EB_t(:,2),EB_t(:,3),'r', hL(:,1), hL(:,2), hL(:,3), '*--'); % with modified reactCtrl dumping from 1400 19/09/2017
title('Evolution of EE and EB over time','FontSize',FontSZ); grid on;
xlabel('x(m)','FontSize',FontSZ);
ylabel('y(m)','FontSize',FontSZ);
zlabel('z(m)','FontSize',FontSZ);

%% Activation over time
if PLOT_ACTIVATION_SEPARATE
    plot_activation(time_rel_pps, part1(:,idx_ppsEv_on_skin_act),'left hand');
    plot_activation(time_rel_pps, part2(:,idx_ppsEv_on_skin_act),'left forearm');
    plot_activation(time_rel_pps, part4(:,idx_ppsEv_on_skin_act),'right hand');
    plot_activation(time_rel_pps, part5(:,idx_ppsEv_on_skin_act),'right forearm');
end

%% Distance of control points in an arm (hand, wrist, mid-arm, elbow) over time
if PLOT_DISTANCE_SEPARATE
    plot_distance(time_rel_reactCtrl, dist_head_EE, 'head','EE');
    plot_distance(time_rel_reactCtrl, dist_hR_EE, 'right hand','EE');
    plot_distance(time_rel_reactCtrl, dist_hL_EE, 'left hand','EE');

    % plot_distance(time_rel_reactCtrl, dist_head_EB, 'head','EB');
    % plot_distance(time_rel_reactCtrl, dist_hR_EB, 'right hand','EB');
    % plot_distance(time_rel_reactCtrl, dist_hL_EB, 'left hand','EB');

    plot_distance(time_rel_jnt, dist_head_EB, 'head','EB');
    plot_distance(time_rel_jnt, dist_hR_EB, 'right hand','EB');
    plot_distance(time_rel_jnt, dist_hL_EB, 'left hand','EB');
end

%% Distance & activation
pps_time = time_rel_pps(1):time_rel_pps(end);
pps_thres = 0.2*ones(length(pps_time));

fig_dist_act = figure('units','normalized','outerposition',[0 0 0.5 1]);    % half left of the screen
    dur = find_idx_in_duration(time_rel_pps, tmin, tmax);
    subplot(4,1,2); hold on
%         rectangle('Position',[time_rel_kp_valence_1(1) 0 time_rel_kp_valence_1(2)-time_rel_kp_valence_1(1) 0.7], 'FaceColor','yellow')
%         plot(time_rel_kp_valence_1(2)*[1, 1], [0, 0.7],'y','LineWidth',3) 
        plot(time_rel_reactCtrl, dist_hL_EE, time_rel_reactCtrl, dist_hR_EE, time_rel_reactCtrl, dist_head_EE, 'LineWidth',LineSZ);
        plot(time_rel_pps, dist_l_locus(:,1),'.');
        ylabel({'distance (m)'; 'to EE(R)'},'FontSize',FontSZ);   yticks(0:0.1:0.7); 
%         legend('left hand(H)', 'right hand(H)', 'head(H)', 'location','best');
        xlim([tmin tmax]); ylim([0 0.7]); grid on
        
        xt = get(gca, 'XTick');    set(gca, 'FontSize', FontSZ);
        yt = get(gca, 'YTick');    set(gca, 'FontSize', FontSZ);
        hold off
        
    subplot(4,1,1); hold on
%         plot(time_rel_jnt, dist_hL_EB, time_rel_jnt, dist_hR_EB, time_rel_jnt, dist_head_EB, 'LineWidth',LineSZ);
%         plot([time_rel_kp_valence_1(1),time_rel_kp_valence_1(1),time_rel_kp_valence_1(2),time_rel_kp_valence_1(2)], [0,0.7,0,0.7],'LineWidth',3,'y') 
        plot(time_rel_reactCtrl, dist_hL_EB, time_rel_reactCtrl, dist_hR_EB, time_rel_reactCtrl, dist_head_EB, 'LineWidth',LineSZ);
        plot(time_rel_pps, dist_l_locus(:,2),'.');
        ylabel({'distance (m)'; 'to EB(R)'},'FontSize',FontSZ);   yticks(0:0.1:0.7); 
        xlim([tmin tmax]); ylim([0 0.7]); grid on
        title('HUMAN PARTS (H) VS. ROBOT LEFT ARM (R)','FontSize',FontSZ);
        xt = get(gca, 'XTick');    set(gca, 'FontSize', FontSZ);
        yt = get(gca, 'YTick');    set(gca, 'FontSize', FontSZ);
        hold off
        
    subplot(4,1,4); 
%         plot(time_rel_pps, part1(:,idx_ppsEv_on_skin_act),'*'); 
        area(time_rel_pps, part1(:,idx_ppsEv_on_skin_act),'EdgeColor','b','FaceColor','c','FaceAlpha',0.5); 
        ylabel({'activation';'on l\_hand(R)'},'FontSize',FontSZ);              yticks(0:0.2:1);
        xlim([tmin tmax]); ylim([0.0 1.0]); grid on
        xlabel('time (s)','FontSize',FontSZ)
        xt = get(gca, 'XTick');    set(gca, 'FontSize', FontSZ);
        yt = get(gca, 'YTick');    set(gca, 'FontSize', FontSZ);
        
    subplot(4,1,3); 
%         plot(time_rel_pps, part2(:,idx_ppsEv_on_skin_act),'*'); 
        area(time_rel_pps, part2(:,idx_ppsEv_on_skin_act),'EdgeColor','b','FaceColor','c','FaceAlpha',0.5); 
        ylabel({'activation';'on l\_forearm(R)'},'FontSize',FontSZ);           yticks(0:0.2:1);  
        xlim([tmin tmax]); ylim([0.0 1.0]); grid on
        xt = get(gca, 'XTick');    set(gca, 'FontSize', FontSZ);
        yt = get(gca, 'YTick');    set(gca, 'FontSize', FontSZ);
% set(gcf, 'Position', get(0, 'Screensize'));


% Distance to locus & activation
% fig_dist_act_locus = figure('units','normalized','outerposition',[0 0 1 1]);
%     dur = find_idx_in_duration(time_rel_reactCtrl, tmin, tmax);
%         
%     subplot(3,1,1); 
%         plot(time_rel_pps, dist_hL, time_rel_pps, dist_hR, time_rel_pps, dist_head, 'LineWidth',LineSZ);
%         ylabel({'distance (m)'; 'to locus'},'FontSize',FontSZ);   yticks(0:0.1:0.7); 
%         xlim([tmin tmax]); ylim([0 0.7]); grid on
%         title('HUMAN PARTS (H) VS. ROBOT LEFT ARM (R)','FontSize',FontSZ);
%         xt = get(gca, 'XTick');    set(gca, 'FontSize', FontSZ);
%         yt = get(gca, 'YTick');    set(gca, 'FontSize', FontSZ);
%    
%         
%     subplot(3,1,3); 
%         plot(time_rel_pps, part1(:,idx_ppsEv_on_skin_act),'*'); ylabel({'activation';'on l\_hand(R)'},'FontSize',FontSZ);              yticks(0:0.2:1);
%         xlim([tmin tmax]); ylim([0.0 1.0]); grid on
%         xlabel('time (s)','FontSize',FontSZ)
%         xt = get(gca, 'XTick');    set(gca, 'FontSize', FontSZ);
%         yt = get(gca, 'YTick');    set(gca, 'FontSize', FontSZ);
%         
%     subplot(3,1,2); 
%         plot(time_rel_pps, part2(:,idx_ppsEv_on_skin_act),'*'); ylabel({'activation';'on l\_forearm(R)'},'FontSize',FontSZ);           yticks(0:0.2:1);  
%         xlim([tmin tmax]); ylim([0.0 1.0]); grid on
%         xt = get(gca, 'XTick');    set(gca, 'FontSize', FontSZ);
%         yt = get(gca, 'YTick');    set(gca, 'FontSize', FontSZ);


%% Joints' limits
fig_jnt_lim = figure('units','normalized','outerposition',[0.5 0 0.5 1]);
for j=7:chainActiveDOF
    subplot(4,1,j-6); 
    hold on;
    plot(time_rel_reactCtrl,d(:,joint_info(j).vel_limit_min_avoid_column),'--b','Marker','v','MarkerSize',2); % current min joint vel limit set by avoidance handler
    plot(time_rel_reactCtrl,d(:,joint_info(j).vel_limit_max_avoid_column),'--m','Marker','^','MarkerSize',2); % current max joint vel limit set by avoidance handler
    plot(time_rel_reactCtrl,d(:,joint_info(j).vel_column),'-k'); % current joint velocity
    
    plot([time_rel_reactCtrl(1) time_rel_reactCtrl(end)],[joint_info(j).vel_limit_min joint_info(j).vel_limit_min],'-.c'); % min joint vel limit
    plot([time_rel_reactCtrl(1) time_rel_reactCtrl(end)],[joint_info(j).vel_limit_max joint_info(j).vel_limit_max],'-.r'); % max joint vel limit   
    
    xlim([tmin tmax]); ylim([(joint_info(j).vel_limit_min - 1) (joint_info(j).vel_limit_max + 1) ]);
    if j == chainActiveDOF
        xlabel('time (s)','FontSize',FontSZ);
    end
    ylabel('joint vel(deg/s)','FontSize',FontSZ);
    
    title(joint_info(j).name,'FontSize',FontSZ);
    hold off;
    xt = get(gca, 'XTick');    set(gca, 'FontSize', FontSZ);
    yt = get(gca, 'YTick');    set(gca, 'FontSize', FontSZ);
end 
% legend('joint vel limit - min', 'joint vel limit - max', 'joint vel', 'location','best');
% set(gcf, 'Position', get(0, 'Screensize'));

%% End-effector pose & desired

f11 = figure('units','normalized','outerposition',[0 0 0.5 1]); clf(f11); %set(f11,'Color','white','Name','Target, reference, end-effector in time and space');  
    subplot(3,1,1);
        hold on;
        title('Reference and EE over time');
%             plot(time_rel_reactCtrl,d(:,target_x.column),'r*','MarkerSize',5);      % desired
            plot(time_rel_reactCtrl,d(:,targetEE_x.column),'go','MarkerSize',3);    % generated reference
            plot(time_rel_reactCtrl,d(:,EE_x.column),'k.','MarkerSize',4);          % current
            
%             plot(time_rel_kp,hL(:,1),'.','MarkerSize',2);
            ylabel('x(m)', 'FontSize',FontSZ);
        hold off;
        xlim([tmin tmax]); 
%         ylim([min(d(:,EE_x.column))-0.1, max(d(:,EE_x.column))+0.1])
        xt = get(gca, 'XTick');    set(gca, 'FontSize', FontSZ);
        yt = get(gca, 'YTick');    set(gca, 'FontSize', FontSZ);

    subplot(3,1,2);
        hold on;
%             plot(time_rel_reactCtrl,d(:,target_y.column),'r*','MarkerSize',5);
            plot(time_rel_reactCtrl,d(:,targetEE_y.column),'go','MarkerSize',3);
            plot(time_rel_reactCtrl,d(:,EE_y.column),'k.','MarkerSize',4);
            
%             plot(time_rel_kp,hL(:,2),'.','MarkerSize',2);
            ylabel('y(m)', 'FontSize',FontSZ);
        hold off;  
        xlim([tmin tmax]); 
%         ylim([min(d(:,EE_y.column))-0.1, max(d(:,EE_y.column))+0.1])
        xt = get(gca, 'XTick');    set(gca, 'FontSize', FontSZ);
        yt = get(gca, 'YTick');    set(gca, 'FontSize', FontSZ);

    subplot(3,1,3);
        hold on;
%             plot(time_rel_reactCtrl,d(:,target_z.column),'r*','MarkerSize',5);
            plot(time_rel_reactCtrl,d(:,targetEE_z.column),'go','MarkerSize',3);
            plot(time_rel_reactCtrl,d(:,EE_z.column),'k.','MarkerSize',4);
            
%             plot(time_rel_kp,hL(:,3),'.','MarkerSize',2);
            ylabel('z(m)', 'FontSize',FontSZ);
            xlabel('time(s)', 'FontSize',FontSZ);
        hold off;
        xlim([tmin tmax]); 
%         ylim([min(d(:,EE_z.column))-0.05, max(d(:,EE_z.column))+0.05])
        xt = get(gca, 'XTick');    set(gca, 'FontSize', FontSZ);
        yt = get(gca, 'YTick');    set(gca, 'FontSize', FontSZ);

dist = [];
for i = 1:length(time_rel_reactCtrl)
    dist = [dist; norm(d(i,targetEE_x.column:targetEE_z.column)-d(i,EE_x.column:EE_z.column))];
end

if PLOT_DIST_EE
    fig_dist_EE = figure('units','normalized','outerposition',[0.5 0 0.5 1]);
    plot(time_rel_reactCtrl,dist,'go','MarkerSize',3);
    title('Error between Reference and EE over time');
    xlim([tmin tmax]); xlabel('time(s)', 'FontSize',FontSZ);
    xt = get(gca, 'XTick');    set(gca, 'FontSize', FontSZ);
    yt = get(gca, 'YTick');    set(gca, 'FontSize', FontSZ);
end
        
%% Keypoint evolution
if PLOT_KEYPOINT_EVOLUTION
    keep = find(time_rel_kp>11.0 & time_rel_kp<42.0);
    keep = find(time_rel_kp>0.0);

    plot_keypoint(time_rel_kp(keep), head(keep,:), 'head', tmin, tmax);
    plot_keypoint(time_rel_kp(keep), hR(keep,:), 'hand right', tmin, tmax);
    plot_keypoint(time_rel_kp(keep), hL(keep,:), 'hand left', tmin, tmax);
    plot_keypoint(time_rel_kp(keep), eR(keep,:), 'elbow right', tmin, tmax);
    plot_keypoint(time_rel_kp(keep), eL(keep,:), 'elbow left', tmin, tmax);
    plot_keypoint(time_rel_kp(keep), sR(keep,:), 'shoulder right', tmin, tmax);
    plot_keypoint(time_rel_kp(keep), sL(keep,:), 'shoulder left', tmin, tmax);
end

moment = find(time_rel_kp>=19.0 & time_rel_kp>=21.0);
figure; plot3(hL(moment,1), hL(moment,2), hL(moment,3), '*--r', 'LineWidth',2); 
grid on; title('Position of left hand');
xlabel('x(m)', 'FontSize',FontSZ);
ylabel('y(m)', 'FontSize',FontSZ);
zlabel('z(m)', 'FontSize',FontSZ);

%%
fig_all_in

%% Export

disp('wait 10 second...');
pause(10);

if (EXPORT_TO_FILES)
    has_results = exist(results_path);
    switch has_results
        case 0
            mkdir(results_path);
            cd(results_path);
        case 7
            cd(results_path);
    end
    mkdir(path);
    cd ..
    filename_dist_act = strcat(results_path,'/',path,'/exp_distance_activation_valence_',...
                               num2str(hL(dur(1),5)),'_',num2str(tmin),'_',num2str(tmax),'_cut.eps');
    print(fig_dist_act,'-depsc',filename_dist_act);
    filename_jnt_lim = strcat(results_path,'/',path,'/exp_joint_vel_valence_',...
                              num2str(hL(dur(1),5)),'_',num2str(tmin),'_',num2str(tmax),'_cut.eps');
    print(fig_jnt_lim,'-depsc',filename_jnt_lim);
    filename_target_current = strcat(results_path,'/',path,'/exp_target_current_valence_',...
                              num2str(hL(dur(1),5)),'_',num2str(tmin),'_',num2str(tmax),'_cut.eps');
    print(f11,'-depsc',filename_target_current);
    
    filename_all = strcat(results_path,'/',path,'/exp_all_',...
                          num2str(tmin),'_',num2str(tmax),'_cut.eps');
    print(fig_all_in_once,'-depsc',filename_all);
end
