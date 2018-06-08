function [ mask_bg_mod ] = intRemoveFalseMicroCol( mask_bg, phase, CONST )
% intRemoveFalseMicroCol : used to remove regions that are not cells.
% It removes anything with outline intensity below the background
% intensity.
%
% INPUT :
%   mask_bg : background mask of cells
%   phase : phase image
%   CONST : segmentation parameters
% OUTPUT :
%   mask_bg_mod : modified mask with removed regions
%
% Copyright (C) 2016 Wiggins Lab
% Written by Paul Wiggins.
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

% inner outline of the mask
mask_bg = logical(mask_bg);
mask_er = bwmorph(mask_bg, 'erode',1 ) - bwmorph(mask_bg, 'erode',2);

label_bg = bwlabel(mask_bg);
mask_er = logical(mask_er);
label_er = label_bg;
label_er(~mask_er) = 0;

% remove labels outline that are not in background mask
ind_bg = unique(label_bg(:));
ind_er = unique(label_er(:));
kill_l = ind_bg(~ismember(ind_bg, ind_er));

% mean intensity of outlines
props = regionprops(label_er, double(phase), 'MeanIntensity');
vals = [props.MeanIntensity];

% mean intesnity of cell and non cell regions
mean_noncell = mean(phase(~mask_bg));
mean_cell    = mean(phase(mask_bg));
dI = mean_noncell-mean_cell;

% indices of regions to be removed
ind = find(vals > mean_noncell-dI*CONST.superSeggerOpti.dIcellNonCell);
kill_list = [kill_l',ind];

mask_kill = ismember(label_bg, kill_list);
mask_bg_mod = mask_bg;
mask_bg_mod(mask_kill) = 0;



end

