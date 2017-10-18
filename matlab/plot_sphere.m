function [ output_args ] = plot_sphere( pos, range )
%UNTITLED19 Summary of this function goes here
%   Detailed explanation goes here
res_angle = 100;

PLOT_NEGATIVE_RF = true;
% TODO
% Add PLOT_NEGATIVE_RF as input
RF = [-.1 .2];
thr = 0.0;
res = 4; % resolution
transparent = 1;

%% INIT

Z_MAX = RF(2); % max extent of RF in z (normal to taxel), meters
Z_NEGATIVE_MAX = RF(1);

APERTURE_DEG = 100; %the spherical sector / cone opening angle or aperture
APERTURE_RAD = (APERTURE_DEG / 360) * 2 * pi;

DESIRED_RADIUS_XY_AT_APEX = 0.07; % 0.05; % meters; we don't want the spherical sector to start at the apex, where it would have 0 volume
%but we want to truncate it such that it starts at the height with this radius;

CONE_HEIGHT_AT_OFFSET = DESIRED_RADIUS_XY_AT_APEX / tan(APERTURE_RAD/2);    % tan(APERTURE_RAD/2) = radius_xy / z_offset; 
%Z_OFFSET = 0;
SPHERE_RADIUS_AT_OFFSET = DESIRED_RADIUS_XY_AT_APEX / sin(APERTURE_RAD/2);    % cos(APERTURE_RAD/2) = radius_xy / sphere_radius;
% here the radius of the sphere will at the same time be used as the
% z-offset - with the radius then equal to cone height + spherical cap height

%% SPHERICAL SECTOR
%polar_angle = linspace(-APERTURE_RAD/2,APERTURE_RAD/2,res); 
azimuth = linspace(0,2*pi,res_angle);
polar_angle = linspace(pi/2-APERTURE_RAD/2,pi/2,res_angle); % in matlab: elevation is angular displacement in radians from the x-y plane
% polar_angle = linspace(pi/2-APERTURE_RAD/2,pi/2+APERTURE_RAD/2,res); % in matlab: elevation is angular displacement in radians from the x-y plane
% also called co-latitude, zenith angle, normal angle, or inclination angle.
[theta,phi] = meshgrid(azimuth,polar_angle);
 
max_radius_z = Z_MAX+CONE_HEIGHT_AT_OFFSET;
radius_z = linspace(SPHERE_RADIUS_AT_OFFSET,max_radius_z,res);

% delta = floor(length(parzenFunc)/length(radius_z));


threshold = thr;
% idxLowerThrd = find(abs(parzenFunc)<=threshold);
% parzenFunc(idxLowerThrd) = 0;


for i=1:length(radius_z)
    [xs,ys,zs] = sph2cart(theta,phi,radius_z(i));
    zs = zs - CONE_HEIGHT_AT_OFFSET;
%     if (delta*i<length(parzenFunc))
        
        h(i) = mesh(xs+pos(1),ys+pos(2),(range)*zs+pos(3));
%     end
end

if PLOT_NEGATIVE_RF
    hold on
    max_radius_z_neg = abs(Z_NEGATIVE_MAX)+CONE_HEIGHT_AT_OFFSET;
    radius_z_neg = linspace(SPHERE_RADIUS_AT_OFFSET,max_radius_z_neg,res);
    for i=1:length(radius_z)
        [xs,ys,zs] = sph2cart(theta,phi,radius_z_neg(i));
        zs = zs - CONE_HEIGHT_AT_OFFSET;
        zs = zs * -1;
        h(i) = mesh(xs+pos(1),ys+pos(2),zs+pos(3));
        set(h(i), 'EdgeColor','none','LineStyle','none', 'FaceAlpha',transparent); %'EdgeAlpha', 0);
    end
    hold off
end

end



