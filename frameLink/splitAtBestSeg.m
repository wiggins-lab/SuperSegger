function [data_c, success] = splitAtBestSeg (data_c, regC, CONST)
% missingSeg2to1 : finds missing segment in regC.
% Segments in regC are used that are close to the segment
% between the two regions regR(1) and regR(2) in data_r.
% if a segment is found that fits the requirements data_new is made with
% the new cell_mask and success is returned as true. Else the same data is
% returned and success is false.
%
% INPUT :
%      data_c : current data (seg/err) file.
%      regC : numbers of region in current data that needs to be separated
%      data_r : reverse data (seg/err) file.
%      regR : numbers of regions in reverse data file
%      CONST : segmentation parameters
%
% OUTPUT :
%      data_new : data_c with new segment in good_segs and modified cell mask
%      success : true if segment was found succesfully.
%
% Copyright (C) 2016 Wiggins Lab
% Written by Stella Stylianidou
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

success = 0;

[xx,yy] = getBBpad(data_c.regs.props(regC).BoundingBox,size(data_c.phase),4);
mask = (data_c.regs.regs_label(yy,xx) == regC);
segMask = (mask - data_c.segs.segs_3n(yy,xx) - data_c.segs.segs_good(yy,xx)) > 0;

badSegMask = logical(data_c.segs.segs_bad(yy,xx) .* segMask);
labelMask = data_c.segs.segs_label(yy,xx);
segIDs = unique(labelMask(badSegMask));

highScores = data_c.segs.scoreRaw(segIDs) > 45;
[~, maxID] = max(data_c.segs.scoreRaw(segIDs));

splitIDs = segIDs(highScores);
splitIDs = [splitIDs; segIDs(maxID)];
splitIDs = unique(splitIDs);

if regC == 53
    disp('test');
end

newMask = ones(numel(yy), numel(xx));
if numel(splitIDs) > 0
    for i = 1:numel(splitIDs)
        newMask = newMask .* (logical(data_c.mask_cell(yy,xx) .* segMask) & ~logical((labelMask == splitIDs(i))));
        newMask = imdilate(imerode(newMask, ones(3)), ones(3));
    end

    % Successfully split into 2 regions
    if max(unique(bwlabel(newMask))) > 1
        fullMask = logical(newMask) + (~mask .* logical(data_c.mask_cell(yy,xx)));
        data_c.mask_cell(yy,xx) = logical(data_c.mask_cell(yy,xx)) & logical(fullMask);

        success = 1;
    end   
end