function dist_cur = find_dist_kpEv_C( time_kp, kpEv, time_reactCtr, controlPt)
%FIND_DIST_KPEV_C Find the distance between the keypoint position
%and control point positions
%   time_kp: index of keypoint corresonding to the projected pps event on
%   skin part
%   kpEv: position of keypoint
%   time_reactCtr: index of pps event
%   controlPt: control point position, e.g. EE, Elbow
idx_kp_pos = 1:3;
dist_cur = norm(kpEv(time_kp,idx_kp_pos)-controlPt(time_reactCtr,1:3));

end

