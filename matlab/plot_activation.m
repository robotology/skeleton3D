function plot_activation( time, y, skinPart_name )
%PLOT_ACTIVATION Plot activation of each skinPart over time
%   PLOT_ACTIVATION(TIME, Y, SKINPART_NAME)
%   Detailed explanation goes here
%   time: time variable
%   y: activation of a skinPart
%   skinPart_name: name of keypoint
figure;
titlename = strcat('Activation of: ',skinPart_name);
keep = find(y~=-1000);
plot(time(keep), y(keep), '*'); 
xlabel('time(s)','FontSize',14); 
ylabel('x(m)', 'FontSize',14); 
grid on; 
title(titlename, 'FontSize',14); 

end

