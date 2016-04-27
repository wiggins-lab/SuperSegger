function [xx,yy] = getBBpad( bb1,ss,pad )
% getBB : coordinates of bounding box with extra 'pad' pixels along x & y.
%
% INPUT :
%       bb1: bounding box [x, y, width, height]
%       ss : size of the phase image
%       pad :  pixels to be added right,left, above and below of the bounding box
% OUTPUT :
%       xx : array from start to end of bounding box along x
%       yy : array from start to end of bounding box along y
%
% Copyright (C) 2016 Wiggins Labs
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

ymin = ceil(bb1(2))-pad;
xmin = ceil(bb1(1))-pad;
ymax = ymin+floor(bb1(4))+2*pad-1;
xmax = xmin+floor(bb1(3))+2*pad-1;

yy = max([1,ymin]):min([ymax,ss(1)]);
xx = max([1,xmin]):min([xmax,ss(2)]);

end