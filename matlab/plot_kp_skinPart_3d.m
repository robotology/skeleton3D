function plot_kp_skinPart_3d( time_kp, kpEv, keypoint_name, time_pps, part1, part2, part4, part5 )
%PLOT_KP_SKINPART_3D Plot the keypoint position and skin parts' positions
%   time_kp: index of keypoint corresonding to the projected pps event on
%   skin part
%   kpEv: position of keypoint
%   keypoint_name: name of keypoint
%   time_pps: index of pps event
%   part1, part2, part4, part5: matrixs containing information of projected
%   pps event. See importfile_ppsEvent
idx_ppsEv_on_skin_pos = 2:4;
idx_kp_pos = 1:3;

titlename = strcat('Distance between position of ',keypoint_name,' and skin part');
figure; title(titlename, 'FontSize',14);
hold on
plot3(kpEv(time_kp,idx_kp_pos(1)),kpEv(time_kp,idx_kp_pos(2)),kpEv(time_kp,idx_kp_pos(3)),'*r')

if (part1(time_pps,1)~=-1000)
    plot3(part1(time_pps,idx_ppsEv_on_skin_pos(1)),part1(time_pps,idx_ppsEv_on_skin_pos(2)),part1(time_pps,idx_ppsEv_on_skin_pos(3)),'ob')
    text(part1(time_pps,idx_ppsEv_on_skin_pos(1)),part1(time_pps,idx_ppsEv_on_skin_pos(2)),part1(time_pps,idx_ppsEv_on_skin_pos(3)),...
        '   l-hand','HorizontalAlignment','left','FontSize',8);
end
if (part2(time_pps,1)~=-1000)
    plot3(part2(time_pps,idx_ppsEv_on_skin_pos(1)),part2(time_pps,idx_ppsEv_on_skin_pos(2)),part2(time_pps,idx_ppsEv_on_skin_pos(3)),'ob')
    text(part2(time_pps,idx_ppsEv_on_skin_pos(1)),part2(time_pps,idx_ppsEv_on_skin_pos(2)),part2(time_pps,idx_ppsEv_on_skin_pos(3)),...
        '   l-forearm','HorizontalAlignment','left','FontSize',8);
end
if (part4(time_pps,1)~=-1000)
    plot3(part4(time_pps,idx_ppsEv_on_skin_pos(1)),part4(time_pps,idx_ppsEv_on_skin_pos(2)),part4(time_pps,idx_ppsEv_on_skin_pos(3)),'ob')
    text(part4(time_pps,idx_ppsEv_on_skin_pos(1)),part4(time_pps,idx_ppsEv_on_skin_pos(2)),part4(time_pps,idx_ppsEv_on_skin_pos(3)),...
        '   r-hand','HorizontalAlignment','left','FontSize',8);
end
if (part5(time_pps,1)~=-1000)
    plot3(part5(time_pps,idx_ppsEv_on_skin_pos(1)),part5(time_pps,idx_ppsEv_on_skin_pos(2)),part5(time_pps,idx_ppsEv_on_skin_pos(3)),'ob');
    text(part5(time_pps,idx_ppsEv_on_skin_pos(1)),part5(time_pps,idx_ppsEv_on_skin_pos(2)),part5(time_pps,idx_ppsEv_on_skin_pos(3)),...
        '   r-forearm','HorizontalAlignment','left','FontSize',8);
end
xlabel('x(m)', 'FontSize',14);
ylabel('y(m)', 'FontSize',14);
zlabel('z(m)', 'FontSize',14);
grid on
hold off
    

end

