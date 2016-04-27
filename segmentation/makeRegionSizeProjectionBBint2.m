function [L1,L2] = makeRegionSizeProjectionBBint2( mask, props )
% makeRegionSizeProjectionBBint2 : THIS IS EXACTLY THE SAME AS makeRegSize,
% needs to be replaced in the code with that and deleted!
%
% INPUT :
%       mask : masked region of interest
%       props : contains information about the orientation of the region
% OUTPUT:
%       L1 : projection length of region on the major axis
%       L2 : projection length of region on the minor axis
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti

imRot = logical(fast_rotate_loose( uint8(mask), -props.Orientation+90 ));
L1 = max(sum(imRot));
L2 = max(sum(imRot,2));

end