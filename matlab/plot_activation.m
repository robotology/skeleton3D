function plot_activation( time, y, skinPart_name, varargin )
%PLOT_ACTIVATION Plot activation of each skinPart over time
%   PLOT_ACTIVATION(TIME, Y, SKINPART_NAME)
%   Detailed explanation goes here
%   time: time variable
%   y: activation of a skinPart
%   skinPart_name: name of keypoint
if (~isempty(varargin))
    if (length(varargin)>=1)
        fig = varargin{1};        
    end
else
    fig = figure;
end
figure(fig);
titlename = strcat('Activation of: ',skinPart_name);
keep = find(y~=-1000);
plot(time(keep), y(keep), '*'); 
xlabel('time(s)','FontSize',14); 
ylabel('ACTIVATION', 'FontSize',14); 
grid on; 
title(titlename, 'FontSize',14); 

end

