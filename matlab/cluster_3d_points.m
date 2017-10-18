function [ idx0, idx1] = cluster_3d_points( in_vector, dist )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
x0 = in_vector(1,:);
idx0 = 1;
idx1 = [];
for i=2:length(in_vector)
    if(norm(x0-in_vector(i,:))<=dist)
        idx0 = [idx0;i];
    else
        idx1 = [idx1;i];
    end
end
% output = [idx0, idx1];

end

