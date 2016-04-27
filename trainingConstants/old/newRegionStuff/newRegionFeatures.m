function [ data ] = newRegionFeatures ( data ,mask_bad_regs, keepScores)
%NEWREGIONFEATURES Summary of this function goes here
%   Detailed explanation goes here

% intMakeRegs : creates info for bad regions or makes new regions

if ~exist('keepScores','var')
    keepScores = false;
end

ss = size( data.mask_cell );
data.regs.regs_label = bwlabel( data.mask_cell );
data.regs.num_regs = max( data.regs.regs_label(:) );
data.regs.props = regionprops( data.regs.regs_label, ...
    'BoundingBox','Orientation','Centroid','Area','Perimeter','MajorAxisLength','MinorAxisLength','Eccentricity');

if ~keepScores
    data.regs.score  = ones( data.regs.num_regs, 1 );
    data.regs.scoreRaw = ones( data.regs.num_regs, 1 );
end

NUM_INFO = 21; % number of info fields
data.regs.info = zeros( data.regs.num_regs, NUM_INFO );
data.regs.boun = zeros( data.regs.num_regs, 1 );

for ii = 1:data.regs.num_regs
    
    [xx,yy] = getBBpad( data.regs.props(ii).BoundingBox, ss, 1);
    mask = data.regs.regs_label(yy,xx)==ii;
    mask_cell = data.regs.regs_label==ii;
    maskedPhase = (double(mask_cell).*double(data.phase));
    maskedPhase = maskedPhase(yy,xx);
    Orientation = data.regs.props(ii).Orientation;
    maskRot = (fast_rotate_loose_double( mask, -Orientation+90 ));
    maskedPhaseRot = imrotate((maskedPhase), -Orientation+90, 'bilinear');
    
    gclm_maskedPhase = graycomatrix(maskedPhaseRot);
    hf = haralickFeatures(gclm_maskedPhase);
    
    data.regs.info (ii, 1:21) = cellprops3(mask, data.regs.props(ii));

    data.regs.boun(ii) = any( [1==xx(1),1==yy(1),ss(1)==yy(end),ss(2)==xx(end)] );
    
    if ~keepScores
        data.regs.scoreRaw(ii) = 0.5;
        data.regs.score(ii) = 1;
    end
    
    if exist( 'mask_bad_regs', 'var' ) && ~isempty( mask_bad_regs )
        mask_ = mask_bad_regs(yy,xx);
        if any( mask(mask_) )
            data.regs.score(ii) = 0;
        end
    end
end

end

