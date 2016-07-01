function [ mask_mod ] = removeDebris( mask_bg, phase, aK )
% removeDebris : removes false positives from microcolony mask


debugFlag = false;

ss = size( phase );

label_bg = bwlabel( mask_bg );

pad = 6;

props = regionprops( label_bg,  'BoundingBox', 'Centroid' );

num_reg = numel( props );

I_K = nan( [1,num_reg] );
I_p = nan( [1,num_reg] );
I_m = nan( [1,num_reg] );



for ii = 1:num_reg
    
    bb = props(ii).BoundingBox;
    
    [xx,yy] = getBBpad( bb,ss,pad );
    
    
    mask_ii  = (label_bg( yy,xx)==ii);
    phase_ii = phase(yy,xx);
    aK_ii = aK(yy,xx);
    
    mask_p2 = bwmorph( mask_ii, 'dilate', 2 );
    mask_p1 = bwmorph( mask_ii, 'dilate', 1 );
    mask_m2 = bwmorph( mask_ii, 'erode', 2 );
    mask_m1 = bwmorph( mask_ii, 'erode', 1 );
    
    o_m = mask_m1-mask_m2;
    o_p = mask_p2-mask_p1;
    
    sss = sum(o_m(:));
    if sss > 0
        I_m(ii) = sum(o_m(:).*double(phase_ii(:)))/sss;
    end
    
    sss = sum(o_p(:));
    if sss > 0
        I_p(ii) = sum(o_p(:).*double(phase_ii(:)))/sum(o_p(:));
    end
    
    sss = sum(mask_ii(:));
    if sss > 0
        I_K(ii) = sum(mask_ii(:).*double(aK_ii(:)))/sss;
    end
    
    
end

DI = I_p-I_m;

keeper = find( and(DI>.2,I_K>5 ));
mask_mod = ismember( label_bg, keeper);





if debugFlag
    
    figure(8);
    clf;
        
    halo_keep = find( DI>.2 );
    pebble_keep = find( I_K>5 );
    
    imshow( comp( phase, mask_bg, ismember( label_bg,halo_keep ), ismember( label_bg,pebble_keep) ) );
       
    for ii = 1:num_reg
        text( props(ii).Centroid(1),props(ii).Centroid(2), [num2str( -I_m(ii)+I_p(ii), '%2.2g' ),',',num2str( I_K(ii), '%2.2g' )] );
    end    
    
    figure(9);
    clf    
    imshow( comp( phase, ~ismember( label_bg, keeper)));
end

end
