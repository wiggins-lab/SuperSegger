function [ mask_mod ] = removeDebris( mask_bg, phase, aK, CONST )
% removeDebris : removes false positives from microcolony mask
% It uses the brightness of the halos versus the darkness of the ecoli
% and the curvature of the image  
%
% INPUT : 
%   mask_bg : background mask.
%   phase : normalized phase image.
%   aK : texture/pebble measure (uses im_xx from the curveFilter).
% OUTPUT : 
%   mask_mod : modified mask.
% 
% Copyright (C) 2016 Wiggins Lab
% Written by Stella Stylianidou & Paul Wiggins.
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




INTENSITY_DIF = CONST.superSeggerOpti.INTENSITY_DIF;
PEBBLE_CONST = CONST.superSeggerOpti.PEBBLE_CONST;
debugFlag = false;

pad = 6;

ss = size( phase );
label_bg = bwlabel( mask_bg );
props = regionprops( label_bg,  'BoundingBox', 'Centroid' );
num_reg = numel( props );

%initialize
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
    
    
    inner_outline = mask_m1-mask_m2; 
    outer_outline = mask_p2-mask_p1;
    
    sss = sum(inner_outline(:));
    if sss > 0
        I_m(ii) = sum(inner_outline(:).*double(phase_ii(:)))/sss;
    end
    
    sss = sum(outer_outline(:));
    if sss > 0
        I_p(ii) = sum(outer_outline(:).*double(phase_ii(:)))/sum(outer_outline(:));
    end
    
    sss = sum(mask_ii(:));
    if sss > 0
        I_K(ii) = sum(mask_ii(:).*double(aK_ii(:)))/sss;
    end
    
    
end


DI = I_p-I_m; % change in intensity of outer and inner outline.
keeper = find(and(DI>INTENSITY_DIF,I_K>PEBBLE_CONST));
mask_mod = ismember(label_bg, keeper);


if debugFlag
    
    figure(8);
    clf;        

    halo_keep = find( DI> INTENSITY_DIF);
    pebble_keep = find( I_K> PEBBLE_CONST );
    comp( phase, ...
        {mask_bg,.3}, ...
        {ismember( label_bg,halo_keep ),.3},...
        {ismember( label_bg,pebble_keep),.3} );

       
    for ii = 1:num_reg
        text( props(ii).Centroid(1),props(ii).Centroid(2), [num2str( -I_m(ii)+I_p(ii), '%2.2g' ),',',num2str( I_K(ii), '%2.2g' )] );
    end    
    
    figure(9);
    clf    
    comp( phase, {~ismember( label_bg, keeper),.3} );
end

end
