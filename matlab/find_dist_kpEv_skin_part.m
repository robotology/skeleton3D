function dist_cur = find_dist_kpEv_skin_part( time_kp, kpEv, time_pps, part1, part2, part4, part5)
%FIND_DIST_KPEV_SKIN_PART Find the distance between the keypoint position
%and skin parts' positions
%   time_kp: index of keypoint corresonding to the projected pps event on
%   skin part
%   kpEv: position of keypoint
%   time_pps: index of pps event
%   part1, part2, part4, part5: matrixs containing information of projected
%   pps event. See importfile_ppsEvent
idx_ppsEv_on_skin_pos = 2:4;
idx_kp_pos = 1:3;
dist_cur = [norm(kpEv(time_kp,idx_kp_pos)-part1(time_pps,idx_ppsEv_on_skin_pos)),...
            norm(kpEv(time_kp,idx_kp_pos)-part2(time_pps,idx_ppsEv_on_skin_pos)),...
            norm(kpEv(time_kp,idx_kp_pos)-part4(time_pps,idx_ppsEv_on_skin_pos)),...
            norm(kpEv(time_kp,idx_kp_pos)-part5(time_pps,idx_ppsEv_on_skin_pos))];

end

