function [L1,L2] = makeRegSize( mask, props )
% makeRegSize : computes the projections lengths after rotating.
% The mask is rotated by props.Orientation. 
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