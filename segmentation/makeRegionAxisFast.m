function [e1,e2] = makeRegionAxisFast( angle_deg )
% makeRegionAxis : calculates the principal axis of the segment mask.
%
% INPUT :
%       angle_deg : orientation of segment
% OUTPUT :
%       e1 : aligned with the major axis
%       e2 : aligned with the minor axis 
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti

theta = -(180+angle_deg)*pi/180;
e1   = [ cos(theta), sin(theta)];
e2   = [-sin(theta), cos(theta)];

end