function [ data ] = newRegionFeatures ( data, CONST)
%NEWREGIONFEATURES Summary of this function goes here
%   Detailed explanation goes here

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
    maskedPhase = (double(mask_cell).*double(data.phase));
    maskedPhase = maskedPhase(yy,xx);
    Orientation = data.regs.props.Orientation;
    maskRot = (fast_rotate_loose_double( mask, -Orientation+90 ));
    maskedPhaseRot = imrotate((maskedPhase), -Orientation+90, 'bilinear');
    gclm_maskedPhase = graycomatrix(maskedPhaseRot); 
    hf = GLCM_Features1(gclm_maskedPhase);
    % put them numbered
    haralickfeatures(1) = hf.autoc;
    haralickfeatures(2) = hf.contr;
    haralickfeatures(3) = hf.corrm;
    haralickfeatures(4) = hf.corrp;
    haralickfeatures(5) = hf.cprom;
    haralickfeatures(6) = hf.cshad;
    haralickfeatures(7) = hf.dissi;
    haralickfeatures(8) = hf.energ;
    haralickfeatures(9) = hf.entro;
    haralickfeatures(10) = hf.homom;
    haralickfeatures(11) = hf.homop;
    haralickfeatures(12) = hf.maxpr;
    haralickfeatures(13) = hf.sosvh;
    haralickfeatures(14) = hf.savgh;
    haralickfeatures(15) = hf.svarh;
    haralickfeatures(16) =hf.senth;
    haralickfeatures(17) =hf.dvarh;
    haralickfeatures(18) =hf.denth;
    haralickfeatures(19) =hf.inf1h;
    haralickfeatures(20) =hf.inf2h;
    haralickfeatures(21) =hf.indnc;
    haralickfeatures(22) =hf.idmnc;
    
    
    data.regs.info(ii,:) = CONST.regionScoreFun.props( mask, data.regs.props(ii) );
    data.regs.boun(ii) = any( [1==xx(1),1==yy(1),ss(1)==yy(end),ss(2)==xx(end)] );
 



end

