clc;
clear all;
close all;

%% Plot flags
PLOT_KEYPOINT_EVOLUTION = 0

%% Keypoints
path = 'data_1800/';
filename_keypoints = 'keypoints/data.log';
filename = strcat(path,filename_keypoints);
[time_kp,head, hR, hL, eR, eL, sR, sL, sp] = importfile_keypoints(filename);
time0_kp = time_kp(1);

%% pps
process_ppsEvents

%% Convert time variables to the same reference
time0 = min(time0_kp,time0_pps);
time_rel_kp = time_kp-time0;
time_rel_pps = time_pps-time0;

time_delta_kp = [];
for i=2:length(time_rel_kp)
    delta = time_rel_kp(i)-time_rel_kp(i-1);
    time_delta_kp = [time_delta_kp;delta];
end

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
dist_hL_id_kp = max(find(time_rel_kp<=time_rel_pps(dist_hL_id_pps)));
plot_kp_skinPart_3d(dist_hL_id_kp,hL,'hand left', dist_hL_id_pps,part1,part2,part4,part5);

[dist_hR_min, dist_hR_id_pps] = min(dist_hR);
dist_hR_id_kp = max(find(time_rel_kp<=time_rel_pps(dist_hR_id_pps)));
plot_kp_skinPart_3d(dist_hR_id_kp,hR,'hand left', dist_hR_id_pps,part1,part2,part4,part5);

%% Plot 
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

