
function [vect,Emin] = systematic( segs_list, data, cell_mask, xx, yy, CONST)

debug_flag = 0;

num_segs = numel(segs_list);
num_comb = 2^num_segs;

regionScore = zeros( 1, num_comb );
ss = size(data.phase);

for jj = 1:num_comb;
    
    % goes through all combinations and turns on segments
    vect = makeVector(jj-1,num_segs);
    %make modified mask - subtract segments with value 1 in vect
    cell_mask_mod = cell_mask;
    
    for kk = 1:num_segs
        cell_mask_mod = cell_mask_mod - vect(kk)*(segs_list(kk)==data.segs.segs_label(yy,xx));
    end
    
    cell_mask_mod = cell_mask_mod>0;
    regs_label_mod = (bwlabel( cell_mask_mod, 4 ));
    tmp2_props = regionprops( regs_label_mod, 'BoundingBox','Orientation','Centroid','Area');
    num_regs_mod = max(regs_label_mod(:));    
    info = zeros(num_regs_mod, CONST.regionScoreFun.NUM_INFO);
    ss_regs_label_mod = size( regs_label_mod );
    
    for mm = 1:num_regs_mod;        
        [xx_,yy_] = getBBpad( tmp2_props(mm).BoundingBox, ss_regs_label_mod, 1);
        
        try
            mask = regs_label_mod(yy_,xx_)==mm;
            info(mm,:) = CONST.regionScoreFun.props( mask, tmp2_props(mm));
        catch ME
            printError(ME);
        end
        
    end
    
    % score is : - RegionScores +  (OnSegments - OffSegments)* DE_norm
    regE(1:mm,jj) = -CONST.regionScoreFun.fun(info,CONST.regionScoreFun.E);
    segE(1:num_segs,jj) = ((1-2*vect).*data.segs.scoreRaw(segs_list)')*CONST.regionOpti.DE_norm;
    
    regionScore(jj) = mean(regE(:,jj) )+ mean(segE(:,jj));
    
    if debug_flag
        figure(1);
        clf;
        imshow( cat(3,autogain(cell_mask),...
            autogain(cell_mask_mod),...
            0*autogain(cell_mask)),'InitialMagnification','fit');
        disp(['Total Region Score : ',num2str(regionScore(jj))]);        
    end
    
end

% get the minimum score
[Emin, jj_min] = min(regionScore);
vect = makeVector(jj_min-1,num_segs);



if debug_flag
    % shows the minimum score found from systematic
    cell_mask_mod = cell_mask;    
    for kk = 1:num_segs
        cell_mask_mod = cell_mask_mod - vect(kk)*(segs_list(kk)==data.segs.segs_label(yy,xx));
    end
    figure(1);
    clf;
    imshow( cat(3,autogain(cell_mask),...
        autogain(cell_mask_mod),...
        0*autogain(cell_mask)),'InitialMagnification','fit');
    disp(['Total Region Score : ',num2str(Emin)]);
end

end

function vect = makeVector( nn, n )
vect = zeros(1,n);
for i=n-1:-1:0;
    vect(i+1) = floor(nn/2^i);
    nn = nn - vect(i+1)*2^i;
end

end