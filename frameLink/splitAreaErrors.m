function [madeChanges, data_c, data_r] =  splitAreaErrors (data_c, data_r, CONST, time, verbose)
% splitAreaErrors : splits cells with large area error.
%
% INPUT :
%   data_c : current time frame data (seg/err) file.
%   data_r : reverse time frame data (seg/err) file.
%   CONST : segmentation parameters.
%   time : frame number
%
% OUTPUT :
%   data_c : updated current time frame data (seg/err) file.
%   data_r : updated reverse time frame data (seg/err) file.
%   madeChanges : boolean for whether cells were split
%
%
% Copyright (C) 2016 Wiggins Lab
% Written by Connor Brennan
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

DEBUG_FLAG = 1;

DA_MIN = CONST.trackOpti.DA_MIN;
DA_MAX =  CONST.trackOpti.DA_MAX;

madeChanges = 0;

splitRegions = [];

for regNum =  1 : data_c.regs.num_regs;
    rCellsFromC = data_c.regs.map.r{regNum}; % where regNum maps in reverse
    rCells = unique(data_r.regs.revmap.f{regNum});
    
    if ~isempty(rCellsFromC)
        cCellsFromR = unique([data_r.regs.map.f{rCellsFromC}]);
    else
        cCellsFromR = [];
    end
    
    rCells = unique([rCellsFromC, rCells]);
    cCells = unique([regNum, cCellsFromR]);
    
    data_r.regs.dA.f(rCells);
    data_c.regs.dA.r(cCells);
    
    if numel(rCells) > 0 && numel(cCells) > 0
        fromArray = repmat(rCells, [1, numel(cCells)]);
        toArray = repmat(cCells, [1, numel(rCells)]);

        deltaSize = ([data_c.regs.props(toArray).Area] - [data_r.regs.props(fromArray).Area]) ./ [data_r.regs.props(fromArray).Area];
        
        for i = find(deltaSize > DA_MAX)
            if ~ismember(toArray(i), splitRegions)
                if (DEBUG_FLAG)
                    toMask = (data_c.regs.regs_label == toArray(i));
                    fromMask = (data_r.regs.regs_label == fromArray(i));

                    figure(4);

                    [fromX, fromY] = getBBpad(data_c.regs.props(toArray(i)).BoundingBox, size(data_c.mask_cell), 20);
                    [toX, toY] = getBBpad(data_r.regs.props(fromArray(i)).BoundingBox, size(data_r.mask_cell), 20);

                    xMax = max([toX, fromX]);
                    xMin = min([toX, fromX]);
                    yMax = max([toY, fromY]);
                    yMin = min([toY, fromY]);

                    x = xMin : xMax;
                    y = yMin : yMax;
                    
                    toMask = toMask(y, x) .* data_c.mask_cell(y, x);
                    fromMask = fromMask(y, x) .* data_r.mask_cell(y, x);

                    background = zeros(size(y, 2), size(x, 2));
                    imshow(cat(3, background + 0.5 * data_c.mask_cell(y, x) + 0.5 * toMask, background + 0.5 * toMask+ 0.5 * fromMask, background + 0.5 * data_r.mask_cell(y, x) + fromMask), []);
                
                    figure(5);
                    imshow(cat(3, ag(data_c.phase(y, x)), background, ag(data_c.segs.segs_bad(y, x))), []);
                    %imshow(data_c.segs.segs_3n(y, x) + data_c.segs.segs_good(y, x) + data_c.segs.segs_bad(y, x))
                end
                
                [data_c, success] = splitAtBestSeg(data_c, toArray(i), CONST);
                
                if success
                    madeChanges = 1;

                    disp (['Frame ', num2str(time), ' : split region ', num2str(toArray(i)), ' due to abnormal growth speed.']);
                else
                    if verbose
                        disp (['Frame ', num2str(time), ' : could not find segment to split region ', num2str(toArray(i)), '.']);
                    end
                end
                
                splitRegions = [splitRegions, toArray(i)];
            end
        end
    end
end

