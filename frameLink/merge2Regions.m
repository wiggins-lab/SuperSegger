function [data_c] = merge2Regions (data_c, reg1, reg2)
% merge2Regions : merges reg1 and reg2 into one in the mask_cell
% regions need to be remade after this in order to have the right
% properties.
%
% INPUT :
%       data_c : data file (err/seg file)
%       reg1 : region 1 number
%       reg2 : region 2 number
% OUTPUT : 
%       data_c : data file with merged regions
%       success :
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
% 
% You should have received a copy of the GNU General Public License
% along with SuperSegger.  If not, see <http://www.gnu.org/licenses/>.


mask1 = (data_c.regs.regs_label == reg1);
mask2 = (data_c.regs.regs_label == reg2);
masksum = (mask1+mask2);
masksum_  = imdilate(masksum,strel('square',3));
masksum__  = imerode(masksum_,strel('square',3));

segsInMask = data_c.segs.segs_label;
segsInMask(~masksum__) = 0;
segsInMask = logical(segsInMask);
data_c.segs.segs_good(segsInMask) = 0;
data_c.segs.segs_bad(segsInMask) = 1;
data_c.mask_cell = double((data_c.mask_cell + segsInMask)>0);


end