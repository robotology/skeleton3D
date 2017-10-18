function plot_keypoint( time, y, keypoint_name, tmin, tmax )
%PLOT_KEYPOINT Plot evolution of each keypoint over time
%   PLOT_KEYPOINT(TIME, Y, KEYPOINT_NAME)
%   Detailed explanation goes here
%   time: time variable
%   y: position of keypoint CoM
%   keypoint_name: name of keypoint
figure;
titlename = strcat('Evolution of: ',keypoint_name);

subplot(3,1,1); plot(time, y(:,1)); ylabel('x(m)', 'FontSize',14); grid on; title(titlename, 'FontSize',14); xlim([tmin tmax]);
subplot(3,1,2); plot(time, y(:,2)); ylabel('y(m)', 'FontSize',14); grid on; xlim([tmin tmax]);
subplot(3,1,3); plot(time, y(:,3)); xlabel('time(s)', 'FontSize',14); ylabel('z(m)', 'FontSize',14); grid on; xlim([tmin tmax]);

end

