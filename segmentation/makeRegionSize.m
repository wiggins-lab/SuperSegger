function [L1,L2] = makeRegionSize( mask,e1,e2 )
% makeRegionSize : computes the projections lengths on the principal axis.
% 
% INPUT :
%       mask : masked region of interest
%       e1 : orientation of major axis
%       e2 : oreintation of minor axis
% OUTPUT:
%       L1 : projection length of region on the major axis
%       L2 : projection length of region on the minor axis
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

mask = ~~mask;

im_size = size(mask);
im_size_x = im_size(2);
im_size_y = im_size(1);

xxx = 1:im_size_x;
yyy = 1:im_size_y;

[X,Y] = meshgrid( xxx, yyy );

Xp = (-(X(mask))*e1(2)+(Y(mask))*e1(1));
Yp = (-(X(mask))*e2(2)+(Y(mask))*e2(1));

XPmax = max(Xp);
YPmax = max(Yp);
XPmin = min(Xp);
YPmin = min(Yp);

L2 = XPmax-XPmin;
L1 = YPmax-YPmin;

end