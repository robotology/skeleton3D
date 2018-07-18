% plot_2_joint = 1;
% plot_dist_thres = 1;        % neutral
% plot_dist_mod_thres = 0;    % reduced
% plot_dist_inc_thres = 0;    % increased
% PLOT_JOINT=0 
FontSZ = 12;

h_new_sp = 0.02;
% no_pps1 = find(part1 == -1000);
% part1(no_pps1)=0;
% no_pps2 = find(part2 == -1000);
% part1(no_pps2)=0;

if PLOT_JOINT==1
    if plot_2_joint==1      % plot 2 joints
        nb_subplot = 5;
        if plot_dist_elbow==0
            nb_subplot = 4;
        end
        nb_jnts_plot = 2;
    %     jnts_plot = 8:2:chainActiveDOF;
        jnts_plot = chainActiveDOF:-2:8;
        out_pos = [0 0 15 25];
    elseif plot_2_joint==0  % plot 4 joints
        nb_subplot = 7;
        nb_jnts_plot = 4;
    %     jnts_plot = 7:chainActiveDOF;
        jnts_plot = chainActiveDOF:-1:7;
        out_pos = [0 0 15 31];
    elseif plot_2_joint==2  % plot 7 joints, including 3 stupid shoulders
        nb_subplot = 10;
        nb_jnts_plot = 7;
        jnts_plot = chainActiveDOF:-1:4;
        out_pos = [0 0 12 31];
        FontSZ = 8;
    end
elseif plot_dist_elbow==0
        nb_subplot = 2;
        out_pos = [0 0 17 14];
else
    nb_subplot = 3;
    out_pos = [0 0 15 15];
end

%% Color
handColor = hex2rgb('#308bc9');
headColor = hex2rgb('#c15112');
ppsColor = hex2rgb('bbf0a8');
green = hex2rgb('#2f786e');
eeColor = hex2rgb('#2f786e ');
velLimColor = hex2rgb('#97c4e7');
skinColor4 = hex2rgb('#ff8ce2');%('#f7cb2c');   % r_hand
skinColor5 = hex2rgb('#f7ed6a');                % r_forearm

%% Plot
% fig_all_in_once = figure('units','normalized','outerposition',[0 0 0.5 1]);
fig_all_in_once = figure('units','centimeters','outerposition',out_pos);

    sp_handle1 = subplot(nb_subplot,1,1); hold on
%         area(time_rel_pps, part1(:,idx_ppsEv_on_skin_act),'EdgeColor',ppsColor,'FaceColor',ppsColor,'FaceAlpha',0.7); % HRI2018
          area(time_rel_pps, part4(:,idx_ppsEv_on_skin_act),'EdgeColor',ppsColor,'FaceColor',ppsColor,'FaceAlpha',0.7); % Humanoids2018
%         plot(time_rel_reactCtrl, dist_hL_EE, time_rel_reactCtrl,
%         dist_head_EE, 'LineWidth',LineSZ);   % HRI2018
        
        if plot_pps==1
            if plot_skin==0
                plot(time_rel_reactCtrl, dist_hL_EE, time_rel_reactCtrl, dist_hR_EE, 'LineWidth',LineSZ); % Humanoids2018
            else
                plot(time_rel_reactCtrl, dist_hL_EE, 'LineWidth',LineSZ); % Humanoids2018
            end
        end

        if plot_skin==1
%             plot(time_rel_skin,0.2*skin_Ev4,'LineWidth',LineSZ,'Color',skinColor4);
%             plot(time_rel_skin,0.2*skin_Ev5,'LineWidth',LineSZ,'Color',skinColor5);
            area(time_rel_skin, 0.2*skin_Ev4,'EdgeColor',skinColor4,'FaceColor',skinColor4,'FaceAlpha',0.7); % Humanoids2018
            area(time_rel_skin, 0.2*skin_Ev5,'EdgeColor',skinColor5,'FaceColor',skinColor5,'FaceAlpha',0.7); % Humanoids2018
        end
%         plot(time_rel_pps, dist_l_locus(:,1),'m.');   // distance to
%         locus


        if plot_dist_thres
            plot(pps_time,dist_thres,'--','color',green,'LineWidth',1);
        end
        if plot_dist_mod_thres
            plot(pps_time,dist_mod_thres,'--','color',handColor,'LineWidth',1);
        end
        if plot_dist_inc_thres
            plot(pps_time,dist_inc_thres,'--','color',headColor,'LineWidth',1);
        end
          
%         ylabel({'distance to', 'end-eff. (m)'},'FontSize',FontSZ);  
        title('distance to iCub hand (m) & PPS activation','FontSize',FontSZ)
        yticks(0:0.2:1.2); 
        xlim([tmin tmax]); ylim([0 ylim_distEE]); 
        grid on
        
        set(gca, 'XTickLabel', [])
        yt = get(gca, 'YTick');    set(gca, 'FontSize', FontSZ);
        if plot_2_joint==2
            pos1 = get(sp_handle1,'Position');
            pos1_new = pos1+ [0 h_new_sp 0 h_new_sp];
            set(sp_handle1,'Position',pos1_new);
        end
       
        hold off
        ax = gca;
        ax0 = ax;
        ax = set_tight_border(ax);
        
    if plot_dist_elbow
    sp_handle2 = subplot(nb_subplot,1,2); hold on
        area(time_rel_pps, part2(:,idx_ppsEv_on_skin_act),'EdgeColor',ppsColor,'FaceColor',ppsColor,'FaceAlpha',0.7); 
%         plot(time_rel_reactCtrl, dist_hL_EB, time_rel_reactCtrl,
%         dist_head_EB, 'LineWidth',LineSZ); % HRI2018
        plot(time_rel_reactCtrl, dist_hL_EB, time_rel_reactCtrl, dist_hR_EB, 'LineWidth',LineSZ);   % Humanoids2018
%         plot(time_rel_pps, dist_l_locus(:,2),'m.');   // distance to
%         locus
        
        
        if plot_dist_thres
            plot(pps_time,dist_thres,'--','color',green,'LineWidth',1);
        end
        if plot_dist_mod_thres
            plot(pps_time,dist_mod_thres,'--','color',handColor,'LineWidth',1);
        end
        if plot_dist_inc_thres
            plot(pps_time,dist_inc_thres,'--','color',headColor,'LineWidth',1);
        end
        
%         ylabel({'distance to', 'elbow (m)'},'FontSize',FontSZ);   
        yticks(0:0.2:1.1); 
        title('distance to elbow (m)','FontSize',FontSZ)
        xlim([tmin tmax]); ylim([0 1.1]); 
        grid on
        set(gca, 'XTickLabel', [])
        yt = get(gca, 'YTick');    set(gca, 'FontSize', FontSZ);
        if plot_2_joint==2
            pos2 = get(sp_handle2,'Position');
            pos2_new = pos2+ [0 0.0 0 h_new_sp];
            set(sp_handle2,'Position',pos2_new);
        end
        hold off
        ax = gca;
        ax0 = ax;
        ax = set_tight_border(ax);
    end
    if PLOT_JOINT==1    
    for j=jnts_plot
        if plot_2_joint==1
            if j==8
                k = 0;
            elseif j==10
                k = 3;
            end
            if plot_dist_elbow==0
                if j==8
                    k = 1;
                elseif j==10
                    k = 4;
                end
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
        
        x = time_rel_reactCtrl';
        yl = d(:,joint_info(j).vel_limit_min_avoid_column)';
        yu = d(:,joint_info(j).vel_limit_max_avoid_column)';
%         fill([x fliplr(x)], [yu fliplr(yl)], [.9 .9 .9], 'linestyle', 'none')
        x2 = [x, fliplr(x)];
        inBetween = [yl, fliplr(yu)];
        fill(x2, inBetween, velLimColor,'FaceAlpha',0.6, 'EdgeColor','none');
        
%         plot(time_rel_reactCtrl,d(:,joint_info(j).vel_limit_min_avoid_column),'--b','Marker','v','MarkerSize',2); % current min joint vel limit set by avoidance handler
%         plot(time_rel_reactCtrl,d(:,joint_info(j).vel_limit_max_avoid_column),'--m','Marker','^','MarkerSize',2); % current max joint vel limit set by avoidance handler
%         ciplot(d(:,joint_info(j).vel_limit_min_avoid_column),d(:,joint_info(j).vel_limit_max_avoid_column),d(:,joint_info(j).vel_limit_max_avoid_column),'c');
        plot(time_rel_reactCtrl,d(:,joint_info(j).vel_column),'-','color',handColor,'LineWidth',0.5); % current joint velocity
        

        xlim([tmin tmax]); ylim([(joint_info(j).vel_limit_min - 1) (joint_info(j).vel_limit_max + 1) ]);
%         if j == chainActiveDOF
%             xlabel('time (s)','FontSize',FontSZ);
%         end
%         ylabel({joint_info(j).name,'vel. (deg/s)'},'FontSize',FontSZ);
        titleJoint = strcat(joint_info(j).name,{' '},'velocity (joint nr.',{' '},num2str(j-3),{') '},'(deg/s)'); 
        title(titleJoint,'FontSize',FontSZ);

        hold off;
        set(gca, 'XTickLabel', [])
        yt = get(gca, 'YTick');    set(gca, 'FontSize', FontSZ);
        ax = gca;
        ax0 = ax;
        ax = set_tight_border(ax);
    end 
    end
    
    subplot(nb_subplot,1,nb_subplot);
        plot(time_rel_reactCtrl,dist,'LineWidth',LineSZ,'color',eeColor);
%         ylabel({'end-eff.','error (m)'},'FontSize',FontSZ);
        title({'Error between end-effector and target (m)'},'FontSize',FontSZ);
        xlim([tmin tmax]); xlabel('time (s)', 'FontSize',FontSZ);
        ylim([0 ylimEE]); %0.03 0.08 0.12
        xt = get(gca, 'XTick');    set(gca, 'FontSize', FontSZ);
        xt_new = xt-tmin;
%         xticklabels({string(xt_new)})
        yt = get(gca, 'YTick');    set(gca, 'FontSize', FontSZ);
        grid on;
        
        ax = gca;
        k = 1.5;
        outerpos = ax.OuterPosition
        ti = ax0.TightInset
        left = outerpos(1) + k*ti(1);
        bottom = outerpos(2);% + k*ti(2);
        ax_width = outerpos(3) - 1.5*k*ti(1);
        ax_height = outerpos(4) - ti(2) - ti(4);
        if PLOT_JOINT==0
            bottom = outerpos(2) + 4.5*ti(2);
            ax_height = outerpos(4) - ti(2) - 2.5*ti(4);
        end
        ax.Position = [left bottom ax_width ax_height];