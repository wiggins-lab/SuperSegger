function [data_c,resetRegions] = merge2Regions (data_c, list_merge, CONST)
% merge2Regions : merges reg1 and reg2 into one in the mask_cell
% regions need to be remade after this in order to have the right
% properties.
% INPUT :
%      data_c : current data (seg/err) file.
%      reg1 : id of region 1
%      reg2 : id of region 2 
%      CONST : segmentation parameters
%
% OUTPUT :
%      data_c : data_c with merged regions
%      resetRegions : true if regions were merged and linking should
%      re-run.
%
% Copyright (C) 2016 Wiggins Lab
% Written by Stella Stylianidou, Paul Wiggins.
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




masksum = 0*data_c.regs.regs_label;

for i = 1 : numel(list_merge)
    mask1 = (data_c.regs.regs_label == list_merge(i));
    masksum = (masksum+mask1);
end
masksum_  = imdilate(masksum,strel('square',3));
masksum__  = imerode(masksum_,strel('square',3));

labels =  bwlabel(masksum__);
if max(labels(:)) == 1
    segsInMask = data_c.segs.segs_label;
    segsInMask(~masksum__) = 0;
    segsInMask = logical(segsInMask);
    data_c.segs.segs_good(segsInMask) = 0;
    data_c.segs.segs_bad(segsInMask) = 1;
    data_c.mask_cell = double((data_c.mask_cell + masksum__)>0);
    resetRegions = true;
else
    resetRegions = false;
end


end