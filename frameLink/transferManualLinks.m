function [data_r, data_f, c_map, c_manual_link] = transferManualLinks (...
    data_c,data_r, data_f, resetRegions)
% transferManualLinks: Transfers the manual links to the new region ids
% if the mask_cell of data_c has changed and the region ids in data_c have
% changed.
%
% Copyright (C) 2016 Wiggins Lab
% Written by Silas Boye Nissen & Stella Stylianidou.
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


new_data = data_c;
new_data.regs.regs_label = bwlabel(new_data.mask_cell);
num_new_regs =  max(new_data.regs.regs_label(:));

% Initialize
c_manual_link.f = zeros(1,num_new_regs);
c_manual_link.r = zeros(1,num_new_regs);
c_map.f = cell(1,num_new_regs);
c_map.r = cell(1,num_new_regs);
if ~isfield (data_c.regs, 'manual_link')
    data_c.regs.manual_link = c_manual_link;
end
if ~isfield (data_c.regs, 'map')
    data_c.regs.map = c_map;
end

manual_cell_ids_r = find(data_c.regs.manual_link.r);
manual_cell_ids_f = find(data_c.regs.manual_link.f);
if (~resetRegions)
    % Regions were not reset, store original map and manual link
    c_map = data_c.regs.map;
    c_manual_link = data_c.regs.manual_link;
else
    % Regions were reset. Get the new regions ids and change the map and
    % manual links to the new regions ids.
    % From current frame cells to reverse frame.
    for jj = manual_cell_ids_r
        reverse_link = data_c.regs.map.r{jj};
        [new_region_id,~,~] = getClosestCellToPoint(new_data,data_c.regs.props(jj).Centroid);
        % Replace jj with new_region id in the mapping in data_r.
        data_r.regs.map.f{reverse_link} (data_r.regs.map.f{reverse_link}==jj) = new_region_id;
        data_r.regs.manual_link.f(reverse_link) = 1;
        c_map.r{new_region_id} = reverse_link;
        c_manual_link.r(new_region_id) = 1;
    end
    
    % From current frame cells to forward frame.
    for ll = manual_cell_ids_f
        forward_link = data_c.regs.map.f{ll};
        [new_region_id,~,~] = getClosestCellToPoint(new_data,data_c.regs.props(ll).Centroid);
        for f = forward_link
            data_f.regs.map.r{f} = new_region_id;
            data_f.regs.manual_link.r(f) = 1;
        end
        c_map.f{new_region_id} = forward_link;
        c_manual_link.f(new_region_id) = 1;
    end
end

end

