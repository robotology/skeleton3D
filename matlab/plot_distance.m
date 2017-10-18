function plot_distance( time, y, bodypart_name, ctrPt_name )
%PLOT_DISTANCE Plot activation of each skinPart over time
%   PLOT_DISTANCE(TIME, Y, SKINPART_NAME)
%   Detailed explanation goes here
%   time: time variable
%   y: activation of a skinPart
%   bodypart_name: name of keypoint
%   ctrlPt_name: name of control point in an arm
figure;
titlename = strcat('Distance between: ',bodypart_name,' and ',ctrPt_name);
% keep = find(y~=-1000);
% plot(time(keep), y(keep), '*');
plot(time, y);
xlabel('time(s)','FontSize',14); 
ylabel('DISTANCE(m)', 'FontSize',14); 
ylim([0 0.7]);
grid on; 
title(titlename, 'FontSize',14); 

end

