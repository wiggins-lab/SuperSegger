function seg_info = segsInfoCurv(segs_props, segs_props_tmp, regs_prop, regs_label,disk1)
% segsInfoCurv : Calculates the properties of the segments used for segment scoring.
% Uses the image curvature to calculate some of the properties.
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


nn = segs_props.Area;
sim_ii = size(segs_props_tmp.phase);
% mask_ii_out are the pixels around the segment so that a second d over
% the segment can be computed.
if nn>2
    mask_ii_end  = (compConn(segs_props_tmp.mask,4)==1);
    mask_ii_out  = xor(bwmorph( xor(segs_props_tmp.mask,mask_ii_end), 'dilate' ),segs_props_tmp.mask);
elseif nn == 1
    mask_ii_out  = xor(bwmorph( segs_props_tmp.mask, 'dilate'),segs_props_tmp.mask);
else
    mask_ii_out  = imdilate( segs_props_tmp.mask, disk1)-segs_props_tmp.mask;
    mask_ii_out  = and(mask_ii_out,(compConn(mask_ii_out,4)>0));
end

% seg_info(:,1) is the minimum phase intensity on the seg
[seg_info(1),ind] = min(segs_props_tmp.phase(:).*double(segs_props_tmp.mask(:))+1e6*double(~segs_props_tmp.mask(:)));

% seg_info(:,2) is the mean phase intensity on the seg
seg_info(2) = mean(segs_props_tmp.phase(segs_props_tmp.mask));

% seg_info(:,3) is area of the seg
seg_info(3) = nn;

% seg_info(:,4) is the mean second d of the phase normal to the seg
seg_info(4) = mean(segs_props_tmp.phase(mask_ii_out)) - seg_info(2);

% next we want to do some more calculation around the minimum phase
% pixel. sub1 and sub2 are the indicies in the cropped image
[sub1,sub2] = ind2sub(sim_ii,ind);
% sub1_ and sub2_ are the indices in the whole image.
%     sub1_ = sub1-1+yymin;
%     sub2_ = sub2-1+xxmin;

% calculate the local second d of the phase at the min pixel
% normal to the seg and parallel to it.
% min_pixel is the mask of the min pixel
min_pixel = false(sim_ii);
min_pixel(sub1,sub2) = true;
% outline the min pixel
min_pixel_out = bwmorph( min_pixel, 'dilate');
% and mask/anti-mask it
ii_min_para   = and(min_pixel_out,segs_props_tmp.mask);
ii_min_norm   = xor(min_pixel_out,ii_min_para);

% seg_info(:,5) is the second d of the phase normal to the seg at the
% min pixel
seg_info(5) = mean(segs_props_tmp.phase(ii_min_norm))-mean(segs_props_tmp.phase(ii_min_para));

% seg_info(:,6) is the second d of the phase parallel to the seg at the
% min pixel
tmp_mask = xor(ii_min_para,min_pixel);
seg_info(6) = mean(segs_props_tmp.phase(tmp_mask))-seg_info(1);

if isnan(seg_info(6))
    disp([header,'NaN in seg_info!']);
end

% We also wish to add information about the neighboring regions. First we
% have to determine what these regions are... ie the regs_label number
% By construction, each seg touches two regions. Ind_reg is the vector
% of the region indexes--after we eliminate '0'.
uu = segs_props_tmp.regs_label(imdilate( segs_props_tmp.mask, disk1));
ind_reg = unique(uu(logical(uu)));

% seg_info(:,7) and seg_info(:,8) are the min and max area of the
% neighboring regions
seg_info(7)  = min( regs_prop(ind_reg(:)).Area);
seg_info(8)  = max( regs_prop(ind_reg(:)).Area);

% seg_info(:,9) and seg_info(:,10) are the min and max minor axis
% length of the neighboring regions
seg_info(9)  = min( regs_prop(ind_reg(:)).MinorAxisLength);
seg_info(10) = max( regs_prop(ind_reg(:)).MinorAxisLength);

% seg_info(:,11) and seg_info(:,12) are the min and max major axis
% length of the neighboring regions
seg_info(11) = min( regs_prop(ind_reg(:)).MajorAxisLength);
seg_info(12) = max( regs_prop(ind_reg(:)).MajorAxisLength);

% seg_info(:,11), seg_info(:,12), and seg_info(:,13) are the min
% and max major axis length of the segment itself, including the
% square of the major axis length... which would allow a non-
% linarity in the length cutoff. No evidence that this helps...
% just added it because I could.
seg_info(13) = segs_props.MinorAxisLength;
seg_info(14) = segs_props.MajorAxisLength;
seg_info(15) = segs_props.MajorAxisLength^2;


% Next we want to do some calculation looking at the size of
% the regions, normal and parallel to the direction of the
% segment. This is a bit computationally expensive, but worth
% it I think.

% Get size of the regions in local coords

% This function computes the principal axes of the segment
% mask. e1 is aligned with the major axis and e2 with the
% minor axis and com is the center of mass.
[e1,e2] = makeRegionAxisFast( segs_props.Orientation );

% L1 is the length of the projection of the region on the
% major axis and L2 is the lenght of the projection on the
% minor axis.
L1 = [0 0];
L2 = [0 0];

% Loop through the two regions


for kk = 1:numel(ind_reg);
    % get a new cropping region for each region with 2 pix padding
    [xx_,yy_] = getBBpad(regs_prop(ind_reg(kk)).BoundingBox,segs_props_tmp.sim,2);
    
    % mask the region of interest
    kk_mask = (regs_label(yy_, xx_) == ind_reg(kk));
    
    % This function computes the projections lengths on e1 and e2.
    [L1(kk),L2(kk)] = makeRegionSize( kk_mask,e1,e2);
end

% seg_info(:,16) and seg_info(:,17) are the min and max Length of the
% regions projected onto the major axis of the segment.
seg_info(16) = max(L1); % max and min region length para to seg
seg_info(17) = min(L1);
% seg_info(:,16) and seg_info(:,17) are the min and max Length of the
% regions projected onto the minor axis of the segment.
seg_info(18) = max(L2); % max and min region length normal to seg
seg_info(19) = min(L2);

% put in the curvatures
Cmaj = e1(1).^2.*segs_props.f_xx + 2*e1(1).*e1(2).*segs_props.f_xy + e1(2).^2.*segs_props.f_yy;
Cmin = e2(1).^2.*segs_props.f_xx + 2*e2(1).*e2(2).*segs_props.f_xy + e2(2).^2.*segs_props.f_yy;

seg_info(20) = segs_props.G;
seg_info(21) = segs_props.G_;

seg_info(22) = Cmaj;
seg_info(23) = Cmin;

seg_info(24) = segs_props.C1;
seg_info(25) = segs_props.C2;


end
