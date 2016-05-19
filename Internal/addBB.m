function bbResult = addBB( bb1, bb2 )
% addBB : creates a bounding box from the addition of two bounding boxes
%
% INPUT : 
%       bb1 : bounding box 1 
%       bb2 : bounding box 2
% OUTPUT :
%       bb : resulting bounding box
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

if isempty(bb1)
    bbResult = bb2;
elseif isempty (bb2)
    bbResult = bb1;
else
    ymin = min([bb1(2),bb2(2)]);
    xmin = min([bb1(1),bb2(1)]);
    ymax = max([bb1(2)+bb1(4),bb2(2)+bb2(4)]);
    xmax = max([bb1(1)+bb1(3),bb2(1)+bb2(3)]);    
    bbResult = [xmin, ymin, xmax-xmin, ymax-ymin];
end

end