function mask = make_bg_mask(phase, filt_3, filt_4, AREA, CONST, crop_box)
% make_bg_mask : makes a background mask for the phase image
%
% INPUT :
%       phase : phase image
%       filt_3 : first filter with bigger size and std
%       filt_4 : second filter with smaller size and std
%       AREA : the minimum area of cells/cell clumps
%       CONST : segmentation constants
%       crop_box : information about alignement of the image
%
% OUTPUT :
%       mask : image masking background as black and cells as white
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.


crop_box = round( crop_box );
crop_rad = CONST.superSeggerOpti.crop_rad;
THRESH1  = CONST.superSeggerOpti.THRESH1; % to remove background
THRESH2  = CONST.superSeggerOpti.THRESH2; % to remove background between cells
Amax     = CONST.superSeggerOpti.Amax;

% applies the two filters
im_filt3 = imfilter(double(phase),filt_3,'replicate');
im_filt4 = imfilter(double(phase),filt_4,'replicate');

tmp      = uint16(-(im_filt4-im_filt3));
nnn      = autogain( tmp );

% dilated mask for values above high threshold
% this makes the white blobs bigger
fmask    = imdilate(nnn>THRESH1,strel('disk',5));
fmask    = fill_max_area( fmask, Amax );

% dilated mask for values above low threshold
% emphasizes the structure in cells and background
mask     = imdilate(nnn>THRESH2,strel('disk',1));

% add the two masks where they match
mask     = and(mask,fmask);

% dilate, fills the max area, and erodes
mask     = imdilate( mask, strel('disk',2));
mask     = fill_max_area( mask, Amax );
mask     = imerode( mask, strel('disk',crop_rad));

% remove from mask objects with area smaller than AREA
cc       = bwconncomp(mask);
stats    = regionprops(cc, 'Area');
idx      = find([stats.Area] > AREA);
mask     = ismember(labelmatrix(cc), idx);


if ~isempty( crop_box );
    mask(:,1:crop_box(2))   = false;
    mask(:,crop_box(4):end) = false;
    mask(1:crop_box(1),:)   = false;
    mask(crop_box(3):end,:) = false;
    
    mask(:,1:crop_box(2))   = false;
    mask(:,crop_box(4):end) = false;
    mask(1:crop_box(1),:)   = false;
    mask(crop_box(3):end,:) = false;
end

end

function mask_fill = fill_max_area( mask, maxA )
% fill_max_area 

fmask     = imfill( mask, 'holes' );
filled    = fmask.*~mask;
cc = bwconncomp(filled);
stats = regionprops(cc, 'Area');
idx = find([stats.Area] < maxA);
added = ismember(labelmatrix(cc), idx);
mask_fill = or(mask,added);

end