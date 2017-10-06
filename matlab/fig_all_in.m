plot_2_joint = 2;
plot_dist_thres = 0;
plot_dist_mod_thres = 1;
plot_dist_inc_thres = 0;
FontSZ = 12;

h_new_sp = 0.02;
% no_pps1 = find(part1 == -1000);
% part1(no_pps1)=0;
% no_pps2 = find(part2 == -1000);
% part1(no_pps2)=0;

if plot_2_joint==1      % plot 2 joints
    nb_subplot = 5;
    nb_jnts_plot = 2;
%     jnts_plot = 8:2:chainActiveDOF;
    jnts_plot = chainActiveDOF:-2:8;
    out_pos = [0 0 15 21.5];
elseif plot_2_joint==0  % plot 4 joints
    nb_subplot = 7;
    nb_jnts_plot = 4;
%     jnts_plot = 7:chainActiveDOF;
    jnts_plot = chainActiveDOF:-1:7;
    out_pos = [0 0 15 30];
elseif plot_2_joint==2  % plot 7 joints, including 3 stupid shoulders
    nb_subplot = 10;
    nb_jnts_plot = 7;
    jnts_plot = chainActiveDOF:-1:4;
    out_pos = [0 0 12 30];
    FontSZ = 8;
end

% fig_all_in_once = figure('units','normalized','outerposition',[0 0 0.5 1]);
fig_all_in_once = figure('units','centimeters','outerposition',out_pos);

    sp_handle1 = subplot(nb_subplot,1,1); hold on
        plot(time_rel_reactCtrl, dist_hL_EE, time_rel_reactCtrl, dist_head_EE, 'LineWidth',LineSZ);
        plot(time_rel_pps, dist_l_locus(:,1),'m.');
        
        area(time_rel_pps, part1(:,idx_ppsEv_on_skin_act),'EdgeColor','c','FaceColor','c','FaceAlpha',0.2);
%         plot(pps_time,pps_thres,'--c');
        if plot_dist_thres
            plot(pps_time,dist_thres,'--g');
        end
        if plot_dist_mod_thres
            plot(pps_time,dist_mod_thres,'--b');
        end
        if plot_dist_inc_thres
            plot(pps_time,dist_inc_thres,'--','color',[1 0.5 0]);
        end
          
        ylabel({'distance to', 'end-eff. (m)'},'FontSize',FontSZ);   yticks(0:0.2:0.7); 
        xlim([tmin tmax]); ylim([0 0.7]); 
        grid on
        
        set(gca, 'XTickLabel', [])
        yt = get(gca, 'YTick');    set(gca, 'FontSize', FontSZ);
        if plot_2_joint==2
            pos1 = get(sp_handle1,'Position');
            pos1_new = pos1+ [0 h_new_sp 0 h_new_sp];
            set(sp_handle1,'Position',pos1_new);
        end
%         box off
        % Create second Y axes on the right.
        a2 = axes('YAxisLocation', 'Right');
        % Hide second plot.
        set(a2, 'color', 'none');
        set(a2, 'XTick', []);
        % Set scala for second Y.
        set(a2, 'YLim', [0 0.7], 'YTick',0:0.2:0.7); 
        
        hold off
        
    sp_handle2 = subplot(nb_subplot,1,2); hold on
        plot(time_rel_reactCtrl, dist_hL_EB, time_rel_reactCtrl, dist_head_EB, 'LineWidth',LineSZ);
        plot(time_rel_pps, dist_l_locus(:,2),'m.');
        
        area(time_rel_pps, part2(:,idx_ppsEv_on_skin_act),'EdgeColor','c','FaceColor','c','FaceAlpha',0.2); 
%         plot(pps_time,pps_thres,'--c');
        if plot_dist_thres
            plot(pps_time,dist_thres,'--g');
        end
        if plot_dist_mod_thres
            plot(pps_time,dist_mod_thres,'--b');
        end
        if plot_dist_inc_thres
            plot(pps_time,dist_inc_thres,'--','color',[1 0.5 0]);
        end
        
        ylabel({'distance to', 'elbow (m)'},'FontSize',FontSZ);   yticks(0:0.2:0.7); 
        xlim([tmin tmax]); ylim([0 0.7]); grid on
%         title('HUMAN PARTS (H) VS. ROBOT LEFT ARM (R)','FontSize',FontSZ);
        set(gca, 'XTickLabel', [])
        yt = get(gca, 'YTick');    set(gca, 'FontSize', FontSZ);
        if plot_2_joint==2
            pos2 = get(sp_handle2,'Position');
            pos2_new = pos2+ [0 0.0 0 h_new_sp];
            set(sp_handle2,'Position',pos2_new);
        end
        hold off
        
%     subplot(9,1,4); 
%         area(time_rel_pps, part1(:,idx_ppsEv_on_skin_act),'EdgeColor','b','FaceColor','c','FaceAlpha',0.5); 
%         ylabel({'activation';'on l\_hand(R)'},'FontSize',FontSZ);              yticks(0:0.2:1);
%         xlim([tmin tmax]); ylim([0.0 1.0]); grid on
%         set(gca, 'XTickLabel', [])
%         yt = get(gca, 'YTick');    set(gca, 'FontSize', FontSZ);
        
%     subplot(9,1,3); 
%         area(time_rel_pps, part2(:,idx_ppsEv_on_skin_act),'EdgeColor','b','FaceColor','c','FaceAlpha',0.5); 
%         ylabel({'activation';'on l\_forearm(R)'},'FontSize',FontSZ);           yticks(0:0.2:1);  
%         xlim([tmin tmax]); ylim([0.0 1.0]); grid on
%         set(gca, 'XTickLabel', [])
%         yt = get(gca, 'YTick');    set(gca, 'FontSize', FontSZ);
        
    for j=jnts_plot
        if plot_2_joint==1
            if j==8
                k = 0;
            elseif j==10
                k = 3;
            end
        elseif plot_2_joint==0
            switch j
                case {7 , 8}
                    k = -2;
                case {9 , 10}
                    k = 2;
            end
        elseif plot_2_joint==2
            switch j
                case {4,5,6}
                    k = -7;
                case {7,8}
                    k = -2;
                case {9, 10}
                    k = 2;
            end
        end
        subplot(nb_subplot,1,j-6+2-k); 
        hold on;
        plot(time_rel_reactCtrl,d(:,joint_info(j).vel_limit_min_avoid_column),'--b','Marker','v','MarkerSize',2); % current min joint vel limit set by avoidance handler
        plot(time_rel_reactCtrl,d(:,joint_info(j).vel_limit_max_avoid_column),'--m','Marker','^','MarkerSize',2); % current max joint vel limit set by avoidance handler
        plot(time_rel_reactCtrl,d(:,joint_info(j).vel_column),'-k'); % current joint velocity

%         plot([time_rel_reactCtrl(1) time_rel_reactCtrl(end)],[joint_info(j).vel_limit_min joint_info(j).vel_limit_min],'-.c'); % min joint vel limit
%         plot([time_rel_reactCtrl(1) time_rel_reactCtrl(end)],[joint_info(j).vel_limit_max joint_info(j).vel_limit_max],'-.r'); % max joint vel limit   

        xlim([tmin tmax]); ylim([(joint_info(j).vel_limit_min - 1) (joint_info(j).vel_limit_max + 1) ]);
%         if j == chainActiveDOF
%             xlabel('time (s)','FontSize',FontSZ);
%         end
        ylabel({joint_info(j).name,'vel. (deg/s)'},'FontSize',FontSZ);

%         title(joint_info(j).name,'FontSize',FontSZ);
        hold off;
        set(gca, 'XTickLabel', [])
        yt = get(gca, 'YTick');    set(gca, 'FontSize', FontSZ);
    end 
    
    subplot(nb_subplot,1,nb_subplot);
        plot(time_rel_reactCtrl,dist,'go','MarkerSize',3);
%         title('Error between Reference and EE over time');
        ylabel({'end-eff.','error (m)'},'FontSize',FontSZ);
        xlim([tmin tmax]); xlabel('time (s)', 'FontSize',FontSZ);
        xt = get(gca, 'XTick');    set(gca, 'FontSize', FontSZ);
        yt = get(gca, 'YTick');    set(gca, 'FontSize', FontSZ);
        grid on;