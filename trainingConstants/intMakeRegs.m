function data = intMakeRegs( data, mask_bad_regs, CONST, E )
% intMakeRegs : creates info for bad regions or makes new regions

ss = size( data.mask_cell );
NUM_INFO = CONST.regionScoreFun.NUM_INFO;
data.regs.regs_label = bwlabel( data.mask_cell );
data.regs.num_regs = max( data.regs.regs_label(:) );
data.regs.props = regionprops( data.regs.regs_label, ...
    'BoundingBox','Orientation','Centroid','Area');
data.regs.score  = ones( data.regs.num_regs, 1 );
data.regs.scoreRaw = ones( data.regs.num_regs, 1 );
data.regs.info = zeros( data.regs.num_regs, NUM_INFO );
data.regs.boun = zeros( data.regs.num_regs, 1 );

for ii = 1:data.regs.num_regs
    
    [xx,yy] = getBBpad( data.regs.props(ii).BoundingBox, ss, 1);
    mask = data.regs.regs_label(yy,xx)==ii;
    
    if ii == 1; % first region, create info table
        tmp = CONST.regionScoreFun.props( mask, data.regs.props(ii) );
        data.regs.info = zeros(data.regs.num_regs, numel(tmp));
    end
    
    data.regs.info(ii,:) = CONST.regionScoreFun.props( mask, data.regs.props(ii) );
    data.regs.boun(ii) = any( [1==xx(1),1==yy(1),ss(1)==yy(end),ss(2)==xx(end)] );
    data.regs.info(ii,:) = CONST.regionScoreFun.props( mask, data.regs.props(ii) );
    data.regs.scoreRaw(ii) = CONST.regionScoreFun.fun(data.regs.info(ii,:), E);
    data.regs.score(ii) = data.regs.scoreRaw(ii) > 0;
  
    if exist( 'mask_bad_regs', 'var' ) && ~isempty( mask_bad_regs )
        mask_ = mask_bad_regs(yy,xx);        
        if any( mask(mask_) )
            data.regs.score(ii) = 0;
        end
    end
    
end
