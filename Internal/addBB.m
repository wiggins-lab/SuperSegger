function bbResult = addBB( bb1, bb2 )
% addBB : creates a bounding box from the addition of two bounding boxes
%
% INPUT : 
%       bb1 : bounding box 1 
%       bb2 : bounding box 2
% OUTPUT :
%       bb : resulting bounding box
%
% Copyright (C) 2016 Wiggins Lab
% Unviersity of Washington, 2016
% This file is part of SuperSeggerOpti.


ymin = min([bb1(2),bb2(2)]);
xmin = min([bb1(1),bb2(1)]);
ymax = max([bb1(2)+bb1(4),bb2(2)+bb2(4)]);
xmax = max([bb1(1)+bb1(3),bb2(1)+bb2(3)]);

bbResult = [xmin, ymin, xmax-xmin, ymax-ymin];

end