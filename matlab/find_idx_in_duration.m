function duration = find_idx_in_duration( t, tmin, tmax )
%FIND_IDX_IN_DURATION Find all member of time array in [tmin tmax]
%   Detailed explanation goes here
duration = find(t>=tmin & t<=tmax);

end

