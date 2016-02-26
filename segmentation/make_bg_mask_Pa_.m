function mask4 = make_bg_mask_Pa_(phase_, filt_3, filt_4, AREA, CONST, crop_box)
% make_bg_mask_Pa : makes a background mask for the phase image
% used for Pseudomonas cells.
% To find cells in the middle of a colony
%
% INPUT :
%       phase : phase image
%       filt_3 : first filter used
%       filt_4 : second filter used
%       AREA : the minimum area of cells/cell clumps
%       CONST : segmentation constants
%       crop_box : information about alignement of the image
%
% OUTPUT :
%       mask : output cell mask
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.


SMOOTH_WIDTH    = CONST.superSeggerOpti.SMOOTH_WIDTH;
debug_flag = false;
crop_box = round( crop_box );
f = fspecial('gaussian', 11, SMOOTH_WIDTH);
phase = imfilter(phase_, f,'replicate');
crop_rad = CONST.superSeggerOpti.crop_rad;
THRESH1 = 50;
THRESH2  = CONST.superSeggerOpti.THRESH2;
Amax     = CONST.superSeggerOpti.Amax;

im_filt3 = imfilter(double(phase),filt_3,'replicate');
im_filt4 = imfilter(double(phase),filt_4,'replicate');

tmp      = uint16(-(im_filt4-im_filt3));
nnn      = autogain( tmp );

fmask    = imdilate(nnn>THRESH1,strel('disk',5));
fmask    = fill_max_area( fmask, Amax );

mask     = imdilate(nnn>THRESH2,strel('disk',1));
mask     = and(mask,fmask);

mask     = imdilate( mask, strel('disk',2));

mask     = fill_max_area( mask, Amax );
mask     = imerode( mask, strel('disk',crop_rad));

cc       = bwconncomp(mask);
stats    = regionprops(cc, 'Area');
idx      = find([stats.Area] > AREA);
mask     = ismember(labelmatrix(cc), idx);


if  debug_flag
    figure(1)
    showMask( phase, mask )
end


d = 20;
x = 1:d;
b = 1.5;

[X,Y] = meshgrid(x,x);
R2 = (X-d/2).^2 + (Y-d/2).^2;
Lap = (R2/b^4-2/b^2).*exp( -R2./2/b^2);
phase_lap = imfilter( double(ag(phase)), Lap, 'replicate' );

if  debug_flag
    figure(2);
    imshow( phase_lap.*~mask, [] );
    makehotcold;
end


% This cuts out bright spots from the mask
phase_ag = ag(phase_);
phase__ = magicContrastFast2(phase_ag, [], 3);
CUT_INT = 50;
mask_mod_50 = (phase__>CUT_INT);


CUT_INT = 20;
mask_mod_20 = (phase__>CUT_INT);
mask_20 = and(~mask,~mask_mod_20);
mask_50 = and(~mask,~mask_mod_50);


if ~isempty( crop_box );
    mask_50(:,1:crop_box(2))   = false;
    mask_50(:,crop_box(4):end) = false;
    mask_50(1:crop_box(1),:)   = false;
    mask_50(crop_box(3):end,:) = false;
    
    mask_20(:,1:crop_box(2))   = false;
    mask_20(:,crop_box(4):end) = false;
    mask_20(1:crop_box(1),:)   = false;
    mask_20(crop_box(3):end,:) = false;
end


regs_label = bwlabel( mask_50,4 );
regs_label_ = mask_20.*regs_label;

NN = max( regs_label(:) );
ttt = zeros( size(regs_label) );
phase_mean   = 0*(1:NN);
laplace_mean = 0*(1:NN);

empty_flag = phase_mean;

props = regionprops( regs_label, 'Centroid' );


if  debug_flag   
    figure(4);
    clf;
    showMask( phase, ~mask_50 );
    
    figure(2);
    clf;
    hold on;
end

CUT = 90;
xx = [ 111.6081,   96.2655, 89.7054, 73.3723, 0,       0];
yy = [ 256,        41.2595, 32.9214, 13.7545, 12.9384, 256];

for ii = 1:NN
    
    flag = (regs_label_==ii);    
    if sum( flag(:) )
        flag_map = (regs_label_==ii);
        phase_mean(ii)   = mean( abs(phase_ag(flag_map) ) );
        laplace_mean(ii) = mean( abs(phase_lap(flag_map) ) );
        empty_flag(ii) = false;
        
        if  debug_flag
            ttt(regs_label==ii) = phase_mean(ii);            
            x = phase_mean(ii);
            y =  laplace_mean(ii);            
            if inpolygon( x,y, xx, yy )
                figure(4)
                text(props(ii).Centroid(1), props(ii).Centroid(2),num2str(ii),  'Color', 'r' );               
                figure(2)
                plot( phase_mean(ii), laplace_mean(ii) );
                text( phase_mean(ii), laplace_mean(ii), num2str(ii),  'Color', 'r' );
            else                
                figure(4)
                text(props(ii).Centroid(1), props(ii).Centroid(2),num2str(ii),  'Color', 'b' );               
                figure(2)
                plot( phase_mean(ii), laplace_mean(ii) );
                text( phase_mean(ii), laplace_mean(ii), num2str(ii),  'Color', 'b' );
            end
            
        end
    else
        phase_mean(ii) = 0;
        laplace_mean(ii) = 0;
        empty_flag(ii) = true;
    end
end

if  debug_flag
    figure(2)
    plot( xx,yy,'g')
end



ind = find(inpolygon( phase_mean, laplace_mean, xx, yy ));
ind = [ find(empty_flag), ind];
gmask = ismember( regs_label, ind );
mask2 = ~(mask_50-gmask);
mask3 = mask2;

if ~isempty( crop_box )
    mask3(:,1:crop_box(2))   = false;
    mask3(:,crop_box(4):end) = false;
    mask3(1:crop_box(1),:)   = false;
    mask3(crop_box(3):end,:) = false;
end


mask3(mask_mod_50) = 0;

mask4 = ~fill_max_area( ~mask3, AREA );

if  debug_flag
    figure(3)
    showMask( abs( phase_), mask4 )
    drawnow;
    'hi'
end

end

function mask_fill = fill_max_area( mask, maxA )

fmask     = imfill( mask, 'holes' );
filled    = fmask.*~mask;
cc = bwconncomp(filled,4);
stats = regionprops(cc, 'Area');
idx = find([stats.Area] < maxA);
added = ismember(labelmatrix(cc), idx);
mask_fill = or(mask,added);

end