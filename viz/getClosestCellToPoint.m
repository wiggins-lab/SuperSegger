function [region_id,x_point,y_point] = getClosestCellToPoint(data,point)
% getClosestCellToPoint : Returns the closest region_id in the data to the 
% input point.
%
% Copyright (C) 2016 Wiggins Lab
% Written by Stella Stylianidou & Paul Wiggins.
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

point = round(point);
ss = size(data.phase);

% Creates a square around point that fades away
tmp = zeros([51,51]);
tmp(26,26) = 1;
tmp = 8000-double(bwdist(tmp));
rmin = max([1,point(2)-25]);
rmax = min([ss(1),point(2)+25]);
cmin = max([1,point(1)-25]);
cmax = min([ss(2),point(1)+25]);
rrind = rmin:rmax;
ccind = cmin:cmax;
pointSize = [numel(rrind),numel(ccind)];

% Multiplies by cell mask
tmp = tmp(26-point(2)+rrind,26-point(1)+ccind).*data.mask_cell(rrind,ccind);

% Finds maximum value of faded-point & cell mask
[~,ind] = max(tmp(:));
[sub1, sub2] = ind2sub(pointSize, ind);
% Label of the region (cell) for the maximum value.
region_id = data.regs.regs_label(sub1-1+rmin,sub2-1+cmin);
x_point = sub2-1+cmin;
y_point = sub1-1+rmin;
end