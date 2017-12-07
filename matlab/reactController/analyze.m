% Author: Matej Hoffmann
% clear; 

visualize_time_stats = false;
visualize_target = false;
visualize_elbow_target = false;
visualize_all_joint_pos = false;
visualize_all_joint_vel = false;
visualize_single_joint_in_detail = false;
visualize_ineq_constr = false;
visualize_ipopt_stats = false;
save_figs = false;
chosen_time_column = 6; % 4 for sender, 6 for receiver 

%path_prefix = 'input/';
%path_prefix = 'icubSimTests/test_20160404a/';
%path_prefix = 'multipleControlPoints_icubSim/data2/';
path_prefix = './data_1030/';
%path_prefix = 'icubSimTests/circleUgosTestCode_a/';
%path_prefix = 'icubSimTests/circleUgosTestCode_c_orientation_dt0.04/';
%path_prefix = 'icubExperiments/moveWithIpoptWithoutAcceptHeuristicsOldTolerance_works/';
path_prefix_dumper = '';


if save_figs
  mkdir('output');
end

% param file - columns: 1:#DOF, then joint pos min max for every DOF, then
% joint vel limits for every DOF, then ...
%  fout_param<<trajTime<<" "<<trajSpeed<<" "<<tol<<" "<<globalTol<<" "<<getRate()/1000.0<<" "<<boundSmoothnessFlag<<" "<<boundSmoothnessValue;
%if(controlMode == "velocity") fout_param<<"1 "; else if(controlMode == "positionDirect")    fout_param<<"2 ";
% for 10 DOF case: 1:nDOF, 2-21 joint pos min/max, 22-41 joint vel limits, 42 traj time, 43 traj speed (deg/s), 44: tol, 
%45: globalTol, 46: rate is s, 47: bound_smoothness flag,
% 48: bound smoothness value, 49: controlMode, 50: ipOptMemory 0~off, 1~on
% 7 DOF case: 1:nDOF, 2-15 joint pos min/max, 16-29 joint vel limits, 30 traj time, 31 traj speed (deg/s), 32: tol, 33: globalTol, 34: rate is s, 35: bound_smoothness flag,
% 36: bound smoothness value, 37: controlMode, 38: ipOptMemory 0~off, 1~on

d_params=importdata([path 'param.log']);

NR_EXTRA_TIME_COLUMNS = 4; % these will be created so that there is time starting from 0, plus time increment column - this 2 times (sender and receiver time stamp) - for diagnostics

% data file (after adding  extra time cols - i.e. d, not d_orig) -  in columns on the output for 10 DOF case:
%1: packetID, 2: sender time stamp, 3:receiver time stamp, 
% 4: time from 0, sender; 5: increments of 4; 6: time from 0 receiver; 7: increments in 6 
%8: nActiveDOF in chain
% 9:11 desired final target position (for end-effector),
% 12:14 current end effector position 
% 15:17 current desired target position given by particle (for end-effector)
% 18:20 desired final target orientation (for end-effector),
% 21:23 current end effector orientation 
% 24:26 current desired target orientation given by referenceGen (currently not supported - equal to desired final - o_d)
%variable - if torso on: 27:36: if torso off: 27:33 ; joint velocities as solution from ipopt and sent to robot 
%variable - if torso on: 37:46: if torso off: 34:40 ; joint positions as solution to control and sent to robot 
%variable - if torso on: 47:66; if torso off: 41:54;  joint vel limits as input to ipopt, after avoidanceHandler
%assuming it is row by row, so min_1, max_1, min_2, max_2 etc.
% variable - if torso on: 67; if torso off: 55; ipopt exit code (Solve_Succeeded=0)
% variable - if torso on: 68; if torso off: 56; time taken to solve problem (s) ~ ipopt + avoidance handler
% variable - if positionDirect & torso on: 69:78; if torso off: 57:63;  joint pos from
% virtual chain ipopt is operating on
% variable - if positionDirect & torso on: 79:81; target elbow position 
% variable - if positionDirect & torso on: 82:84; actual elbow position (real chain) 

d_orig=importdata([path path_prefix_dumper 'reactCtrl/data.log']);

TIME_FROM_ZERO_1_COLUMN = 4;
TIME_FROM_ZERO_DELTA_1_COLUMN = 5;
TIME_FROM_ZERO_2_COLUMN = 6;
TIME_FROM_ZERO_DELTA_2_COLUMN = 7;
PACKET_ID_COLUMN = 1;
TIME_ABS_1_COLUMN = 2;
TIME_ABS_2_COLUMN = 3;

target_x.column = 9;
target_y.column = 10;
target_z.column = 11;
    
EE_x.column = 12;
EE_y.column = 13;
EE_z.column = 14;

targetEE_x.column = 15;
targetEE_y.column = 16;
targetEE_z.column = 17;

%controlMode = 'velocity';
%controlMode = 'positionDirect'; % should be picked up automatically from
%the param file

if((d_params(1) == 10) && (d_orig(1,4) == 10) ) % 10 DOF situation - 3 torso, 7 arm
    chainActiveDOF = 10
        
    joint_info(1).name = '1st torso - pitch'; joint_info(2).name = '2nd torso - roll'; joint_info(3).name = '3rd torso - yaw'; 
    joint_info(4).name = '1st shoulder'; joint_info(5).name = '2nd shoulder'; joint_info(6).name = '3rd shoulder'; 
%     joint_info(7).name = '1st elbow'; joint_info(8).name = '2nd elbow';  joint_info(9).name = '1st wrist'; joint_info(10).name = '2nd wrist'; 
    joint_info(7).name = 'elbow'; joint_info(8).name = 'elbow';  joint_info(9).name = 'wrist'; joint_info(10).name = 'wrist'; 

    
    for i=1:chainActiveDOF
        joint_info(i).pos_limit_min = d_params(2*i); joint_info(i).pos_limit_max = d_params(2*i+1);
        joint_info(i).vel_limit_min = d_params(20+2*i); joint_info(i).vel_limit_max = d_params(20+2*i+1);
        joint_info(i).vel_column = 22+i+NR_EXTRA_TIME_COLUMNS; joint_info(i).pos_column = 32+i+NR_EXTRA_TIME_COLUMNS; 
        joint_info(i).vel_limit_min_avoid_column = 41+2*i+NR_EXTRA_TIME_COLUMNS; joint_info(i).vel_limit_max_avoid_column = 41+2*i+1+NR_EXTRA_TIME_COLUMNS;
        joint_info(i).integrated_pos_column = 64+i+NR_EXTRA_TIME_COLUMNS; 
    end
    
    if (length(d_params) == 41) % old format before outputting extra params (prior to 13.2.2016)
        dT = 0.02 % need to set manually - 20 ms
        boundSmoothnessFlag = false; % or set manually based on documentation from runs
    elseif (length(d_params) == 46)
        dT = d_params(46)
        boundSmoothnessFlag = false; % or set manually based on documentation from runs
    elseif  (length(d_params) == 48) % logging bound smoothness - as of 16.2.
        dT = d_params(46)
        if (d_params(47) ==1)
            boundSmoothnessFlag = true
            boundSmoothnessValue = d_params(48)
        else
            boundSmoothnessFlag = false
        end
    elseif  (length(d_params) >= 49) % logging controlMode as of 19.2., ipOptMemory as off 22.2.
        dT = d_params(46)
        if (d_params(47) ==1)
            boundSmoothnessFlag = true
            boundSmoothnessValue = d_params(48)
        else
            boundSmoothnessFlag = false
        end
        if(d_params(49) == 1)
            controlMode = 'velocity'
        elseif(d_params(49) == 2)
            controlMode = 'positionDirect'    
        end
        if (length(d_params) >= 53)
            if(d_params(53) == 1)
                interactionMode = 'stiff'
            elseif(d_params(53) == 0)
                interactionMode = 'compliant'    
            end
        end
        if (length(d_params) >= 54)
            if(d_params(54) == 1)
                additionalControlPointsFlag = true
            elseif(d_params(54) == 0)
                additionalControlPointsFlag = false    
            end
        end
    end   
         
   ipoptExitCode_col = 67; % setting the cols already for the new d, after adding extra time cols
   timeToSolve_s_col = 68;
     
    if (strcmp(controlMode,'positionDirect')) 
        if (size(d_orig,2) <  74) 
            error('It seems that integrated positions were not logged.'); 
        end
        target_elbow_x.column = 79;
        target_elbow_y.column = 80;
        target_elbow_z.column = 81;
        elbow_x.column = 82;
        elbow_y.column = 83;
        elbow_z.column = 84;
    else 
        target_elbow_x.column = 69;
        target_elbow_y.column = 70;
        target_elbow_z.column = 71;
        elbow_x.column = 72;
        elbow_y.column = 73;
        elbow_z.column = 74;
    end
    
   
        
elseif((d_params(1) == 7) && (d_orig(1,4) == 7) ) % 7 DOF situation - arm
    chainActiveDOF = 7
    
    joint_info(1).name = '1st shoulder'; joint_info(2).name = '2nd shoulder'; joint_info(3).name = '3rd shoulder'; 
    joint_info(4).name = '1st elbow'; joint_info(5).name = '2nd elbow'; 
    joint_info(6).name = '1st wrist'; joint_info(7).name = '2nd wrist'; 

        
    for i=1:chainActiveDOF
        joint_info(i).pos_limit_min = d_params(2*i); joint_info(i).pos_limit_max = d_params(2*i+1);
        joint_info(i).vel_limit_min = d_params(14+2*i); joint_info(i).vel_limit_max = d_params(14+2*i+1);
        joint_info(i).vel_column = 22+i+NR_EXTRA_TIME_COLUMNS; joint_info(i).pos_column = 29+i+NR_EXTRA_TIME_COLUMNS; 
        joint_info(i).vel_limit_min_avoid_column = 35+2*i+NR_EXTRA_TIME_COLUMNS; joint_info(i).vel_limit_max_avoid_column = 35+2*i+1+NR_EXTRA_TIME_COLUMNS;
        joint_info(i).integrated_pos_column = 52+i+NR_EXTRA_TIME_COLUMNS; 
    end
    
    % 7 DOF case: 1:nDOF, 2-15 joint pos min/max, 16-29 joint vel limits, 30 traj time, 31 traj speed (deg/s), 32: tol, 33: globalTol, 34: rate is s, 35: bound_smoothness flag,
    % 36: bound smoothness value, 37: controlMode, 38: ipOptMemory 0~off, 1~on
    if (length(d_params) >= 38) 
        dT = d_params(34)
        if (d_params(35) ==1)
            boundSmoothnessFlag = true
            boundSmoothnessValue = d_params(36)
        else
            boundSmoothnessFlag = false
        end
        if(d_params(37) == 1)
            controlMode = 'velocity'
        elseif(d_params(37) == 2)
            controlMode = 'positionDirect'    
        end
        if(d_params(38) == 1)
            ipOptMemory = true
        elseif(d_params(38) == 0)
            ipOptMemory = false    
        end
        if (length(d_params) >= 40)
           if (d_params(39) ==1)
            ipOptFilter = true
            ipOptFilterValue = d_params(40)
           else
            ipOptFilter = false
           end
        end
         
       % TODO set interaction mode and additionalControl points here
        
       
    else
        error('Unexpected param.log length for 7 DOF chain');
    end
   
    ipoptExitCode_col = 55; % setting the cols already for the new d, after adding extra time cols
    timeToSolve_s_col = 56;
    
    if ( (strcmp(controlMode,'positionDirect')) && (size(d_orig,2) <  59) )
        error('It seems that intergrated positions were not logged.'); 
    end
    % TODO add elbow pos plotting here
     
else
   error('This script is currently not supporting other than 10 DOF and 7 DOF chains'); 
end



%% create extra time columns

    nr_rows_dat = size(d_orig,1);
    time_cols_to_insert = NaN(nr_rows_dat,4);
    time_cols_to_insert(1,1)=0; time_cols_to_insert(1,2)=0;time_cols_to_insert(1,3)=0; time_cols_to_insert(1,4)=0;
    for i=2:nr_rows_dat
        time_cols_to_insert(i,1)=d_orig(i,2)-d_orig(1,2); % sender time stamp
        time_cols_to_insert(i,2)=time_cols_to_insert(i,1)-time_cols_to_insert(i-1,1); % increment - to see if it is stable
        time_cols_to_insert(i,3)=d_orig(i,3)-d_orig(1,3); % this would be the receiver time stamp
        time_cols_to_insert(i,4)=time_cols_to_insert(i,3)-time_cols_to_insert(i-1,3); % increment - to see if it is stable
    end
    d = [d_orig(:,1:3) time_cols_to_insert(:,1:4) d_orig(:,4:end)];
    

%% info about data matrix

sz=size(d);
L=sz(1); % ~ nr. rows

t = d(:,TIME_ABS_2_COLUMN); 
time_reactCtrl = t;
time0_reactCtrl = time_reactCtrl(1);

EEd_f = d(:,target_x.column:target_z.column);
EE_t  = d(:,EE_x.column:EE_z.column);
EEd_t = d(:,targetEE_x.column:targetEE_z.column);
% EB_t  = d(:,elbow_x.column:elbow_z.column);
%% plot time diagnostics

if visualize_time_stats
    f13 = figure(13); clf;
    set(f13,'Name','Time statistics');

    subplot(3,1,1);
        title('Absolute time');
        hold on;
          plot(d(:,TIME_ABS_1_COLUMN),'b*');
          plot(d(:,TIME_ABS_2_COLUMN),'k.');
        hold off;
        legend('time (sender)','time (receiver)');
        ylabel('Time (s)');
       
    subplot(3,1,2)
        title('Time starting from 0');
        hold on;
          plot(d(:,TIME_FROM_ZERO_1_COLUMN),'b*');
          plot(d(:,TIME_FROM_ZERO_2_COLUMN),'k.');
        hold off;
        legend('time (sender)','time (receiver)');
        ylabel('Time (s)');
       
     subplot(3,1,3);
           title(' Time increments');
           hold on;
             plot(t(2:end),d(2:end,TIME_FROM_ZERO_DELTA_1_COLUMN),'b*');
             plot(t(2:end),d(2:end,TIME_FROM_ZERO_DELTA_2_COLUMN),'k.');
             plot([t(2) t(end)],[dT dT],'r-','LineWidth',2);   
           hold off;
           legend('sender','receiver');
           ylabel('Sampling - delta time (s)');
           xlabel('Time (s)');
       
    if save_figs
       saveas(f13,'output/TimeStats.fig'); 
    end

end

%% reference vs. real position end-effector and elbow
if visualize_target

    f1 = figure(1); clf(f1); set(f1,'Color','white','Name','Target, reference, end-effector (and elbow) in space');  
    hold on; axis equal; view([-130 30]); grid;
    xlabel('x [m]');
    ylabel('y [m]');
    zlabel('z [m]');

    plot3(d(:,target_x.column),d(:,target_y.column),d(:,target_z.column),'r*','LineWidth',4); % plots the desired target trajectory
    %plot3(d(end,5),d(end,6),d(end,7),'r*','LineWidth',10); % plots the desired target final pos

    plot3(d(:,targetEE_x.column),d(:,targetEE_y.column),d(:,targetEE_z.column),'go','LineWidth',2); % plots the end-eff targets as given by reference
    plot3(d(end,targetEE_x.column),d(end,targetEE_y.column),d(end,targetEE_z.column),'go','LineWidth',4); % plots the end-eff reference final pos

    plot3(d(:,EE_x.column),d(:,EE_y.column),d(:,EE_z.column),'k.','LineWidth',3); % plots the end-eff trajectory
    plot3(d(end,EE_x.column),d(end,EE_y.column),d(end,EE_z.column),'kx','LineWidth',6); % plots the end-eff final pos

    if visualize_elbow_target % for elbow - target and reference are currently identical (9.12.2016) 
         plot3(d(:,target_elbow_x.column),d(:,target_elbow_y.column),d(:,target_elbow_z.column),'r*','LineWidth',4); % plots the desired elbow target trajectory
         plot3(d(:,target_elbow_x.column),d(:,target_elbow_y.column),d(:,target_elbow_z.column),'go','LineWidth',2); % plots the elbow targets as given by reference
         plot3(d(end,target_elbow_x.column),d(end,target_elbow_y.column),d(end,target_elbow_z.column),'go','LineWidth',4); % plots the elbow reference final pos
         plot3(d(:,elbow_x.column),d(:,elbow_y.column),d(:,elbow_z.column),'k.','LineWidth',3); % plots the elbow real trajectory
         plot3(d(end,elbow_x.column),d(end,elbow_y.column),d(end,elbow_z.column),'kx','LineWidth',6); % plots the elbow final pos plot3(d(:,targetEE_x.column),d(:,targetEE_y.column),d(:,targetEE_z.column),'go','LineWidth',2); % plots the end-eff targets as given by reference
         plot3(d(end,targetEE_x.column),d(end,targetEE_y.column),d(end,targetEE_z.column),'go','LineWidth',4); % plots the end-eff target final pos
    end    
       
    hold off;

    f11 = figure(11); clf(f11); set(f11,'Color','white','Name','Target, reference, end-effector in time and space');  
        subplot(3,1,1);
            hold on;
            title('x coordinate');
                plot(t,100*d(:,target_x.column),'r*','MarkerSize',5);
                plot(t,100*d(:,targetEE_x.column),'go','MarkerSize',3);
                plot(t,100*d(:,EE_x.column),'k.','MarkerSize',4);
                ylabel('position (cm)');
            hold off;
         
        subplot(3,1,2);
            hold on;
            title('y coordinate');
                plot(t,100*d(:,target_y.column),'r*','MarkerSize',5);
                plot(t,100*d(:,targetEE_y.column),'go','MarkerSize',3);
                plot(t,100*d(:,EE_y.column),'k.','MarkerSize',4);
                ylabel('position (cm)');
            hold off;  
       
        subplot(3,1,3);
            hold on;
            title('z coordinate');
                plot(t,100*d(:,target_z.column),'r*','MarkerSize',5);
                plot(t,100*d(:,targetEE_z.column),'go','MarkerSize',3);
                plot(t,100*d(:,EE_z.column),'k.','MarkerSize',4);
                ylabel('position (cm)');
            hold off;
     
    if visualize_elbow_target
       f12 = figure(12); clf(f12);
       set(f12,'Color','white','Name','Target and elbow pos in time and space');  
        subplot(3,1,1);
            hold on;
            title('x coordinate');
                plot(t,100*d(:,target_elbow_x.column),'r*','MarkerSize',5);
                plot(t,100*d(:,target_elbow_x.column),'go','MarkerSize',3);
                plot(t,100*d(:,elbow_x.column),'k.','MarkerSize',4);
                ylabel('position (cm)');
            hold off;
         
        subplot(3,1,2);
            hold on;
            title('y coordinate');
                plot(t,100*d(:,target_elbow_y.column),'r*','MarkerSize',5);
                plot(t,100*d(:,target_elbow_y.column),'go','MarkerSize',3);
                plot(t,100*d(:,elbow_y.column),'k.','MarkerSize',4);
                ylabel('position (cm)');
            hold off; 
            
         subplot(3,1,3);
            hold on;
            title('z coordinate');
                plot(t,100*d(:,target_elbow_z.column),'r*','MarkerSize',5);
                plot(t,100*d(:,target_elbow_z.column),'go','MarkerSize',3);
                plot(t,100*d(:,elbow_z.column),'k.','MarkerSize',4);
                ylabel('position (cm)');
            hold off;
     
    end
         
    
    
    f2 = figure(2); clf(f2); set(f2,'Color','white','Name','End-eff reference evolution');  
        subplot(4,1,1);
            hold on;
            title('reference (x), reference (y)');
            plotyy(t,100*d(:,targetEE_x.column),t,100*d(:,targetEE_y.column));
            legend('reference (x)','reference (y)');
            ylabel('position (cm)');
            hold off;

        subplot(4,1,2);
            hold on;
            title('reference (z)');
            plot(t,100*d(:,targetEE_z.column));
            ylabel('position (cm)');
            hold off;

        subplot(4,1,3);
            title('End-eff reference increments');
            hold on;
            for i=2:L
                plot(t(i),100*myEuclDist3d(d(i,targetEE_x.column),d(i,targetEE_y.column),d(i,targetEE_z.column),...
                    d(i-1,targetEE_x.column),d(i-1,targetEE_y.column),d(i-1,targetEE_z.column)),'ko','MarkerSize',4);
            end
            %xlabel('Time (s)');
            ylabel('Distance (cm)');
            hold off;

        subplot(4,1,4);  
            title('End-eff speed needed');
            hold on;
            for i=2:L
                plot(t(i),100*myEuclDist3d(d(i,targetEE_x.column),d(i,targetEE_y.column),d(i,targetEE_z.column),...
                    d(i-1,targetEE_x.column),d(i-1,targetEE_y.column),d(i-1,targetEE_z.column))/dT,'ko','MarkerSize',4);
            end
            xlabel('Time (s)');
            ylabel('Speed (cm/s)');
            hold off;
            
      f21 = figure(21); clf(f21); set(f21,'Color','white','Name','End-eff evolution');  
        subplot(4,1,1);
            hold on;
            title('Position (x), (y)');
            plotyy(t,100*d(:,EE_x.column),t,100*d(:,EE_y.column));
            legend('(x)','(y)');
            ylabel('position (cm)');
            hold off;

        subplot(4,1,2);
            hold on;
            title('Position (z)');
            plot(t,100*d(:,EE_z.column));
            ylabel('position (cm)');
            hold off;

        subplot(4,1,3);
            title('End-eff increments');
            hold on;
            for i=2:L
                plot(t(i),100*myEuclDist3d(d(i,EE_x.column),d(i,EE_y.column),d(i,EE_z.column),...
                    d(i-1,EE_x.column),d(i-1,EE_y.column),d(i-1,EE_z.column)),'ko','MarkerSize',4);
            end
            %xlabel('Time (s)');
            ylabel('Distance (cm)');
            hold off;

        subplot(4,1,4);  
            title('End-eff speed');
            hold on;
            for i=2:L
                plot(t(i),100*myEuclDist3d(d(i,EE_x.column),d(i,EE_y.column),d(i,EE_z.column),...
                    d(i-1,EE_x.column),d(i-1,EE_y.column),d(i-1,EE_z.column))/dT,'ko','MarkerSize',4);
            end
            xlabel('Time (s)');
            ylabel('Speed (cm/s)');
            hold off;
    
    
    f22 = figure(22); clf(f22); set(f22,'Color','white','Name','Distance end-eff vs. reference and target');      
   
        xlabel('time (s)');
        [ax,h1,h2] = plotyy(t,100*myEuclDist3d_matrix(d(:,EE_x.column),d(:,EE_y.column),d(:,EE_z.column),d(:,targetEE_x.column),d(:,targetEE_y.column),d(:,targetEE_z.column)),...
            t,100*myEuclDist3d_matrix(d(:,EE_x.column),d(:,EE_y.column),d(:,EE_z.column),d(:,target_x.column),d(:,target_y.column),d(:,target_z.column)));
        set(h1,'Marker','o','MarkerSize',10,'Color','b');
        set(h2,'Marker','*','MarkerSize',10,'Color','g');
        legend('Distance end-eff to reference','Distance end-eff to final target'); % reference is the current target
        set(get(ax(1),'Ylabel'),'String','Distance (cm)'); 
        set(get(ax(2),'Ylabel'),'String','Distance (cm)');
    
    if visualize_elbow_target
    f23 = figure(23); clf(f23); set(f23,'Color','white','Name','Distance elbow vs. reference and target');      
   
        xlabel('time (s)');
        [ax,h1,h2] = plotyy(t,100*myEuclDist3d_matrix(d(:,elbow_x.column),d(:,elbow_y.column),d(:,elbow_z.column),d(:,target_elbow_x.column),d(:,target_elbow_y.column),d(:,target_elbow_z.column)),...
            t,100*myEuclDist3d_matrix(d(:,elbow_x.column),d(:,elbow_y.column),d(:,elbow_z.column),d(:,target_elbow_x.column),d(:,target_elbow_y.column),d(:,target_elbow_z.column)));
        set(h1,'Marker','o','MarkerSize',10,'Color','b');
        set(h2,'Marker','*','MarkerSize',10,'Color','g');
        legend('Distance elbow to reference','Distance elbow to final target'); % reference is the current target
        set(get(ax(1),'Ylabel'),'String','Distance (cm)'); 
        set(get(ax(2),'Ylabel'),'String','Distance (cm)');    
    end

    if save_figs
       saveas(f1,'output/TargetReferenceEndeffectorTrajectoriesInSpace.fig');
       saveas(f11,'output/TargetReferenceEndeffectorTrajectoriesInTime.fig');
       saveas(f12,'output/TargetVsRealElbowTrajectoriesInTime.fig');
       saveas(f2,'output/End-effector reference detail.fig');
       saveas(f21,'output/End-effector position detail.fig');
       saveas(f22,'output/TargetReferenceEndeffectorDistances.fig');
       saveas(f23,'output/TargetReferenceElbowDistances.fig');
    end

end


%% joint values vs. joint limits
if visualize_all_joint_pos
        data = [];
        f3 = figure(3); clf(f3); set(f3,'Color','white','Name','Joint positions');  
       % f4 = figure(4); clf(f4); set(f4,'Color','white','Name','Joint positions - Visual avoidance');  
       % f5 = figure(5); clf(f5); set(f5,'Color','white','Name','Joint positions - Tactile avoidance');  

        for i=1:1 % for all variants of the simulation
            switch i
                case 1 
                    set(0, 'currentfigure', f3); 
                    data = d;
                case 2 
                    set(0, 'currentfigure', f4); 
                    data = d_v;
                case 3 
                    set(0, 'currentfigure', f5); 
                    data = d_t;
            end
            
            for j=1:chainActiveDOF
                subplot(4,3,j); hold on;
                plot(t,data(:,joint_info(j).pos_column));
                plot([t(1) t(end)],[joint_info(j).pos_limit_min joint_info(j).pos_limit_min],'r--'); % min joint pos limit
                plot([t(1) t(end)],[joint_info(j).pos_limit_max joint_info(j).pos_limit_max],'r--'); % max joint pos limit   
                if (strcmp(controlMode,'positionDirect'))
                    plot(t,data(:,joint_info(j).integrated_pos_column),'g-.');
                end
                xlabel('t [s]');
                ylabel('angle [deg]');
                title(joint_info(j).name);
                hold off;
            end    
                
        end   
    if save_figs
        saveas(f3,'output/JointPositions.fig');
        %saveas(f4,'output/JointPositionsVisualAvoidance.fig');
        %saveas(f5,'output/JointPositionsTactileAvoidance.fig');
    end    
end




%% joint velocities vs. joint vel limits
if visualize_all_joint_vel
       
        data = [];
        f6 = figure(6); clf(f6); set(f6,'Color','white','Name','Joint vel - control commands');  
        %f7 = figure(7); clf(f7); set(f7,'Color','white','Name','Joint velocities - Visual avoidance');  
        %f8 = figure(8); clf(f8); set(f8,'Color','white','Name','Joint velocities - Tactile avoidance');  

        for i=1:1 % for all variants of the simulation
            switch i
                case 1 
                    set(0, 'currentfigure', f6); 
                    data = d;
                case 2 
                    set(0, 'currentfigure', f7); 
                    data = d_v;
                case 3 
                    set(0, 'currentfigure', f8); 
                    data = d_t;
            end
            
            for j=1:chainActiveDOF
                subplot(4,3,j); hold on;
                plot(t,data(:,joint_info(j).vel_limit_min_avoid_column),'--c','Marker','v','MarkerSize',2); % current min joint vel limit set by avoidance handler
                plot(t,data(:,joint_info(j).vel_limit_max_avoid_column),'--m','Marker','^','MarkerSize',2); % current max joint vel limit set by avoidance handler
                plot([t(1) t(end)],[joint_info(j).vel_limit_min joint_info(j).vel_limit_min],'-.r'); % min joint vel limit
                plot([t(1) t(end)],[joint_info(j).vel_limit_max joint_info(j).vel_limit_max],'-.r'); % max joint vel limit   
                plot(t,data(:,joint_info(j).vel_column),'-k'); % current joint velocity
                ylim([(joint_info(j).vel_limit_min - 1) (joint_info(j).vel_limit_max + 1) ]);
                xlabel('t [s]');
                ylabel('joint velocity [deg/s]');
                title(joint_info(j).name);
                hold off;
            end    
        end

        f60 = figure(60); clf(f60); set(f60,'Color','white','Name','Joint vel limits');  
            data = d;
            
            for j=1:chainActiveDOF
                subplot(4,3,j); hold on;
                plot(t,data(:,joint_info(j).vel_limit_min_avoid_column),'--c','Marker','v','MarkerSize',2); % current min joint vel limit set by avoidance handler
                plot(t,data(:,joint_info(j).vel_limit_max_avoid_column),'--m','Marker','^','MarkerSize',2); % current max joint vel limit set by avoidance handler
                plot([t(1) t(end)],[joint_info(j).vel_limit_min joint_info(j).vel_limit_min],'-.r'); % min joint vel limit
                plot([t(1) t(end)],[joint_info(j).vel_limit_max joint_info(j).vel_limit_max],'-.r'); % max joint vel limit   
                plot([t(1) t(end)],[0 0],'--k'); % max joint vel limit   
                                %plot(t,data(:,joint_info(j).vel_column),'-k'); % current joint velocity
                ylim([(joint_info(j).vel_limit_min - 1) (joint_info(j).vel_limit_max + 1) ]);
                xlabel('t [s]');
                ylabel('joint velocity [deg/s]');
                title(joint_info(j).name);
                hold off;
            end    
        
        
        
        f61 = figure(61); clf(f61); set(f61,'Color','white','Name','Joint vel increments (control commands)');  
        for j=1:chainActiveDOF
            subplot(4,3,j); hold on;
            if boundSmoothnessFlag
                plot([t(2) t(end)],[boundSmoothnessValue boundSmoothnessValue],'-.r','LineWidth',3); % smoothness limit
                plot([t(2) t(end)],[-boundSmoothnessValue -boundSmoothnessValue],'-.r','LineWidth',3); % smoothness limit
            end
            for i=2:L
                plot(t(i),data(i,joint_info(j).vel_column)-data(i-1,joint_info(j).vel_column),'ok','MarkerSize',4); % increment in joint velocity
            end
            %if boundSmoothnessFlag
             %  ylim([boundSmoothnessValue-0.1 boundSmoothnessValue+0.1]); 
            %end
            xlabel('t [s]');
            ylabel('delta joint vel. [deg/s]');
            title(joint_info(j).name);
            hold off;
        end    
         
    
    if save_figs
        saveas(f6,'output/JointVelocities.fig');
        saveas(f6,'output/JointVelocityLimits.fig');
        %saveas(f7,'output/JointVelocitiesVisualAvoidance.fig');
        %saveas(f8,'output/JointVelocitiesTactileAvoidance.fig');
        saveas(f61,'output/JointVelocitiesIncrements.fig');
    end
end




%% individual joint in detail 
if visualize_single_joint_in_detail

    j = 4; % joint index to visualize

        data = [];
        f10 = figure(10); clf(f10); set(f10,'Color','white','Name',[joint_info(j).name ' in detail']);  
        %f11 = figure(11); clf(f11); set(f11,'Color','white','Name',['Visual avoidance - ' joint_info(j).name]);  
        %f12 = figure(12); clf(f12); set(f12,'Color','white','Name',['Tactile avoidance - ' joint_info(j).name]);  

        for i=1:1 % for all variants of the simulation
            switch i
                case 1 
                    set(0, 'currentfigure', f10); 
                    data = d;
                case 2 
                    set(0, 'currentfigure', f11); 
                    data = d_v;
                case 3 
                    set(0, 'currentfigure', f12); 
                    data = d_t;
            end
         [m,n] = size(data);

         hold on;
         [AX,H1,H2] = plotyy(t,data(:,joint_info(j).pos_column),t,data(:,joint_info(j).vel_column));   
         hold(AX(1),'on');hold(AX(2),'on');
         H7 = plot(AX(2),t,data(:,joint_info(j).vel_limit_min_avoid_column), 'Parent', AX(2), 'LineStyle',':','Color','c','Marker','v','MarkerSize',2);
         H8 = plot(AX(2),t,data(:,joint_info(j).vel_limit_max_avoid_column), 'Parent', AX(2), 'LineStyle',':','Color','m','Marker','^','MarkerSize',2);
         hold(AX(1),'off');hold(AX(2),'off');
         H3 = line([t t],[joint_info(j).pos_limit_min joint_info(j).pos_limit_min], 'Parent', AX(1), 'LineStyle','--','Color','k');
         H4 = line([t t],[joint_info(j).pos_limit_max joint_info(j).pos_limit_max], 'Parent', AX(1), 'LineStyle','--','Color','k');
         H5 = line([t t],[joint_info(j).vel_limit_min joint_info(j).vel_limit_min], 'Parent', AX(2), 'LineStyle',':','Color','r');
         H6 = line([t t],[joint_info(j).vel_limit_max joint_info(j).vel_limit_max], 'Parent', AX(2), 'LineStyle',':','Color','r');
         set(get(AX(1),'Ylabel'),'String','Joint angle [deg]'); 
         set(AX(1),'Ylim',[joint_info(j).pos_limit_min-5 joint_info(j).pos_limit_max+5]); 
         set(get(AX(2),'Ylabel'),'String','Joint velocity [deg/s]');
         set(AX(2),'Ylim',[joint_info(j).vel_limit_min-3 joint_info(j).vel_limit_max+3]); 
         xlabel('t [s]');
         %set(H1,'LineStyle','-');
         %set(H2,'LineStyle','--');
         hold off;

        end
    
    if save_figs
        saveas(f10,'output/SelectedJointDetail.fig');
        %saveas(f11,'output/SelectedJointDetailVisualAvoidance.fig');
        %saveas(f12,'output/SelectedJointDetailTactileAvoidance.fig');
    end
end


%% inequality constraints - shoulder assembly + self-collisions

if visualize_ineq_constr

    jointIndexCorrection = 0;
    if (chainActiveDOF == 7) 
       jointIndexCorrection = -3; 
    end
    
    EXTRA_MARGIN_SHOULDER_INEQ_DEG = (0.05 / (2 * pi) ) * 360; 
    %each of the ineq. constraints for shoulder joints will have an extra safety marging of 0.05 rad on each side - i.e. the actual allowed range will be smaller
    EXTRA_MARGIN_GENERAL_INEQ_DEG =  (0.05 / (2 * pi) ) * 360;
    
    f14 = figure(14); clf(f14); set(f14,'Color','white','Name','Inequality constraints');  

        subplot(6,1,1);
        hold on;
            plot(t, data(:,joint_info(4+jointIndexCorrection).pos_column) - data(:,joint_info(5+jointIndexCorrection).pos_column));
            plot([t(1) t(end)], [-347/1.71+EXTRA_MARGIN_SHOULDER_INEQ_DEG -347/1.71+EXTRA_MARGIN_SHOULDER_INEQ_DEG],'--r');
            %legend([joint_info(4+jointIndexCorrection).name ' - ' joint_info(5+jointIndexCorrection).name],'lower limit');
            title('1st inequality constraint - shoulder');
            ylabel('angle (deg)'); 
        hold off;

        subplot(6,1,2);
        hold on;
            plot(t, data(:,joint_info(4+jointIndexCorrection).pos_column) - data(:,joint_info(5+jointIndexCorrection).pos_column) - data(:,joint_info(6+jointIndexCorrection).pos_column));
            plot([t(1) t(end)], [-366.57/1.71+EXTRA_MARGIN_SHOULDER_INEQ_DEG -366.57/1.71+EXTRA_MARGIN_SHOULDER_INEQ_DEG],'--r');
            plot([t(1) t(end)], [112.42/1.71-EXTRA_MARGIN_SHOULDER_INEQ_DEG 112.42/1.71-EXTRA_MARGIN_SHOULDER_INEQ_DEG],'-.r');
            %legend([joint_info(4+jointIndexCorrection).name ' - ' joint_info(5+jointIndexCorrection).name ' - ' joint_info(6+jointIndexCorrection).name],'lower limit','upper limit');
            title('2nd inequality constraint -  shoulder');
            ylabel('angle (deg)'); 
        hold off;

        subplot(6,1,3);
        hold on;
            plot(t, data(:,joint_info(5+jointIndexCorrection).pos_column) + data(:,joint_info(6+jointIndexCorrection).pos_column));
            plot([t(1) t(end)], [-66.6+EXTRA_MARGIN_SHOULDER_INEQ_DEG -66.6+EXTRA_MARGIN_SHOULDER_INEQ_DEG],'--r');
            plot([t(1) t(end)], [213.3-EXTRA_MARGIN_SHOULDER_INEQ_DEG 213.3-EXTRA_MARGIN_SHOULDER_INEQ_DEG],'-.r');
            %legend([joint_info(5+jointIndexCorrection).name ' - ' joint_info(6+jointIndexCorrection).name],'lower limit','upper limit');
            title('3rd inequality constraint - shoulder');
            ylabel('angle (deg)'); 
        hold off;
        
        joint1_0= 28.0;
        joint1_1= 23.0;
        joint2_0=-37.0;
        joint2_1= 80.0;
        shou_m=(joint1_1-joint1_0)/(joint2_1-joint2_0);
        shou_n=joint1_0-shou_m*joint2_0;

        joint3_0= 85.0;
        joint3_1=105.0;
        joint4_0= 90.0;
        joint4_1= 40.0;
        elb_m=(joint4_1-joint4_0)/(joint3_1-joint3_0);
        elb_n=joint4_0-elb_m*joint3_0;
        
                
        subplot(6,1,4);
        hold on;
            plot(t, data(:,joint_info(5+jointIndexCorrection).pos_column) + -shou_m*data(:,joint_info(6+jointIndexCorrection).pos_column));
            plot([t(1) t(end)], [shou_n+EXTRA_MARGIN_GENERAL_INEQ_DEG shou_n+EXTRA_MARGIN_GENERAL_INEQ_DEG],'--r');
            %legend([joint_info(5+jointIndexCorrection).name ' - ' joint_info(6+jointIndexCorrection).name],'lower limit');
            title('upper arm vs. torso inequality constraint');
            ylabel('angle (deg)'); 
        hold off;

        subplot(6,1,5);
        hold on;
            plot(t, -elb_m*data(:,joint_info(7+jointIndexCorrection).pos_column) + data(:,joint_info(8+jointIndexCorrection).pos_column));
            plot([t(1) t(end)], [elb_n-EXTRA_MARGIN_GENERAL_INEQ_DEG elb_n-EXTRA_MARGIN_GENERAL_INEQ_DEG],'--r');
            %legend([joint_info(7+jointIndexCorrection).name ' - ' joint_info(8+jointIndexCorrection).name],'upper limit');
            title('1st upper arm vs. elbow inequality constraint');
            ylabel('angle (deg)'); 
        hold off;
        
        subplot(6,1,6);
        hold on;
            plot(t, elb_m*data(:,joint_info(7+jointIndexCorrection).pos_column) + data(:,joint_info(8+jointIndexCorrection).pos_column));
            plot([t(1) t(end)], [-elb_n+EXTRA_MARGIN_GENERAL_INEQ_DEG -elb_n+EXTRA_MARGIN_GENERAL_INEQ_DEG],'--r');
            %legend([joint_info(7+jointIndexCorrection).name ' - ' joint_info(8+jointIndexCorrection).name],'lower limit');
            title('2nd upper arm vs. elbow');
            ylabel('angle (deg)'); 
        hold off;
 
        
   if save_figs
       saveas(f14,'output/IneqConstraints.fig');
   end
        
end


%% ipopt stats
if (visualize_ipopt_stats)
   f15 = figure(15); clf(f15); set(f15,'Color','white','Name','Ipopt statistics');  

   subplot(2,1,1);
   hold on;
    title('ipopt exit code');
    plot(t,data(:,ipoptExitCode_col),'or');
   hold off;
   xlabel('time (s)');
   ylim([-5 7]);
   ax = gca;
   set(ax,'YTick',[-4 -3 -2 -1 0 1 2 3 4 5 6]);
   set(ax,'YTickLabel',{'MaximumCpuTimeExceeded','ErrorInStepComputation','RestorationFailed','MaximumIterationsExceeded','SolveSucceeded','SolvedToAcceptableLevel','InfeasibleProblemDetected','SearchDirectionBecomesTooSmall','DivergingIterates','UserRequestedStop','FeasiblePointFound'});
    
    %Solve_Succeeded=0,  Solved_To_Acceptable_Level=1,  Infeasible_Problem_Detected=2,
    %Search_Direction_Becomes_Too_Small=3, Diverging_Iterates=4, User_Requested_Stop=5,
    %Feasible_Point_Found=6,
    %Maximum_Iterations_Exceeded=-1, Restoration_Failed=-2,    Error_In_Step_Computation=-3,
    %Maximum_CpuTime_Exceeded=-4, Not_Enough_Degrees_Of_Freedom=-10, Invalid_Problem_Definition=-11,
    %Invalid_Option=-12,  Invalid_Number_Detected=-13,
    %Unrecoverable_Exception=-100,  NonIpopt_Exception_Thrown=-101,    Insufficient_Memory=-102,
    %Internal_Error=-199
  
   
   subplot(2,1,2);
   hold on;
    title('solver time taken');
    plot(t,data(:,timeToSolve_s_col));
    hold off;
   xlabel('time (s)');
   ylabel('time (s)');
  


   if save_figs
       saveas(f15,'output/ipoptStats.fig');
   end
  
    
end



