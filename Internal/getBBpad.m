function [xx,yy] = getBBpad( bb1,ss,pad );
% getBB : coordinates from start to end of bounding box with padding
% along the x and y axis
%
% INPUT :
%       bb1: bounding box [x, y, width, height]
%       ss : size of the phase image
%       pad :  padding to be added around bounding box
% OUTPUT :
%       xx : array from start to end of bounding box along x
%       yy : array from start to end of bounding box along y
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

ymin = ceil(bb1(2))-pad;
xmin = ceil(bb1(1))-pad;
ymax = ymin+floor(bb1(4))+2*pad-1;
xmax = xmin+floor(bb1(3))+2*pad-1;

yy = max([1,ymin]):min([ymax,ss(1)]);
xx = max([1,xmin]):min([xmax,ss(2)]);

end