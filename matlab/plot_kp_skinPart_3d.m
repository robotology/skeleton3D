function plot_kp_skinPart_3d( time_kp, kpEv, keypoint_name, time_pps, part1, part2, part4, part5 )
%PLOT_KP_SKINPART_3D Plot the keypoint position and skin parts' positions
%   time_kp: index of keypoint corresonding to the projected pps event on
%   skin part
%   kpEv: position of keypoint
%   keypoint_name: name of keypoint
%   time_pps: index of pps event
%   part1, part2, part4, part5: matrixs containing information of projected
%   pps event. See importfile_ppsEvent
idx_kp_pos = 1:3;

titlename = strcat('Distance between position of ',keypoint_name,' and skin part');
fig = figure; title(titlename, 'FontSize',14);
hold on
% plot3(kpEv(time_kp,idx_kp_pos(1)),...
%       kpEv(time_kp,idx_kp_pos(2)),...
%       kpEv(time_kp,idx_kp_pos(3)),'*r','LineWidth',10)
drawCube(kpEv(time_kp,idx_kp_pos), 0.035*ones(1,3),'r');

plot_skinPart_3D(time_pps,part1,fig);
plot_skinPart_3D(time_pps,part2,fig);
plot_skinPart_3D(time_pps,part4,fig);
plot_skinPart_3D(time_pps,part5,fig);

xlabel('x(m)', 'FontSize',14);
ylabel('y(m)', 'FontSize',14);
zlabel('z(m)', 'FontSize',14);
grid on
hold off
    

end



