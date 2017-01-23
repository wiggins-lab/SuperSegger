function mask = makeBgMask(phase, filt_3, filt_4, AREA, CONST, crop_box)
% makeBgMask : makes a background mask for the phase image
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
crop_rad = CONST.superSeggerOpti.crop_rad;
THRESH1  = CONST.superSeggerOpti.THRESH1; % to remove background
THRESH2  = CONST.superSeggerOpti.THRESH2; % to remove background between cells
Amax     = CONST.superSeggerOpti.Amax;

% the large filter blurs the white halos with the cells
large_colony_fitler = imfilter(double(phase),filt_3,'replicate');
% smaller filter to blur any small structure
small_filter = imfilter(double(phase),filt_4,'replicate');

% Subtracting the two filters results in the cells regions as white.
tmp      = uint16(large_colony_fitler-small_filter);
nnn      = ag(tmp);

% Intensity thresholding to identify the cells from the background.
% Cell colonies are found by dilating and filling the areas below Amax.
maskth1    = imdilate(nnn>THRESH1,strel('disk',5));
maskth1    = fill_max_area( maskth1, Amax );

% Dilated mask for values above a lower threshold THRESH2.
% Emphasizes the structure in cells and background.
maskth2     = imdilate(nnn>THRESH2,strel('disk',1));

% Keep where the two masks match.
mask     = and(maskth2,maskth1);

% Dilate, fill the max area, and erode.
mask     = imdilate( mask, strel('disk',2));
mask     = fill_max_area( mask, Amax );
mask     = imerode( mask, strel('disk',crop_rad));

% Remove from mask objects with area smaller than AREA.
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