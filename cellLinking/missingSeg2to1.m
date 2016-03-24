function [data_new,success] = missingSeg2to1 (data_c,regC,data_r,regR,CONST)
% finds missing segment
% adds it to the segs good, removes it from seg bad
% removes it from the regions and remakes the mask_cell

minimumScore = inf;
minimumInfo = [];
minIndex = [] ;
minRegProps = [];
minRegsLabel = [];
success = true;
data_new = data_c;

% need some checks to see if this should happen
longAxis = data_c.regs.info(regC,1);
shortAxis = data_c.regs.info(regC,2);
[xx,yy] = getBB(data_c.regs.props(regC).BoundingBox);
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

% find segment between them in data_r
% comboMaskRdil = imdilate(comboMaskR, strel('square',2));
% comboMaskRerod = imerode(comboMaskRdil, strel('square',3));
% separatingSegment = ~comboMaskR.*comboMaskRerod;


imshow(cat(3,0.5*ag(data_c.phase) + ag(data_c.regs.regs_label==regC),ag(data_r.regs.regs_label==regR(1)),ag(data_r.regs.regs_label==regR(2))));

% add the long axis thing as a constant..
% if this thing are not true don't even try to segment this again.
if numel(segs_list) == 0  || (longAxis < 30 && shortAxis < .5*CONST.superSeggerOpti.MAX_WIDTH) % or size of cell too small to be divided..
    success = false;
    return
else
     
%     dilateSeg = imdilate(separatingSegment, strel('square',3));   
%     overlapSegs = (labels(dilateSeg(yy,xx)>0));
%     sizeOfSeg = sum (separatingSegment(:)==1);
%     
%     % count occuring pixels..
%     [occur,segVal]=hist(overlapSegs,unique(overlapSegs));
%     occur = occur(segVal~=0);
%     segVal = segVal(segVal~=0);
%     
%     imshow(separatingSegment + labels==220 + labels==227)
%     
    
%     % create fake segment..
%     
%     cell_mask_mod = mask;
%     cell_mask_mod(dilateSeg(yy,xx)>0) = 0;
%     
%     regs_label_mod = (bwlabel( cell_mask_mod, 4 ));
%     num_regs_mod   = max(regs_label_mod(:));
%     

        
    % or get a bounding box..?
    % get all segments in badSegments that match?
    

    num_segs = numel(segs_list);
    num_comb = 2^num_segs;
    disp ([num2str(num_segs),' segments ', num2str(num_comb), ' combinations']);
    for i = 1  : num_comb
       
        vect = makeVector(i-1,num_segs); % systematic
        
        cell_mask_mod = mask;
        segmentMask = mask*0;
        for kk = 1:num_segs
            if vect(kk)
                segmentMask = segmentMask + (segs_list(kk)==segsLabel);
            end
        end
        
        % sometimes the prob is that segments are not touching.. dilate the
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
                sum((1-2*vect).*data_c.segs.scoreRaw(segs_list)')*CONST.regionOpti.DE_norm;
                        
            if regionScore(i) < minimumScore
                minimumScore =  regionScore(i) ;
                minIndex = i ;
                minRegEScore = reg_E;
                minDA = min(areaChange1,areaChange2)/2; % for two regions..
            end
        end
    end
    
   if  ~isempty(minIndex) && any (minRegEScore) > 0 && minDA < 1.5*CONST.trackOpti.AREA_CHANGE_LIMIT
        % a good solution
        
        vect = makeVector(minIndex-1,num_segs);       
        segsAdded = data_c.segs.segs_label * 0;
        segsRemoved = data_c.segs.segs_label * 0;
        
        for kk = 1:num_segs        
            if  vect(kk)
                segsAdded = segsAdded + (segs_list(kk)==data_c.segs.segs_label);
            else
                segsRemoved = segsRemoved + (segs_list(kk)==data_c.segs.segs_label);
            end
        end
        
        segsAdded(yy,xx) = segsAdded(yy,xx) + data_c.segs.segs_3n(yy,xx);
        segsAdded(yy,xx) = segsAdded(yy,xx)>0; 
        data_new.segs.segs_good = data_c.segs.segs_good+segsAdded;
        data_new.segs.segs_good = data_c.segs.segs_good-segsRemoved;
        data_new.segs.segs_bad = data_c.segs.segs_bad+segsRemoved;
        data_new.segs.segs_bad = data_c.segs.segs_bad-segsAdded;
        data_new.segs.segs_bad = (data_new.segs.segs_bad>0);
        data_new.segs.segs_bad = (data_new.segs.segs_good>0);
        
        data_new.regs.regs_label(segsAdded>0) = 0; % removes segment from regs_label
        data_new.mask_cell(segsAdded>0) = 0;
        imshow(cat(3,ag(data_new.mask_cell),ag(data_c.mask_cell),ag(data_c.mask_cell)))
        
    else
        
        % make up a segment using area percentages?
        imshow(cat(3,0.5*ag(data_c.phase) + ag(data_c.regs.regs_label==regC),ag(data_r.regs.regs_label==regR(1)),ag(data_r.regs.regs_label==regR(2))));

        success = false;
        data_new = data_c;
        keyboard;
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