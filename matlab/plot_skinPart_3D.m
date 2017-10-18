function plot_skinPart_3D(time_pps,part,fig)
%PLOT_SKINPART_3D Plot the keypoint position and skin parts' positions
%   time_pps: index of pps event
%   part1, part2, part4, part5: matrixs containing information of projected
%   pps event. See importfile_ppsEvent

idx_ppsEv_on_skin_pos = 2:4;
idx_ppsEv_on_skin_nom = 5:7;

if (part(time_pps,1)~=-1000)
    switch part(time_pps,1)
        case 1
            partname = '    l-hand';
        case 2
            partname = '    l-forearm';
        case 4
            partname = '    r-hand';
        case 5
            partname = '    r-forearm';
    end
        
    plot3(  part(time_pps,idx_ppsEv_on_skin_pos(1)),...
            part(time_pps,idx_ppsEv_on_skin_pos(2)),...
            part(time_pps,idx_ppsEv_on_skin_pos(3)),'ob')
     text(  part(time_pps,idx_ppsEv_on_skin_pos(1)),...
            part(time_pps,idx_ppsEv_on_skin_pos(2)),...
            part(time_pps,idx_ppsEv_on_skin_pos(3)),...
            partname,'HorizontalAlignment','left','FontSize',10);
    plot_RF(part(time_pps,idx_ppsEv_on_skin_pos), part(time_pps,idx_ppsEv_on_skin_nom), fig);
end
end

