function data = killRegionsGUI (data, CONST, position1, position2)
% killRegionsGUI : used to remove regions from an image.
%
% INPUT :
%       data : data file with regions (seg/err file)
%       CONST : segmentation constants
% OUTPUT : 
%       data : data file without the selected region
%
% Copyright (C) 2016 Wiggins Lab 
% Written by Paul Wiggins, Stella Stylianidou.
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



if ~isempty(position1) && isempty(position2)
    % get closer region
    ss = size(data.phase);
    x = round(position1);
    tmp_cell_mask = zeros([51,51]);
    tmp_cell_mask(26,26) = 1;
    tmp_cell_mask = 8000-double(bwdist(tmp_cell_mask));

    rmin = max([1,x(2)-25]);
    rmax = min([ss(1),x(2)+25]);

    cmin = max([1,x(1)-25]);
    cmax = min([ss(2),x(1)+25]);

    rrind = rmin:rmax;
    ccind = cmin:cmax;

    pointSize = [numel(rrind),numel(ccind)];
    tmp_cell_mask = tmp_cell_mask(26-x(2)+rrind,26-x(1)+ccind).*data.mask_cell(rrind,ccind);
    try
        [~,ind] = max( tmp_cell_mask(:) );
    catch ME
        printError(ME);
    end

    [sub1, sub2] = ind2sub( pointSize, ind );
    ii = data.regs.regs_label(sub1-1+rmin,sub2-1+cmin);
    if ii ~=0
        [xx,yy] = getBB( data.regs.props(ii).BoundingBox);
        tmp_cell_mask = (data.regs.regs_label == ii);
        
        tmp_cell_mask = imdilate(tmp_cell_mask,strel('square',2));
        data.segs.segs_good(tmp_cell_mask) = 0;
        data.segs.segs_bad(tmp_cell_mask) = 0;
        data.segs.segs_3n(tmp_cell_mask) = 0;
        data.segs.segs_label(tmp_cell_mask) = 0;
        data.mask_bg(tmp_cell_mask)= 0;
        data.mask_cell(tmp_cell_mask) = 0;
        
        data = intMakeRegs( data, CONST);
    end
    
elseif ~isempty(position1) && ~isempty(position2)
    xy = [position1(1:2); position2(1:2)];
    xy = floor(xy);
    xmin = min(xy(:,1));
    xmin = max(xmin,1);
    xmax = max(xy(:,1));
    xmax = min(xmax,size(data.phase,2));
    ymin = min(xy(:,2));
    ymin = max(ymin,1);
    ymax = max(xy(:,2));
    ymax = min(ymax,size(data.phase,1));
    xx = xmin:xmax;
    yy = ymin:ymax;
    hold on
    plot( [xmin,xmax],[ymin,ymax] ,'r.');
    ind_segs = unique( data.segs.segs_label(yy,xx));
    ind_segs = ind_segs(logical(ind_segs));
    ind_segs = reshape(ind_segs,1,numel(ind_segs));

%     if isfield( data, 'regs' );
%         ind_regs = unique( data.regs.regs_label(yy,xx));
%         ind_regs = ind_regs(logical(ind_regs));
%         ind_regs = reshape(ind_regs,1,numel(ind_regs));
%         data = rmfield(data,'regs');
%     end

    mask = false(size(data.phase));

    for ii = ind_segs
        data.segs.info(ii,:)   = NaN;
        data.segs.score(ii)    = NaN;
        data.segs.scoreRaw(ii) = NaN;
        mask = logical(mask + (data.segs.segs_label==ii));
    end
    
    data.segs.segs_good(yy,xx)  = 0;
    data.segs.segs_bad(yy,xx)   = 0;
    data.segs.segs_3n(yy,xx)    = 0;
    data.segs.segs_label(yy,xx) = 0;
    data.mask_cell(yy,xx)       = 0;
    data.mask_bg(yy,xx)         = 0;

    data.segs.segs_good(mask)  = 0;
    data.segs.segs_bad(mask)   = 0;
    data.segs.segs_3n(mask)    = 0;
    data.segs.segs_label(mask) = 0;
    data.mask_cell(mask)       = 0;
    data.mask_bg(mask)         = 0;
    data = intMakeRegs( data, CONST);
end
