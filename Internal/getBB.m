function [xx,yy] = getBB( bb1 );
% getBB : coordinates from start to end of bounding box
% along the x and y axis
%
% INPUT :
%       bb1: bounding box [x, y, width, height]
% OUTPUT :
%       xx : array from start to end of bounding box along x
%       yy : array from start to end of bounding box along y
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

ymin = ceil(bb1(2));
xmin = ceil(bb1(1));
ymax = ymin+floor(bb1(4))-1;
xmax = xmin+floor(bb1(3))-1;

yy = ymin:ymax;
xx = xmin:xmax;

end