function celld = toMakeCellFast(celld, e1_old, props)
% toMakeCellFast : calculates all the properties of the cell.
% This includes center (center of mass) as well as the principle axis which
% is assumed to be the axis that diagonizes the moment of inertia tensor.
% This gives the axis up to a sign, which is determined by aligning the
% current axis with the last axis (e1_old).
% The properties added to celld are the following :
%         lenght : length of cell
%         coord,A: Area of cell mask
%         coord.r_center: geometrical center of the cell
%         coord.box: coordinated of box surrounding cell
%         corrd.xaxis: coord of major axis
%         coord.yaxis:  coord of minor axis
%         coord.e1: priniple axis (major) unit vector
%         coord.e2: priniple axis (minor) unit vector
%         coord.rcm: center of mass position of mask
%
% INPUT :
%       celld : Cell file
%       props : contains information about the cell such as bounding box, area,
%       and centroid
%       e1_old : is the last axis of the cell
% OUTPUT : 
%       celld : new cell file with calculated properties
%
% Copyright (C) 2016 Wiggins Lab
% Unviersity of Washington, 2016
% This file is part of SuperSeggerOpti.

theta = (-props.Orientation)*pi/180;
A     = props.Area;
mask  = logical(celld.mask);

imRot   = (fast_rotate_loose_double( uint8(mask), -props.Orientation ));
ss      = size(imRot);
ss_mask = size(mask);

xind = any(imRot);
yind = any(imRot');

len = [sum(double(xind)),sum(double(yind))];

xxx = (1:ss(2));
yyy = (1:ss(1));

e1   = [ cos(theta); sin(theta)];
e2   = [-sin(theta); cos(theta)];
Mrot = [e1,e2];

% center of mass for cell
r_center = Mrot*([mean(xxx(xind)),mean(yyy(yind))]'-(ss(2:-1:1))'/2)+...
    (ss_mask(2:-1:1)/2+celld.r_offset-[0.5,0.5])';
Xcm      = props.Centroid(1);
Ycm      = props.Centroid(2);
rcm      = [Xcm,Ycm];

if ~isempty( e1_old );
    if sum(e1.*e1_old) < 0
        e1 = -e1;
    end
end

if sum(e1(1)*e2(2)-e1(2)*e2(1)) < 0
    e2 = -e2;
end

XPmax = r_center(1) + len(1);
YPmax = r_center(2) + len(2);
XPmin = r_center(1) - len(1);
YPmin = r_center(2) - len(2);

% draw a box around the cell
xbox = ...
    [ e1(1)*len(1)+e2(1)*len(2),...
    -e1(1)*len(1)+e2(1)*len(2),...
    -e1(1)*len(1)-e2(1)*len(2),...
    e1(1)*len(1)-e2(1)*len(2),...
    e1(1)*len(1)+e2(1)*len(2)]/2 + r_center(1);

ybox = ...
    [ e1(2)*len(1)+e2(2)*len(2),...
    -e1(2)*len(1)+e2(2)*len(2),...
    -e1(2)*len(1)-e2(2)*len(2),...
    e1(2)*len(1)-e2(2)*len(2),...
    e1(2)*len(1)+e2(2)*len(2)]/2 + r_center(2);

% draw the axes inside the cell. (useful for debugging)
xaxisx = ...
    [ e1(1)*len(1),...
    -e1(1)*len(1)]/2 + r_center(1);
xaxisy = ...
    [ e1(2)*len(1),...
    -e1(2)*len(1)]/2 + r_center(2);
yaxisx = ...
    [ e2(1)*len(2),...
    -e2(1)*len(2)]/2 + r_center(1);
yaxisy = ...
    [ e2(2)*len(2),...
    -e2(2)*len(2)]/2 + r_center(2);

xaxisxp = ...
    [ e1(1)*len(1),...
    0]/2 + r_center(1);
xaxisyp = ...
    [ e1(2)*len(1),...
    0]/2 + r_center(2);
yaxisxp = ...
    [ e2(1)*len(2),...
    0]/2 + r_center(1);
yaxisyp = ...
    [ e2(2)*len(2),...
    0]/2 + r_center(2);


% copy all the info into the cell structure.

celld.length         = len;
celld.coord.A        = A;
celld.coord.r_center = r_center;
celld.coord.box     = [xbox',ybox'];
celld.coord.xaxis   = [xaxisx',xaxisy'];
celld.coord.yaxis   = [yaxisx',yaxisy'];
celld.coord.e1       = e1;
celld.coord.e2       = e2;
celld.coord.rcm      = rcm;
celld.pole.e1        = e1;
celld.pole.op_ori    = 0;
celld.pole.op_age    = NaN;
celld.pole.np_age    = NaN;

% Debugging info.
debug_flag = 0;

if debug_flag;
    
    im_size   = size(mask);
    im_size_x = im_size(2);
    im_size_y = im_size(1);
    
    xx = 1:im_size_x;
    yy = 1:im_size_y;
        
    xxx = xx + celld.r_offset(1)-1;
    yyy = yy + celld.r_offset(2)-1;
    
    clf;
    imagesc( xxx,yyy,ag(mask));
    axis equal
    
    colormap gray
    hold on;
    %    plot( r(1), r(2), 'bo');
    plot( celld.coord.rcm(1), celld.coord.rcm(2), 'c.');
    plot( celld.coord.r_center(1), celld.coord.r_center(2), 'c*');
    plot( celld.coord.xaxis(:,1),celld.coord.xaxis(:,2),'c:')
    plot( celld.coord.yaxis(:,1),celld.coord.yaxis(:,2),'c:')
    plot( xaxisxp, xaxisyp,'c-')
    plot( yaxisxp, yaxisyp,'c-')
    plot( celld.r_offset(1), celld.r_offset(2),'co')
    plot( celld.coord.box(:,1), celld.coord.box(:,2),'c-')
end


end