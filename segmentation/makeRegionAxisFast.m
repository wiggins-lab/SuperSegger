function [e1,e2] = makeRegionAxisFast( angle_deg )
% makeRegionAxis : calculates the principal axis of the segment mask.
%
% INPUT :
%       angle_deg : orientation of segment
% OUTPUT :
%       e1 : aligned with the major axis
%       e2 : aligned with the minor axis 
%
%
% Copyright (C) 2016 Wiggins Lab 
% Written by Paul Wiggins.
% University of Washington, 2016
% This file is part of SuperSegger.
% 
% SuperSegger is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% SuperSegger is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with SuperSegger.  If not, see <http://www.gnu.org/licenses/>.

theta = -(180+angle_deg)*pi/180;
e1   = [ cos(theta), sin(theta)];
e2   = [-sin(theta), cos(theta)];

end