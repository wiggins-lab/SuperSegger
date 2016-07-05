function trackOptiStripSmall(dirname, CONST, disp_flag)
% trackOptiStripSmall : removes small regions and fills holes in the regions.
% It removes regions anything with area below  CONST.trackOpti.MIN_AREA
% that are probably not real, typically bubbles, dust, or minicells.
% It then creates a new cell mask and new region fields and resaves the seg
% file.
%
% INPUT :
%   dirname : seg folder eg. maindirectory/xy1/seg
%   CONST : Constants file
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


VERY_SMALL_AREA = CONST.trackOpti.MIN_AREA; % smaller that this is stripped
MIN_AREA = CONST.trackOpti.MIN_AREA_NO_NEIGH; % smaller that this is stripped if no neighbors
dirname = fixDir(dirname);
contents=dir([dirname '*_seg.mat']);
num_im = length(contents);

if ~exist('disp_flag','var') || isempty(disp_flag)
    disp_flag = 0;
end


if CONST.parallel.show_status
    h = waitbar( 0, 'Strip small cells.');
    cleanup = onCleanup( @()( delete( h ) ) );
else
    h = [];
end
SE = strel('disk',3);

for i = 1:num_im;
    
    if CONST.parallel.show_status
        waitbar((num_im-i)/num_im,h,['Strip small cells--Frame: ',num2str(i),'/',num2str(num_im)]);
    end
    
    data_c = loaderInternal([dirname,contents(i).name]);  % load data
    
    % remove small area regions
    regs_label = bwlabel(data_c.mask_cell);
    props = regionprops( regs_label, 'Area' );
    area_props = [props(:).Area];
    small = find(area_props<=MIN_AREA);
    
    small_new = [];
    % only if they can not connect to other cells
    for j = 1 : numel(small)
        id = small(j);
        mask = imdilate(regs_label == id,SE);
        neighbors = unique(regs_label(mask));
        neighbors = neighbors(neighbors~=id);
        neighbors = neighbors(neighbors~=0);
        if isempty(neighbors) || (area_props(id) < VERY_SMALL_AREA)
            small_new = [small_new,id];
        end
    end
    
    
    % remove the small from the mask
    cellmask_small= ismember( regs_label,small_new );
    cellmask_nosmall = data_c.mask_cell ;
    cellmask_nosmall (cellmask_small) = 0;
    
    data_c.mask_bg (cellmask_small) =0;
    
    % remove segments in small regions
    dilatedMask = imdilate(cellmask_nosmall, strel('square',4));
    data_c.segs.segs_3n(~dilatedMask) = 0;
    data_c.segs.segs_good(~dilatedMask) = 0;
    data_c.segs.segs_bad(~dilatedMask) = 0;
    
    
    % filling the holes in each region separetely
    ss = size( data_c.phase );
    regs_label = bwlabel( cellmask_nosmall );
    props = regionprops( regs_label, {'Area','BoundingBox'} );
    num_props = numel(props);
    mask_new = false(ss);
    
    for ii = 1:num_props
        [xx,yy] = getBBpad(props(ii).BoundingBox, ss,1);
        mask = (regs_label(yy,xx)==ii);
        mask__ = bwmorph(bwmorph( mask, 'dilate'), 'erode' );
        mask__ = imfill(mask__,'holes');
        mask_tmp = mask_new(yy,xx);
        mask_tmp(mask__) = true;
        mask_new(yy,xx) = mask_tmp;
    end
    
    
    if disp_flag
        imshow(cat(3,ag( data_c.mask_cell),ag(mask_new),ag(mask_new)));
        pause;
    end
    
    data_c.mask_cell = mask_new;
    
    % remake the regions
    data_c = intMakeRegs( data_c, CONST);
    
    % save the updated *seg.mat file
    dataname=[dirname,contents(i).name];
    save(dataname,'-STRUCT','data_c');
    
    
end

if CONST.parallel.show_status
    close(h);
end

end


function data = loaderInternal( filename )
data = load( filename );
end