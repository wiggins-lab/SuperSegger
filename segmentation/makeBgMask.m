function mask = makeBgMask(phase, filt_3, filt_4, CONST, crop_box, pixelFactor)
% makeBgMask : makes a background mask for the phase image
%
% INPUT :
%       phase : phase image
%       filt_3 : first filter with bigger size and std
%       filt_4 : second filter with smaller size and std
%       CONST : segmentation constants
%       crop_box : information about alignement of the image
%
% OUTPUT :
%       mask : image masking background as black and cells as white
%
%
% Copyright (C) 2016 Wiggins Lab 
% Written by Paul Wiggins & Stella Stylianidou.
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


crop_box = round( crop_box );
crop_rad = round(CONST.superSeggerOpti.crop_rad/ pixelFactor);

THRESH1  = CONST.superSeggerOpti.THRESH1; % to remove background
THRESH2  = CONST.superSeggerOpti.THRESH2; % to remove background between cells
Amax     = CONST.superSeggerOpti.Amax / pixelFactor^2;
MIN_BG_AREA = CONST.superSeggerOpti.MIN_BG_AREA; % the minimum area of cells/cell clumps

disk_5 = round(5 / pixelFactor);
disk_1 = round(1 / pixelFactor);
disk_2 = round(2 / pixelFactor);
% applies the two filters
im_filt3 = imfilter(double(phase),filt_3,'replicate');
im_filt4 = imfilter(double(phase),filt_4,'replicate');

tmp      = uint16(-(im_filt4-im_filt3));
nnn      = ag(tmp);

% intensity thresholding to get the cell colonies
% dilating and filling the areas below Amax
maskth1    = imdilate(nnn>THRESH1,strel('disk',disk_5));
maskth1    = fill_max_area( maskth1, Amax );

% dilated mask for values above low threshold
% emphasizes the structure in cells and background
maskth2     = imdilate(nnn>THRESH2,strel('disk',disk_1));

% Logical and of two masks where the two masks match
mask     = and(maskth2,maskth1);

% dilate, fills the max area, and erodes
mask     = imdilate( mask, strel('disk',disk_2));
mask     = fill_max_area( mask, Amax );
mask     = imerode( mask, strel('disk',crop_rad));

% remove from mask objects with area smaller than AREA
cc       = bwconncomp(mask);
stats    = regionprops(cc, 'Area');
idx      = find([stats.Area] > MIN_BG_AREA);
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