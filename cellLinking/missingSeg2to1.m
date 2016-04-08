function [data_new,success] = missingSeg2to1 (data_c,regC,data_r,regR,CONST)
% finds missing segment
% adds it to the segs good, removes it from seg bad
% removes it from the regions and remakes the mask_cell

minimumInfo = [];
minIndex = [] ;
minRegProps = [];
minRegsLabel = [];
success = false;
data_new = data_c;

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
comboMaskRdil = imdilate(comboMaskR, strel('square',2));
comboMaskRerod = imerode(comboMaskRdil, strel('square',2));
separatingSegment = ~comboMaskR.*comboMaskRerod;

dist = bwdist(separatingSegment);

imshow(cat(3,0.5*ag(data_c.phase) + ag(data_c.regs.regs_label==regC),ag(data_r.regs.regs_label==regR(1)),ag(data_r.regs.regs_label==regR(2))));

% add the long axis thing as a constant..
% if this thing are not true don't even try to segment this again.
% or size of cell too small to be divided..
if numel(segs_list) == 0  || (longAxis < 30 && shortAxis < .5*CONST.superSeggerOpti.MAX_WIDTH)
    return
end
imshow(segsLabel)

% keep only segments of interest
[minIndex,minRegEScore, minDA,segs_close] = findBestSegs (segsLabel,segs_list,dist,mask,CONST,areaR1,areaR2,data_c.segs.scoreRaw);

if  ~isempty(minIndex) && any (minRegEScore) > 0 && minDA < 1.5*CONST.trackOpti.AREA_CHANGE_LIMIT
    % a good solution
    num_segs = numel(segs_close)
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
    imshow(cat(3,ag(data_new.mask_cell),ag(data_c.mask_cell),ag(data_c.mask_cell)))
    success = true;
    return;
end

% resegment only that part of the image
phase = data_c.phase(yy,xx) ;
tmp = superSeggerOpti(phase, [], 1, CONST, 1, '', [] )
maskDil =  imdilate(mask, strel('square',2));
newmask = tmp.mask_bg;
newmask(~maskDil) = 0;
imshow(newmask-tmp.segs.segs_3n-tmp.segs.segs_good-tmp.segs.segs_bad)
newmask = (newmask - tmp.segs.segs_3n)>0;

TmpSegsLabel = tmp.segs.segs_label.*newmask;
segs_list = unique(TmpSegsLabel);
segs_list = segs_list(segs_list~=0);


[minIndex,minRegEScore, minDA,segs_close] = findBestSegs (TmpSegsLabel,segs_list,dist,newmask,CONST,areaR1,areaR2,tmp.segs.scoreRaw);

% get best segments..
% how to extend segment - horiz/diag/or wtv?

% check if a good solution was found
if  ~isempty(minIndex) && any (minRegEScore) > 0 && minDA < 1.5*CONST.trackOpti.AREA_CHANGE_LIMIT
    % a good solution
    num_segs = numel(segs_close)
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
    mask_cell_partial(mask) = finalMask(mask);
    data_new.mask_cell(yy,xx) = mask_cell_partial;
    
    % %         should probably do something to add them to the segments and
    % %         reset the labels.. but seems complicated right now :S
    %         partialGoodSegs = data_new.segs.segs_good(yy,xx);
    %         partialGoodSegs(logical(finalMask))= 0;
    %         data_new.segs.segs_good(yy,xx) = partialGoodSegs+segsAdded;
    %         data_new.segs.segs_good(yy,xx) = data_new.segs.segs_good(yy,xx)-segsRemoved;
    %         data_new.segs.segs_bad(yy,xx) = data_new.segs.segs_bad(yy,xx)+segsRemoved;
    %         data_new.segs.segs_bad(yy,xx) = data_new.segs.segs_bad(yy,xx)-segsAdded;
    %         data_new.segs.segs_bad = (data_new.segs.segs_bad>0);
    %         data_new.segs.segs_good = (data_new.segs.segs_good>0);
    
    
    success = true;
    return;
end

end

function [minIndex,minRegEScore, minDA,segs_close] = findBestSegs (segsLabel,segs_list,dist,mask,CONST,areaR1,areaR2,rawScores)
minimumScore = inf;
DIST_CUT = 5;
dist_segs_c = inf*segs_list;
nsegs = numel(segs_list);

for jj = 1:nsegs
    dist_segs_c(jj) = min(dist(segsLabel ==segs_list(jj)));
end

% sort distances and keep only distances < 5
segs_close = segs_list(dist_segs_c<DIST_CUT);

% turn on each segment until the regions become more than 1
num_segs = numel( segs_close );

%num_segs = numel(segs_list);
num_comb = 2^num_segs;
disp (['Finding missing segment from ', num2str(num_segs),' segments, ', num2str(num_comb), ' combinations']);
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
    
    
    % needs another part where it just comes up with a line..
    
end


end

function vect = makeVector( nn, n )
vect = zeros(1,n);
for i=n-1:-1:0;
    vect(i+1) = floor(nn/2^i);
    nn = nn - vect(i+1)*2^i;
end
end