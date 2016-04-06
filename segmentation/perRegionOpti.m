function [data] = perRegionOpti( data, disp_flag, CONST,header)
% regionOpti : Segmentaion optimization using region characteristics.
% It turns off on and off segments using a systematic method, or simulated
% anneal, according to the nudmber of segments to be considered.
% if the number of segments > MAX_NUM_RESOLVE : uses the rawScore.
% if the number of segments > MAX_NUM_SYSTEMATIC : uses simulated anneal.
% and if it is below that it uses a systematic function.
%
% INPUT :
%       data : data with segs field (.err data or .trk data)
%       dissp : display flag
%       CONST : segmentation constants
%       header : information string
% OUTPUT :
%       data : data structure with modified segments
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

MAX_LENGTH = CONST.regionOpti.MAX_LENGTH;
CutOffScoreHi = CONST.regionOpti.CutOffScoreHi;
MAX_NUM_RESOLVE  = CONST.regionOpti.MAX_NUM_RESOLVE;
MAX_NUM_SYSTEMATIC = CONST.regionOpti.MAX_NUM_SYSTEMATIC;
CONST.regionOpti.Emin   = .2;
NUM_INFO = CONST.regionScoreFun.NUM_INFO;
E = CONST.regionScoreFun.E;

minGoodRegScore = CONST.regionOpti.minGoodRegScore ; 
neighMaxScore = CONST.regionOpti.neighMaxScore;

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


disp([header, 'rO: Got ',num2str(data.regs.num_regs),' regions.']);


% get regions with bad scores
regs_label = data.regs.regs_label;
badReg = find(data.regs.scoreRaw < minGoodRegScore);
props = data.regs.props;

% remove tiny region
small = find([props(:).Area]>CONST.trackOpti.MIN_AREA);
badReg = badReg(ismember(badReg,small));

numBadRegions = size(badReg,1);
disp([header, 'rO: Possible segments to be tweaked : ',num2str(numel(unique(segsLabelMod))-1),'.']);
disp([header, 'rO: Optimizing ',num2str(numBadRegions),' regions.']);


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
    if  data.regs.info(ii,1) < MAX_LENGTH % for a small cell add all segments 
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
    
    % remove from mask already checked segments
    for kk = 1 : numel(goodChecked)
        combMask = combMask - (segsLabelMod(yy,xx)==goodChecked(kk));
    end
    
    
    for kk = 1 : numel(badChecked)
        combMask = combMask + (segsLabelMod(yy,xx)==badChecked(kk));
    end
    
    combMask = double(combMask>0);
    % keep only not checked segs
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
    
    if debug_flag
        figure(1);
        mod = mask_regs;
        mod(yy,xx) = mod(yy,xx) + combMaskErode;
        imshow(cat(3,0.5*ag(mask_regs),ag(mod),ag(mod)));
    end
    
    
    if isempty(segs_list)
        [vect] = [];
    elseif numel(segs_list) > MAX_NUM_RESOLVE % use raw score
        disp([header, 'rO: Too many regions to analyze (',num2str(num_segs),').']);
        [vect] = data.segs.scoreRaw(segs_list)>0;
        Emin = -100;
    elseif numel(segs_list) > MAX_NUM_SYSTEMATIC % use simulated anneal
        disp([header, 'rO: Simulated Anneal : (',num2str(num_segs),' segments).']);
        [vect,regEmin] = simAnnealMap( segs_list, data, combMask, xx, yy, CONST, 0);
    else % use systematic
        disp([header, 'rO: Systematic : (',num2str(num_segs),' segments).']);
        [vect,regEmin] = systematic( segs_list, data, combMask, xx, yy, CONST);
    end
        
    if ~isempty(segs_list)
        goodSegList = [goodSegList;segs_list(logical(vect))];
        badSegList = [badSegList;segs_list(~vect)];
    end
    
    
    if debug_flag
        % shows the final optimized segments for the combined mask      
        mod = mask_regs*0;
        mod(yy,xx) = combMask;
        segment_mask = mask_regs*0;
        % segment_mask
        for kk = 1:num_segs
            mod = mod - vect(kk)*(segs_list(kk)==segsLabelAll);
            segment_mask = segment_mask + vect(kk)*(segs_list(kk)==segsLabelAll);
        end        
        
        figure (2);
        backer = 0.5*ag(mask_regs);      
        imshow(cat(3,backer+ag(segment_mask) + 0.7*ag(ismember(segsLabelAll,segs_list)),backer + ag(mod>0), ag(mod>0) + backer))
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
    cell_mask = data.mask_cell;
    back = double(0.7*ag( data.phase ));
    outline = imdilate( cell_mask, strel( 'square',3) );
    outline = ag(outline-cell_mask);
    imshow(uint8(cat(3,back + 0.7*double(ag(data.segs.segs_good)) + double(ag(data.segs.segs_3n))...
        ,back,...
        back+ 0.2*double(ag(~cell_mask)-outline))));
    drawnow;
end


end

