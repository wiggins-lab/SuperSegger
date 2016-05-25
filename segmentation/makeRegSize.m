function [L1,L2] = makeRegSize( mask, props )
% makeRegSize : computes the projections lengths after rotating.
% The mask is rotated by the angle in props.Orientation. 
%
% INPUT :
%       mask : masked region of interest
%       props : contains information about the orientation of the region
% OUTPUT:
%       L1 : projection length of region on the major axis
%       L2 : projection length of region on the minor axis
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

imRot = logical(fast_rotate_loose(uint8(mask), -props.Orientation+90 ));
L1 = max(sum(imRot));
L2 = max(sum(imRot,2));

end