function [data_new,success] = missingSeg2to1 (data_c,regC,data_r,regR,CONST)
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

success = false;
data_new = data_c;
debug_flag = 0;

% need some checks to see if this should happen
longAxis = data_c.regs.info(regC,1);
shortAxis = data_c.regs.info(regC,2);
[xx,yy] = getBBpad(data_c.regs.props(regC).BoundingBox,size(data_c.phase),4);
mask = (data_c.regs.regs_label(yy,xx) == regC);
mask = (mask - data_c.segs.segs_3n(yy,xx))>0;

% turn on all segments pick best one that divides the area ~ equally?
segsLabel = data_c.segs.segs_label(yy,xx).*mask;
segs_list = unique(segsLabel);
segs_list = segs_list(segs_list~=0);
areaR1 = data_r.regs.props(regR(1)).Area;
areaR2 = data_r.regs.props(regR(2)).Area;

maskR1 = (data_r.regs.regs_label == regR(1));
maskR2 = (data_r.regs.regs_label == regR(2));
comboMaskR = maskR1+maskR2;

comboMaskR = comboMaskR(yy,xx);
% find segment between them in data_r
comboMaskRdil = imdilate(comboMaskR, strel('square',3));
comboMaskRerod = imerode(comboMaskRdil, strel('square',3));
separatingSegment = ~comboMaskR.*comboMaskRerod;

dist = bwdist(separatingSegment);

if debug_flag
    figure(2);
    clf;
    imshow(cat(3,0.5*ag(data_c.phase) + ag(data_c.regs.regs_label==regC),...
        ag(data_r.regs.regs_label==regR(1)),ag(data_r.regs.regs_label==regR(2))));
end

% do not divide a cell that is too small to be divided.
if numel(segs_list) == 0  || ...
        (longAxis < CONST.regionOpti.MIN_LENGTH * 1.5 && shortAxis < .5*CONST.superSeggerOpti.MAX_WIDTH)
    return
end
if debug_flag
    imshow(segsLabel);
end

% keep only segments of interest
[minIndex,minRegEScore, minDA,segs_close] = findBestSegs (segsLabel,segs_list,dist,mask,CONST,areaR1,areaR2,data_c.segs.scoreRaw);

if  ~isempty(minIndex)% && any (minRegEScore) > 0 && minDA < 1.5*CONST.trackOpti.DA_MAX
    % a good solution
    num_segs = numel(segs_close);
    vect = makeVector(minIndex-1,num_segs);
    segsAdded = data_c.segs.segs_label * 0;
    segsRemoved = data_c.segs.segs_label * 0;
    
    for kk = 1:num_segs
        if  vect(kk)
            segsAdded = segsAdded + (segs_close(kk)==data_c.segs.segs_label);
        else
            segsRemoved = segsRemoved + (segs_close(kk)==data_c.segs.segs_label);
        end
    end
    
    segsAdded(yy,xx) = segsAdded(yy,xx) + data_c.segs.segs_3n(yy,xx);
    segsAdded(yy,xx) = segsAdded(yy,xx)>0;
    data_new.segs.segs_good = data_c.segs.segs_good+segsAdded;
    data_new.segs.segs_good = data_c.segs.segs_good-segsRemoved;
    data_new.segs.segs_bad = data_c.segs.segs_bad+segsRemoved;
    data_new.segs.segs_bad = data_c.segs.segs_bad-segsAdded;
    data_new.segs.segs_bad = (data_new.segs.segs_bad>0);
    data_new.segs.segs_good = (data_new.segs.segs_good>0);
    
    data_new.regs.regs_label(segsAdded>0) = 0; % removes segment from regs_label
    data_new.mask_cell(segsAdded>0) = 0;
    if debug_flag
        imshow(cat(3,ag(data_new.mask_cell),ag(data_c.mask_cell),ag(data_c.mask_cell)))
    end
    success = true;
    return;
end

% resegment only that part of the image
phase = data_c.phase(yy,xx) ;
tmp = superSeggerOpti(phase, [], 1, CONST, 1, '', []);
maskDil =  imdilate(mask, strel('square',2));
newmask = tmp.mask_bg;
newmask(~maskDil) = 0;
if debug_flag
    imshow(newmask-tmp.segs.segs_3n-tmp.segs.segs_good-tmp.segs.segs_bad);
end
newmask = (newmask - tmp.segs.segs_3n)>0;

TmpSegsLabel = tmp.segs.segs_label.*newmask;
segs_list = unique(TmpSegsLabel);
segs_list = segs_list(segs_list~=0);

[minIndex,minRegEScore, minDA,segs_close] = findBestSegs (TmpSegsLabel,segs_list,dist,newmask,CONST,areaR1,areaR2,tmp.segs.scoreRaw);

% check if a good solution was found
if  ~isempty(minIndex) %&& any (minRegEScore) > 0 && minDA < 1.5*CONST.trackOpti.DA_MAX
    % a good solution
    num_segs = numel(segs_close);
    vect = makeVector(minIndex-1,num_segs);
    segsAdded = TmpSegsLabel * 0;
    segsRemoved = TmpSegsLabel * 0;
    
    for kk = 1:num_segs
        if  vect(kk)
            segsAdded = segsAdded + (segs_close(kk)==TmpSegsLabel);
        else
            segsRemoved = segsRemoved + (segs_close(kk)==TmpSegsLabel);
        end
    end
    
    finalMask = newmask - segsAdded + segsRemoved;
    data_new = data_c;
    mask_cell_partial = data_new.mask_cell(yy,xx);
    mask_cell_partial((data_c.regs.regs_label(yy,xx) == regC)) = finalMask((data_c.regs.regs_label(yy,xx) == regC));
    data_new.mask_cell(yy,xx) = mask_cell_partial;
    success = true;
    return;
end

end

function [minIndex,minRegEScore, minDA,segs_close] = findBestSegs (segsLabel,segs_list,dist,mask,CONST,areaR1,areaR2,rawScores)
verbose = CONST.parallel.verbose;
minimumScore = inf;
DIST_CUT = 5;
dist_segs_c = inf*segs_list;
nsegs = numel(segs_list);
minIndex = [];
minRegEScore = [];
minDA = [];

for jj = 1:nsegs
    dist_segs_c(jj) = min(dist(segsLabel ==segs_list(jj)));
end

% sort distances and keep only distances < 5

segs_close = segs_list(dist_segs_c<DIST_CUT);

if numel(segs_close) > 8 
   [~,ord_segs] = sort(dist_segs_c);
   segs_close = segs_list(ord_segs(1:8));
end

% turn on each segment until the regions become more than 1
num_segs = numel( segs_close );

if num_segs == 0
    num_comb = 0;
else
    num_comb = 2^num_segs;
end

if verbose
    disp (['Finding missing segment from ', num2str(num_segs),' segments, ', num2str(num_comb), ' combinations']);
end

for i = 1  : num_comb
    
    vect = makeVector(i-1,num_segs); % systematic
    cell_mask_mod = mask;
    segmentMask = mask*0;
    for kk = 1:num_segs
        if vect(kk)
            segmentMask = segmentMask + (segs_close(kk)==segsLabel);
        end
    end
    
    % sometimes the problem is that segments are not touching.. dilate the
    % segment mask
    segmentMask = imdilate(segmentMask, strel('square',2));
    cell_mask_mod = (mask - segmentMask) >0;
    regs_label_mod = (bwlabel( cell_mask_mod, 4 ));
    num_regs_mod   = max(regs_label_mod(:));
    
    if num_regs_mod == 2 % only if there are two regions
        % loop through the regs and get their scores
        kk_range = 1:num_regs_mod;
        
        cell_mod_props = regionprops( regs_label_mod, 'BoundingBox','Orientation','Centroid','Area');
        
        reg_E = [];
        mask_reg = {};
        for kk = kk_range;
            [xx_,yy_] = getBB( cell_mod_props(kk).BoundingBox);
            mask_reg{kk} = (regs_label_mod==kk);
            info = CONST.regionScoreFun.props(mask_reg{kk}(yy_,xx_), cell_mod_props(kk));
            reg_E(kk) = CONST.regionScoreFun.fun(info,CONST.regionScoreFun.E);
        end
        
        areaChange1 = abs(cell_mod_props(2).Area  - areaR1)/ areaR1 + abs(cell_mod_props(1).Area - areaR2)/areaR2;
        areaChange2 = abs(cell_mod_props(2).Area - areaR2)/areaR2 +abs(cell_mod_props(1).Area - areaR1)/areaR1;
        
        regionScore(i) = 10 * min(areaChange1,areaChange2) + sum(-reg_E)+...
            sum((1-2*vect).*rawScores(segs_close)')*CONST.regionOpti.DE_norm;
        
        if regionScore(i) < minimumScore
            minimumScore =  regionScore(i) ;
            minIndex = i ;
            minRegEScore = reg_E;
            minDA = min(areaChange1,areaChange2)/2; % for two regions..
        end
    end
end


end

function vect = makeVector( nn, n )
vect = zeros(1,n);
for i=n-1:-1:0;
    vect(i+1) = floor(nn/2^i);
    nn = nn - vect(i+1)*2^i;
end
end