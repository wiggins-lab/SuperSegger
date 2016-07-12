function seg_info = segInfoResCurvNoD(segs_props, segs_props_tmp, regs_prop, regs_label,disk1, pixelFactor)
% segInfoL2 : Calculates the properties of the segments used for segment scoring.
%
% INPUT :
%   segs_props : calculated segment properties
%   segs_props_tmp : calculated segment properties tmp
%   regs_prop : region properties
%   regs_label : region labels
%   disk1 : disk for dilating/eroding
% OUTPUT :
%   seg_info : array with parameters used for segment scoring
%
% Copyright (C) 2016 Wiggins Lab
% Written by Paul Wiggins & Stella Stylianidou.
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

phase_im = segs_props_tmp.phaseC2;
nn = segs_props.Area;
seg_mask = segs_props_tmp.mask;
seg_mask = imdilate(seg_mask,disk1);

% mask_ii_out are the pixels around the segment so that a second d over
% the segment can be computed.

% seg_info(:,1) is the minimum phase intensity on the seg
[seg_info(1),~] = min(phase_im(:).*double(seg_mask(:))+1e6*double(~seg_mask(:)));

% seg_info(:,2) is the mean phase intensity on the seg
seg_info(2) = mean(phase_im(seg_mask));

% seg_info(:,3) is area of the seg
seg_info(3) = nn * pixelFactor;

% We also wish to add information about the neighboring regions. First we
% have to determine what these regions are... ie the regs_label number
% By construction, each seg touches two regions. Ind_reg is the vector
% of the region indexes--after we eliminate '0'.
uu = segs_props_tmp.regs_label(imdilate( seg_mask, disk1));
ind_reg = unique(uu(logical(uu)));

% min and max area of the neighboring regions
seg_info(4)  = min([regs_prop(ind_reg(:)).Area]) * pixelFactor^2;
seg_info(5)  = max([regs_prop(ind_reg(:)).Area]) * pixelFactor^2;

% min and max major axis length of the segment itsel
seg_info(6) = segs_props.MinorAxisLength * pixelFactor;
seg_info(7) = segs_props.MajorAxisLength * pixelFactor;


% Get size of the regions in local coords

% This function computes the principal axes of the segment
% mask. e1 is aligned with the major axis and e2 with the
% minor axis and com is the center of mass.
[e1,e2] = makeRegionAxisFast( segs_props.Orientation );


% Loop through the two regions


% put in the curvatures
Cmaj = e1(1).^2.*segs_props.f_xx + 2*e1(1).*e1(2).*segs_props.f_xy + e1(2).^2.*segs_props.f_yy;
Cmin = e2(1).^2.*segs_props.f_xx + 2*e2(1).*e2(2).*segs_props.f_xy + e2(2).^2.*segs_props.f_yy;
seg_info(8) = segs_props.C2;

seg_info(9) = Cmaj;
seg_info(10) = Cmin;

seg_info(11) = segs_props.C1;
seg_info(12) = segs_props.G;
seg_info(13) = segs_props.G_;


end
