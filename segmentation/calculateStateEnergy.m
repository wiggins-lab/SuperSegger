function [regionScore,state] = calculateStateEnergy(cell_mask,vect,segs_list,data,xx,yy,CONST)
% calculateStateEnergy : calculates the state energy for modifying segments
% in a mask of a region.
%
% INPUT :
%       cell_mask : mask of regions of cells to be optimized
%       vect : logical for segments that are on or off
%       segs_list : list of ids of segments to be turned on and off
%       data : seg data file
%       xx : xx from bounding box of cell_mask
%       yy : yy from bounding box of cell_mask
%       CONST : segmentation constants
%
% OUTPUT :
%       regionScore : total score for modified mask
%       state : state information
%
%
% Copyright (C) 2016 Wiggins Lab 
% Written by Stella Stylianidou.
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


state =  caclulateState(cell_mask,vect,segs_list,data,xx,yy,CONST);
sigma = 1-2*double(state.seg_vect0);
allGoodScore = double(all(state.reg_E> 0));
allWidth = double(all(CONST.superSeggerOpti.MAX_WIDTH < state.short_axis_mean));
regionScore = mean(-state.reg_E)+ mean(sigma.*state.seg_E) - allGoodScore * 50 - allWidth * 10;

end

function [state] =  caclulateState(cell_mask,vect,segs_list,data,xx,yy,CONST)
% caclulateState : calculates the region scores for the modified cell mask 
% using the vect for the segments that will be on or off.
state.seg_E = data.segs.scoreRaw(segs_list)*CONST.regionOpti.DE_norm;
state.seg_vect0 = logical(vect);
state.mask = cell_mask;
num_segs = numel(vect);

for kk = 1:num_segs
    state.mask = state.mask - vect(kk)*(segs_list(kk)==data.segs.segs_label(yy,xx));
end

state.mask = state.mask>0;

regs_label_mod = (bwlabel(state.mask, 4));
regs_props_mod = regionprops( regs_label_mod,'BoundingBox','Orientation','Centroid','Area');
num_regs_mod = max(regs_label_mod(:));
info = zeros(num_regs_mod, CONST.regionScoreFun.NUM_INFO);
ss_regs_label_mod = size( regs_label_mod );

for mm = 1:num_regs_mod;
    [xx_,yy_] = getBBpad( regs_props_mod(mm).BoundingBox, ss_regs_label_mod, 1);
    mask = regs_label_mod(yy_,xx_)==mm;
    info(mm,:) = CONST.regionScoreFun.props( mask, regs_props_mod(mm));
end

state.reg_E = CONST.regionScoreFun.fun(info,CONST.regionScoreFun.E);
state.short_axis_mean = info(:,2);
state.long_axis = info(:,1);
end
