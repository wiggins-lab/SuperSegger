function [data] = regionOpti( data, disp_flag, CONST,header)
% regionOpti : Segmentaion optimization using region characteristics.
% It turns off on and off segments that have scores between two values in the
% constants (CONST.regionOpti.CutOffScoreHi and CONST.regionOpti.CutOffScoreLo)
% And uses systematic method, or simulated anneal, to find the optimal segments 
% configuration.
%
% INPUT :
%       data : data with segs field (.err data or .trk data)
%       disp_flag : display flag
%       CONST : segmentation constants
%       header : information string
% OUTPUT :
%       data : data structure with modified segments
%
% Copyright (C) 2016 Wiggins Lab 
% Written by Stella Styliandou & Paul Wiggins.
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

MAX_WIDTH = CONST.superSeggerOpti.MAX_WIDTH;
MIN_LENGTH = CONST.regionOpti.MIN_LENGTH;
CutOffScoreHi = 30; %CONST.regionOpti.CutOffScoreHi;
CutOffScoreLo = -30; %;CONST.regionOpti.CutOffScoreLo;
MAX_NUM_RESOLVE = CONST.regionOpti.MAX_NUM_RESOLVE;
MAX_NUM_SYSTEMATIC = CONST.regionOpti.MAX_NUM_SYSTEMATIC;
CONST.regionOpti.Emin  = .2;
DE_norm = CONST.regionOpti.DE_norm;
verbose = CONST.parallel.verbose;

if ~exist('header')
    header = [];
end

if nargin < 2 || isempty('dispp');
    disp_flag = 1;
end


% Turn on and off segs outside the cutoff.
segs_label = data.segs.segs_label;
segs_3n = data.segs.segs_3n;
segs_bad = 0*data.segs.segs_3n;
segs_good  = segs_bad;
segs_good_off  = segs_bad;
ss = size(segs_3n);
num_segs_ = numel(data.segs.score);

% segments above the high cutoff are added to segs_3n (hard segments,
% always on) and segments below the low cutoff are added to segs_bad, 
% segs label contains only segments that can be switched on / off.
% Both are removed from the local copy of segs_label, so they can not 
% be switched on and off.
above_Hi_ind = find(data.segs.scoreRaw > CutOffScoreHi);
below_Lo_ind = find(data.segs.scoreRaw < CutOffScoreLo);
segs_3n = segs_3n + double(ismember(segs_label, above_Hi_ind)); % high in 3n
segs_bad = double(ismember(segs_label, below_Lo_ind)); % low in bad
segs_label(logical(segs_3n+segs_bad)) = 0; % rest remain in segs_label

mask_regs = double((data.mask_bg-segs_3n)>0);
regs_label = (bwlabel( mask_regs, 4 ));
regs_props = regionprops( regs_label, 'BoundingBox','Orientation' );
num_regs   = max(regs_label(:));
segs_added = [];
if verbose
disp([header, 'rO: Got ',num2str(num_regs),' regions.']);
end
% Find short regions and add surrounding segments to segs_added
for ii = 1:num_regs
    
    [xx,yy] = getBBpad(regs_props(ii).BoundingBox,ss,2);
    tmp_mask = (regs_label(yy,xx)==ii);
    % calculates long and short axis of region
    [L1,L2] = makeRegSize (tmp_mask, regs_props(ii));
    debug_flag = 0;
    
    if debug_flag
        % image of phase and regions (green). Current region is shown in yellow
        figure;
        clf;
        imshow( cat(3,ag(regs_label==ii),ag(regs_label>0),ag(data.phase)), [])
        disp([num2str(L1),', ',num2str(L2)]);
    end
    
     
    % if region is shorter than MIN_LENGTH it adds the hard segments inside the
    % region in segs_added to be switched on / off.   
    if L1 < MIN_LENGTH;
        tmp_mask = imdilate(tmp_mask, strel('square',3));
        tmp_added = unique( tmp_mask.*data.segs.segs_label(yy,xx).*segs_3n(yy,xx));
        tmp_added = tmp_added(logical(tmp_added));
        tmp_added = reshape(tmp_added,1,numel(tmp_added));
        segs_added = [segs_added,tmp_added];
    end
    
end

% segs_added are surrounding segments of small regions
segs_added = unique(segs_added);
segs_added_ = ismember( data.segs.segs_label, segs_added); % image of segs_added segments
segs_3n(segs_added_) = 0; % removes segs_added_ from 3n

% adding them to the local copy of segs_label
segs_label(segs_added_) = data.segs.segs_label(segs_added_); 


% mask_regs is the super mask of all boundaries + segments that are
% permanently on
mask_regs = double((data.mask_bg-segs_3n)>0);
regs_label = (bwlabel( mask_regs, 4 )); % labels these regions.
regs_props = regionprops( regs_label, 'BoundingBox','Orientation'  );
num_regs   = max( regs_label(:));

rs_list = cell(1,num_regs);
ss = size(data.phase);

for ii = 1:num_regs
    [xx,yy] = getBBpad(regs_props(ii).BoundingBox,ss,2);
    cell_mask = (regs_label(yy,xx) == ii);
    
    % get the names of the remaining segments that are in this region.
    segs_list = unique( cell_mask.*segs_label(yy,xx));
    
    % get rid of zero and make sure the thing is a row vector.
    segs_list = segs_list(logical(segs_list));
    segs_list = reshape(segs_list,1,numel(segs_list));   
    rs_list{ii} = segs_list;
    
 
    % Turn on segments who would help resolve cells that are too wide
    % First turn everything on in the seg_list and check to make sure that
    % the regions are small enough.   
    tmp_segs = cell_mask-ismember( segs_label(yy,xx),segs_list );
    tmp_segs = double(tmp_segs>0);
    tmp_label = (bwlabel( tmp_segs, 4 ));
    tmp_props = regionprops( tmp_label, 'BoundingBox','Orientation'  );
    num_tmp   = max( tmp_label(:));    
    segs_added = [];
    
    for ff = 1:num_tmp
        
        tmp_mask = (tmp_label==ff);
        [L1,L2] = makeRegSize( tmp_mask, tmp_props(ff) );
        
        if L2 > MAX_WIDTH; % break down things larger than max width
            tmp_added = unique( tmp_mask.*data.segs.segs_label(yy,xx));
            tmp_added = tmp_added(logical(tmp_added));
            tmp_added = reshape(tmp_added,1,numel(tmp_added));
            segs_added = [segs_added,tmp_added];
        end
    end
    
    segs_list = unique([segs_list,segs_added]);

    
    if isempty(segs_list)
        [vect] = [];
    elseif numel(segs_list) > MAX_NUM_RESOLVE % use raw score
        if verbose
        disp([header, 'rO: Too many regions to analyze (',num2str(numel(segs_list)),').']);
        end
        [vect] = data.segs.scoreRaw(segs_list)>0;
    elseif numel(segs_list) > MAX_NUM_SYSTEMATIC % use simulated anneal
         if verbose
        disp([header, 'rO: Simulated Anneal : (',num2str(numel(segs_list)),' segments).']);
         end
        debug_flag = 0;
        [vect] = simAnnealMap( segs_list, data, cell_mask, xx, yy, CONST, debug_flag);
    else % use systematic
        if verbose 
        disp([header, 'rO: Systematic : (',num2str(numel(segs_list)),' segments).']);    
        end
        %tic;
        [vect] = systematic( segs_list, data, cell_mask, xx, yy, CONST);
       % toc;
    end
    
    num_segs = numel(segs_list);
    
    try
        segs_good(yy,xx) = segs_good(yy,xx) + ismember( data.segs.segs_label(yy,xx), segs_list(logical(vect)));
        segs_good_off(yy,xx) = segs_good_off(yy,xx) + ismember( data.segs.segs_label(yy,xx), segs_list(~vect));
    catch ME
        printError(ME);
    end
    
end

data.mask_cell = double((data.mask_bg-segs_3n-segs_good)>0);

% reset the seg scores incase you want to use this with segsManage
segs_on_ind = unique((~data.mask_cell).*data.segs.segs_label);
segs_on_ind = segs_on_ind(logical(segs_on_ind));
data.segs.score(segs_on_ind) = 1;
segs_off_ind = unique((data.mask_cell).*data.segs.segs_label);
segs_off_ind = segs_off_ind(logical(segs_off_ind));
data.segs.score(segs_off_ind) = 0;
cell_mask = data.mask_cell;
data.segs.segs_good   = double(data.segs.segs_label>0).*double(~data.mask_cell);
data.segs.segs_bad   = double(data.segs.segs_label>0).*data.mask_cell;

data = intMakeRegs( data, CONST );

if disp_flag
    back = double(0.7*ag( data.phase ));
    outline = imdilate( cell_mask, strel( 'square',3) );
    outline = ag(outline-cell_mask);
    segs_never = ((segs_bad-segs_good_off-segs_good)>0);
    segs_tried = ((segs_good_off + segs_good)>0);
    
    try
        figure(1);
        clf;
        
        imshow(uint8(cat(3,back + 1*double(outline),...
            back + 0.3*double(ag(segs_tried)),...
            back + 0.3*double(ag(segs_tried)).*double(segs_good_off) + 0.2*double(ag(~cell_mask)-outline) + 0.5*double(ag(segs_never)))));
    catch ME
        printError(ME);
    end
    drawnow;
    
end
end

