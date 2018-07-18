filename_keypoints = 'skinEvAggreg/data.log';  % <from>/visuoTactileRF/pps_events_aggreg:o</from>
filename = strcat(path,filename_keypoints)
[time_skin,skin_Ev1, skin_Ev2, skin_Ev4, skin_Ev5, skin_part, skin_taxel] = importfile_skinEvAggreg(filename);
time0_skin = time_skin(1);
