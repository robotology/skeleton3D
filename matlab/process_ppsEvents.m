%% Import ppsEvent file and pure processing time & re-allocate event on "right" skin part
% path = 'data_1030/';
filename_keypoints = 'ppsEvents/data.log';  % <from>/visuoTactileRF/pps_events_aggreg:o</from>
filename = strcat(path,filename_keypoints);
[time_pps,part1,part2,part4,part5] = importfile_ppsEvent(filename);
time0_pps = time_pps(1);
% time_rel = time_pps-time0_pps;

for i=1:length(time_pps)
    if (part1(i,1)==2)
        part2(i,:) = part1(i,:);
        part1(i,:) = -1000;
    elseif (part1(i,1)==4)
        part4(i,:) = part1(i,:);
        part1(i,:) = -1000;
    elseif (part1(i,1)==5)
        part5(i,:) = part1(i,:);
        part1(i,:) = -1000;
    end
    if (part2(i,1)==4)
        part4(i,:) = part2(i,:);
        part2(i,:) = -1000;
    elseif (part2(i,1)==5)
        part5(i,:) = part2(i,:);
        part2(i,:) = -1000;
    end    
    if (part4(i,1)==5)
        part5(i,:) = part4(i,:);
        part4(i,:) = -1000;
    end
end