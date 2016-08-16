function [data] = perRegionOpti( data, disp_flag, CONST,header)
% perRegionOpti : Segmentaion optimization using region characteristics.
% It attempts to improve the region score by turning off on and off segments
% of regions with bad scores. It uses systematic method, or simulated
% anneal, according to the nudmber of segments to be considered.
%
% INPUT :
%       data : data with segs field (.err data or .trk data)
%       dissp : display flag
%       CONST : segmentation constants
%       header : information string
% OUTPUT :
%       data : data structure with modified segments
%
%
% Copyright (C) 2016 Wiggins Lab
% Written by Stella Styliandou & Paul Wiggins.
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


MIN_LENGTH = CONST.regionOpti.MIN_LENGTH;
CutOffScoreHi = CONST.regionOpti.CutOffScoreHi;
MAX_NUM_RESOLVE  = CONST.regionOpti.MAX_NUM_RESOLVE;
MAX_NUM_SYSTEMATIC = CONST.regionOpti.MAX_NUM_SYSTEMATIC;
NUM_INFO = CONST.regionScoreFun.NUM_INFO;
E = CONST.regionScoreFun.E;

minGoodRegScore = CONST.regionOpti.minGoodRegScore ;
neighMaxScore = CONST.regionOpti.neighMaxScore;
verbose = CONST.parallel.verbose;

if ~exist('header','var')
    header = [];
end

if nargin < 2 || isempty(disp_flag);
    disp_flag = 1;
end

debug_flag = 0;

segsLabelAll = data.segs.segs_label;
segs_3n    = data.segs.segs_3n;
above_Hi_ind = find(data.segs.scoreRaw > CutOffScoreHi);
below_Hi_ind = find(data.segs.scoreRaw <= CutOffScoreHi);
segs_HiGood = double(ismember(segsLabelAll, above_Hi_ind));
segs_good = segs_HiGood;
segs_bad = double(ismember(segsLabelAll, below_Hi_ind));
ss = size(segs_3n);

% remaining segs allowed to be tweaked
segsLabelMod = data.segs.segs_label;
segsLabelMod(logical(segs_3n+segs_good)) = 0;

% remake mask with best guessed regions : segs_3n and high segs_good
mask_regs = double((data.mask_bg-segs_3n-segs_good)>0);
data.regs.regs_label = (bwlabel( mask_regs, 4 ));
data.regs.props = regionprops( data.regs.regs_label, ...
    'BoundingBox','Orientation','Centroid','Area');
data.regs.num_regs = max( data.regs.regs_label(:) );
data.regs.score  = ones( data.regs.num_regs, 1 );
data.regs.scoreRaw = ones( data.regs.num_regs, 1 );
data.regs.info = zeros( data.regs.num_regs, NUM_INFO );

for ii = 1:data.regs.num_regs
    [xx,yy] = getBBpad( data.regs.props(ii).BoundingBox, ss, 1);
    mask = data.regs.regs_label(yy,xx)==ii;
    data.regs.info(ii,:) = CONST.regionScoreFun.props( mask, data.regs.props(ii) );
    data.regs.scoreRaw(ii) = CONST.regionScoreFun.fun(data.regs.info(ii,:), E);
    data.regs.score(ii) = data.regs.scoreRaw(ii) > 0;
end

if verbose
    disp([header, 'rO: Got ',num2str(data.regs.num_regs),' regions.']);
end

% get regions with bad scores
regs_label = data.regs.regs_label;
badReg = find(data.regs.scoreRaw < minGoodRegScore);
props = data.regs.props;

numBadRegions = size(badReg,1);
if verbose
    disp([header, 'rO: Possible segments to be tweaked : ',num2str(numel(unique(segsLabelMod))-1),'.']);
    disp([header, 'rO: Optimizing ',num2str(numBadRegions),' regions.']);
end

% list of already tweaked segments
goodSegList = [];
badSegList = [];


while ~isempty(badReg)
    ii = badReg(1);
    
    % get padded box
    originalBBbox = data.regs.props(ii).BoundingBox;
    [xx_,yy_] = getBBpad( originalBBbox, ss, 5);
    cellMask = (regs_label(yy_,xx_) == ii);
    
    % get neigbors with scores below neighMaxScore
    neighborIds = unique(regs_label(yy_,xx_));
    neighborIds = neighborIds(neighborIds~=0);
    neighbordIds = neighborIds(data.regs.scoreRaw(neighborIds) < neighMaxScore);
    cellMaskDil = imdilate(cellMask, strel('square',3));
    combinedCellMask = regs_label *0;
    
    for kk = 1 : numel(neighborIds)
        combinedCellMask = combinedCellMask + (regs_label == neighborIds(kk));
    end
    
    % add all segments inside the original cell / touching neighbors
    if  data.regs.info(ii,1) < MIN_LENGTH % for a small cell add all segments
        segs_list = unique(cellMaskDil.*segsLabelAll(yy_,xx_));
    else % add only segments to be considered
        segs_list = unique(cellMaskDil.*segsLabelMod(yy_,xx_));
    end
    segs_list = segs_list(segs_list~=0);
    
    % add segments to the mask
    for kk = 1 :numel(segs_list)
        combinedCellMask = combinedCellMask + (segsLabelAll==segs_list(kk));
    end
    combinedCellMask = combinedCellMask>0;
    
    % remake regions
    regCombLabels = bwlabel(combinedCellMask);
    combRegProps = regionprops(regCombLabels,'BoundingBox','Orientation','Centroid','Area');
    
    % find most overlapping region
    origCellMask = (regs_label == ii);
    %imshow(cat(3,0.5*ag(mask_regs),ag(origCellMask),ag(origCellMask)));
    overlapArea = zeros(1,numel(combRegProps));
    for j = 1 : numel(combRegProps)
        mask2 = (regCombLabels == j);
        overlap = origCellMask & mask2;
        overlapArea(j) = sum(overlap(:)) / data.regs.props(ii).Area;
    end
    
    
    ind = find(overlapArea ==1);
    
    % bounding box of overlapping region
    [xx,yy] = getBBpad(combRegProps(ind).BoundingBox,ss,3);
    combMask = (regCombLabels(yy,xx) == ind);
    
    % get indices of neighbors we are checking and remove them from
    % checklist
    neighborsToCheck = unique(regs_label.* (regCombLabels == ind));
    badReg = setdiff (badReg,neighborsToCheck);
    
    % dilate and erode mask to add more segments.
    combMaskDil = imdilate(combMask, strel('square',2));
    combMaskErode = imerode(combMaskDil, strel('square',2));
    segs_list_extra = unique(combMaskErode.*segsLabelMod(yy,xx));
    segs_list = [segs_list;segs_list_extra];
    segs_list = unique(segs_list);
    segs_list = segs_list(segs_list~=0);
    
    goodChecked = segs_list(ismember(segs_list,goodSegList));
    badChecked = segs_list(ismember(segs_list,badSegList));
    
    %remove from mask already checked segments
    for kk = 1 : numel(goodChecked)
        combMask = combMask - (segsLabelMod(yy,xx)==goodChecked(kk));
    end
    
    
    for kk = 1 : numel(badChecked)
        combMask = combMask + (segsLabelMod(yy,xx)==badChecked(kk));
    end
    
    combMask = double(combMask>0);
    %keep only not checked segs
    if ~isempty(goodChecked)
        segs_list =  segs_list(~ismember(segs_list,goodChecked));
    end
    if ~isempty(badChecked)
        segs_list =  segs_list(~ismember(segs_list,badChecked));
    end
    
    
    num_segs = numel(segs_list);
    segmentMask = 0 *combinedCellMask;
    
    for kk = 1 :num_segs
        segmentMask = segmentMask + (segsLabelAll==segs_list(kk));
    end
    
    
    
    if isempty(segs_list)
        [vect] = [];
    elseif numel(segs_list) > MAX_NUM_RESOLVE % use raw score
        if verbose
            disp([header, 'rO: Too many regions to analyze (',num2str(num_segs),').']);
        end
        [vect] = data.segs.scoreRaw(segs_list)>0;
    elseif numel(segs_list) > MAX_NUM_SYSTEMATIC % use simulated anneal
        if verbose
            disp([header, 'rO: Simulated Anneal : (',num2str(num_segs),' segments).']);
        end
        [vect,~] = simAnnealMap( segs_list, data, combMask, xx, yy, CONST, 0);
    else % use systematic
        if verbose
            disp([header, 'rO: Systematic : (',num2str(num_segs),' segments).']);
        end
        [vect,~] = systematic( segs_list, data, combMask, xx, yy, CONST);
    end
    
    if ~isempty(segs_list)
        goodSegList = [goodSegList;segs_list(logical(vect))];
        badSegList = [badSegList;segs_list(~vect)];
    end
    
    
    if debug_flag &&  ~isempty(segs_list)
        % shows the final optimized segments for the combined mask
        mod = mask_regs*0;
        mod(yy,xx) = combMask;
        segment_mask = mask_regs*0;
        % segment_mask
        for kk = 1:num_segs
            mod = mod - vect(kk)*(segs_list(kk)==segsLabelAll);
            segment_mask = segment_mask + vect(kk)*(segs_list(kk)==segsLabelAll);
        end
        
        
        backer = 0.5*ag(mask_regs);
        segment_mask_small = ag(segment_mask(yy,xx));
        backer_small = (backer(yy,xx));
        backer_small = ag(((backer_small) - ag(combMask))>0);
        all_segs = ag(ismember(segsLabelAll,segs_list));
        all_segs_small = all_segs(yy,xx);
        combMask_bef = data.mask_cell(yy,xx);
        figure (2);
        subplot(1,2,1)
        imshow(cat(3,0.5*(backer_small),backer_small + ag(combMask_bef), ...
            ag(combMask_bef) + (backer_small)))
        subplot(1,2,2)
        imshow(cat(3,0.3*(backer_small)+ag(segment_mask_small)...
            ,0.2*ag(all_segs_small-segment_mask_small) +  0.3*backer_small + 0.5*ag(combMask>0), ...
            0.5* ag(combMask>0) +  0.3*(backer_small)));
        keyboard;
    end
end

if ~isempty(goodSegList)
    segs_good = (ismember(segsLabelAll,goodSegList)+segs_good)>0;
    segs_bad = (segs_bad - ismember(segsLabelAll,goodSegList))>0;
    data.segs.score(goodSegList) = 1;
end

if ~isempty(badSegList)
    segs_good = (segs_good - ismember(segsLabelAll,badSegList))>0;
    segs_bad = (segs_bad + ismember(segsLabelAll,badSegList ))>0;
    data.segs.score(badSegList) = 0;
end

data.mask_cell = double((data.mask_bg-segs_3n-segs_good)>0);
data.segs.segs_good = segs_good;
data.segs.segs_bad = segs_bad;

% update region fields using new mask
data = intMakeRegs( data, CONST );

if disp_flag
    figure(1);
    cell_mask = data.mask_cell;
    back = double(0.7*ag( data.phase ));
    outline = imdilate( cell_mask, strel( 'square',3) );
    outline = ag(outline-cell_mask);
    % imshow does not work for parallel - use image
    image(uint8(cat(3,back + 0.7*double(ag(data.segs.segs_good)) + double(ag(data.segs.segs_3n))...
        ,back,...
        back+ 0.2*double(ag(~cell_mask)-outline))));
    drawnow;
    axis equal tight;
end


end

