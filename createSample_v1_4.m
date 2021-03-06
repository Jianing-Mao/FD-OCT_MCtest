% Create the files for the simulation
   
clear
format compact
clc
home

%File location
% cd('C:\Users\raphi\Documents\ubuntu_share')

%%% USER CHOICES %%%%%%%% <-------- You must set these parameters ------
SAVEON      = 1;        % 1 = save myname_T.bin, myname_H.mci 
                        % 0 = don't save. Just check the program.

myname      = '5ag05Short';% name for files: myname_T.bin, myname_H.mci  
time_min    = 1440;      	% time duration of the simulation [min] <----- run time -----
Nx          = 200;    	% # of bins in each dimension of cube 
Ny          = 200;    	% # of bins in each dimension of cube 
Nz          = 200;    	% # of bins in each dimension of cube 
binsize     = 0.0005;     	% size of each bin, eg. [cm]

% Set Monte Carlo launch flags (not in use)
mcflag      = 0;     	% launch: 0 = uniform beam, 1 = Gaussian, 2 = isotropic pt. 
                        % 3 = rectangular beam (use xfocus,yfocus for x,y halfwidths)
launchflag  = 1;        % 0 = let mcxyz.c calculate launch trajectory
                        % 1 = manually set launch vector.
boundaryflag = 1;       % 0 = no boundaries, 1 = escape at boundaries
                        % 2 = escape at surface only. No x, y, bottom z
                        % boundaries

% Sets position of source with 0 centered on each Aline
xs          = 0;      	% x of source
ys          = 0;        % y of source
zs          = 0.0001; % z of source must start in simulation

% Set position of focus, so mcxyz can calculate launch trajectory (not in use)
xfocus      = 0;        % set x,position of focus
yfocus      = 0;        % set y,position of focus
zfocus      = inf;    	% set z,position of focus (=inf for collimated beam)

% Set detection parameter
radius      = 0.05;     % Half width of the BScan
waist       = 0.03;  	% Width of the scanned beam (Not in use)
Ndetectors  = 512;      % Number of Aline per BScan
flens       = 0.06;        %Focal lens in m 0.01 or 0.06
beamw       = 0.002;        %Beam diameter at imaging lens in m
det_radius  = 1310e-7*2/pi/atan(beamw/2/flens);    % Width of the beam at the imaging lens
nm = 1310;
cos_accept  = cos(atan(beamw/2/flens)); % Cos of the accepted angle

% only used if launchflag == 1 (manually set launch trajectory): (not in use)
ux0         = 0;      % trajectory projected onto x axis
uy0         = 0;      % trajectory projected onto y axis
uz0         = sqrt(1 - ux0^2 - uy0^2); % such that ux^2 + uy^2 + uz^2 = 1

% Bias scattering parameter
a_coef    = 0.5;
p         = 0.5;
dx = binsize;
dy = binsize;
dz = binsize;
%%%%%%%%%%%%%%%%%%%%%%%%%

% Specify Monte Carlo parameters    
x  = ([0:Nx]'-Nx/2)*dx;
y  = ([0:Ny]'-Ny/2)*dy;
z  = [0:Nz]'*dz;
zmin = min(z);
zmax = max(z);
xmin = min(x);
xmax = max(x);
%%%%%%%%%%%%
% Create Sample
%%%
tissue = make_TissueList_original(nm); % also --> global tissue(1:Nt).s
Nt = length(tissue);
for i=1:Nt
    muav(i)  = tissue(i).mua;
    musv(i)  = tissue(i).mus;
    gv(i)    = tissue(i).g;
    nrv(i)   = 1.4;
end
T = double(zeros(Ny,Nx,Nz)); 

T = T + 2;      % fill background with skin (dermis)

zsurf = 0.0100;  % position of air/skin surface

for iz=1:Nz % for every depth z(iz)

    % air
    if iz<=round(zsurf/dz)
        T(:,:,iz) = 2; 
    end

%     epidermis (60 um thick)
    if iz>round(zsurf/dz) & iz<=round((zsurf+0.0060)/dz)
        T(:,:,iz) = 4; 
    end
    if iz>round(zsurf*4/dz) & iz<=round((zsurf*4+0.0060)/dz)
        T(:,:,iz) = 4; 
    end
    if iz>round(zsurf*5/dz) & iz<=round((zsurf*5+0.0060)/dz)
        T(:,:,iz) = 4; 
    end

%     % blood vessel @ xc, zc, radius, oriented along y axis
%     xc      = 0;            % [cm], center of blood vessel
%     zc      = Nz/2*dz;     	% [cm], center of blood vessel
%     vesselradius  = 0.0100;      	% blood vessel radius [cm]
%     for ix=1:Nx
%             xd = x(ix) - xc;	% vessel, x distance from vessel center
%             zd = z(iz) - zc;   	% vessel, z distance from vessel center                
%             r  = sqrt(xd^2 + zd^2);	% r from vessel center
%             if (r<=vesselradius)     	% if r is within vessel
%                 T(:,ix,iz) =3; % blood
%             end
% 
%     end %ix
%      xc      = 0;            % [cm], center of blood vessel
%     zc      = Nz/2*dz;     	% [cm], center of blood vessel
%     vesselradius  = 0.0100;      	% blood vessel radius [cm]
%     for ix=1:Nx
%             xd = x(ix) - xc;	% vessel, x distance from vessel center
%             zd = z(iz) - zc;   	% vessel, z distance from vessel center                
%             r  = sqrt((xd-0.02)^2 + zd^2);	% r from vessel center
%             if (r<=vesselradius)     	% if r is within vessel
%                 T(:,ix,iz) =4; % blood
%             end
% 
%     end %ix
%      xc      = 0;            % [cm], center of blood vessel
%     zc      = Nz/2*dz;     	% [cm], center of blood vessel
%     vesselradius  = 0.0100;      	% blood vessel radius [cm]
%     for ix=1:Nx
%             xd = x(ix) - xc;	% vessel, x distance from vessel center
%             zd = z(iz) - zc;   	% vessel, z distance from vessel center                
%             r  = sqrt((xd+0.02)^2 + zd^2);	% r from vessel center
%             if (r<=vesselradius)     	% if r is within vessel
%                 T(:,ix,iz) =5; % blood
%             end
% 
%     end %ix
%     
end % iz

%%%%%%%%%% 
% Prepare Monte Carlo 
%%%

if isinf(zfocus), zfocus = 1e12; end



%%
if SAVEON
    tic
    % convert T to linear array of integer values, v(i)i = 0;
    v = uint8(reshape(T,Ny*Nx*Nz,1));

    %% WRITE FILES
    % Write myname_H.mci file
    %   which contains the Monte Carlo simulation parameters
    %   and specifies the tissue optical properties for each tissue type.
    commandwindow
    disp(sprintf('--------create %s --------',myname))
    filename = sprintf('%s_H.mci',myname);
    fid = fopen(filename,'w');
        % run parameters
        fprintf(fid,'%0.2f\n',time_min);
        fprintf(fid,'%0.4f\n',a_coef);
        fprintf(fid,'%0.4f\n',p);
        fprintf(fid,'%0.4f\n',Ndetectors);
        fprintf(fid,'%0.6f\n',det_radius);
        fprintf(fid,'%0.6f\n',cos_accept);
        fprintf(fid,'%d\n'   ,Nx);
        fprintf(fid,'%d\n'   ,Ny);
        fprintf(fid,'%d\n'   ,Nz);
        fprintf(fid,'%0.4f\n',dx);
        fprintf(fid,'%0.4f\n',dy);
        fprintf(fid,'%0.4f\n',dz);
        % launch parameters
        fprintf(fid,'%d\n'   ,mcflag);
        fprintf(fid,'%d\n'   ,launchflag);
        fprintf(fid,'%d\n'   ,boundaryflag);
        fprintf(fid,'%0.4f\n',xs);
        fprintf(fid,'%0.4f\n',ys);
        fprintf(fid,'%0.4f\n',zs);
        fprintf(fid,'%0.4f\n',xfocus);
        fprintf(fid,'%0.4f\n',yfocus);
        fprintf(fid,'%0.4f\n',zfocus);
        fprintf(fid,'%0.4f\n',ux0); % if manually setting ux,uy,uz
        fprintf(fid,'%0.4f\n',uy0);
        fprintf(fid,'%0.4f\n',uz0);
        fprintf(fid,'%0.4f\n',radius);
        fprintf(fid,'%0.4f\n',waist);
        fprintf(fid,'%0.4f\n',zsurf);
        % tissue optical properties
        fprintf(fid,'%d\n',Nt);
        for i=1:Nt
            fprintf(fid,'%0.6f\n',muav(i));
            fprintf(fid,'%0.6f\n',musv(i));
            fprintf(fid,'%0.6f\n',gv(i));
            fprintf(fid,'%0.6f\n',nrv(i));
        end
    fclose(fid);

    %% write myname_T.bin file
    filename = sprintf('%s_T.bin',myname);
    disp(['create ' filename])
    fid = fopen(filename,'wb');
    fwrite(fid,v,'uint8');
    fclose(fid);

    toc
end % SAVEON

%% Look at structure of Tzx at iy=Ny/2
Txzy = shiftdim(T,1);   % Tyxz --> Txzy
Tzx  = Txzy(:,:,Ny/2)'; % Tzx

%%
figure(1); clf
sz = 12;  fz = 10; 
imagesc(x,z,Tzx,[1 Nt])
hold on
set(gca,'fontsize',sz)
xlabel('x [cm]')
ylabel('z [cm]')
title('\rm Tissue')
colorbar
cmap = makecmap(Nt);
colormap(cmap)
set(colorbar,'fontsize',1)
% label colorbar
zdiff = zmax-zmin;
%%%

for i=1:Nt
    yy = (Nt-i)/(Nt-1)*Nz*dz;
    text(max(x)*1.2,yy, tissue(i).name,'fontsize',fz)
end

text(xmax,zmin - zdiff*0.06, 'Tissue types','fontsize',fz)
axis equal image
axis([xmin xmax zmin zmax])

%%% draw launch
N = 20; % # of beam rays drawn
switch mcflag
    case 0 % uniform
        for i=0:N
            plot((-radius + 2*radius*i/N)*[1 1],[zs max(z)],'r-')
        end

    case 1 % Gaussian
        for i=0:N
            plot([(-radius + 2*radius*i/N) xfocus],[zs zfocus],'r-')
        end

    case 2 % iso-point
        for i=1:N
            th = (i-1)/19*2*pi;
            xx = Nx/2*cos(th) + xs;
            zz = Nx/2*sin(th) + zs;
            plot([xs xx],[zs zz],'r-')
        end
        
    case 3 % rectangle
        zz = max(z);
        for i=1:N
            xx = -radius + 2*radius*i/20;
            plot([xx xx],[zs zz],'r-')
        end
end
savefig(strcat(myname, '.fig'));
disp('done')

