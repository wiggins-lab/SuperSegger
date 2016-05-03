function [xx,yy] = getBB( bb1 )
% getBB : coordinates from start to end of bounding box
% along the x and y axis
%
% INPUT :
%       bb1: bounding box [x, y, width, height]
% OUTPUT :
%       xx : array from start to end of bounding box along x
%       yy : array from start to end of bounding box along y

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

ymin = ceil(bb1(2));
xmin = ceil(bb1(1));
ymax = ymin+floor(bb1(4))-1;
xmax = xmin+floor(bb1(3))-1;

yy = ymin:ymax;
xx = xmin:xmax;

end