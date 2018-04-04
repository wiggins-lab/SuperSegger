function data  = updateRegionFields (data,CONST)
% updateRegionFields: computes the reg fields in the seg and err data structure.
% using the cell mask. It also initialized the fields to be used by the
% linking aglorithm.
%
% INPUT :
%       data    : region (cell) data structure (seg file)
%       CONST   : SuperSeggerOpti set parameters
%
% OUTPUT :
%       data : updated region (cell) data structure with regions field.
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

if ~isempty(data)
    % create regions
    data.regs.regs_label = bwlabel(data.mask_cell);
    num_regs =  max(data.regs.regs_label(:));
    
    data.regs.num_regs = num_regs;
    data.regs.props = regionprops( data.regs.regs_label, ...
        'BoundingBox','Orientation','Centroid','Area');
    NUM_INFO = CONST.regionScoreFun.NUM_INFO;
    data.regs.info = zeros( data.regs.num_regs, NUM_INFO );
    
    % initializing region fields
    data.regs.eccentricity = zeros(1,data.regs.num_regs);
    data.regs.L1 = zeros(1,data.regs.num_regs);
    data.regs.L2 = zeros(1,data.regs.num_regs);
    data.regs.contact = zeros(1,data.regs.num_regs);
    data.regs.neighbors = cell(1,data.regs.num_regs);
    data.regs.contactHist = zeros(1,data.regs.num_regs);
    data.regs.info= zeros(data.regs.num_regs,CONST.regionScoreFun.NUM_INFO);
    data.regs.scoreRaw = zeros(1,data.regs.num_regs);
    data.regs.score = zeros(1,data.regs.num_regs);
    data.regs.death = zeros(1,data.regs.num_regs); % Death/division time
    data.regs.deathF = zeros(1,data.regs.num_regs); % division in this frame
    data.regs.birth = zeros(1,data.regs.num_regs);% Birth Time: either division or appearance
    data.regs.birthF = zeros(1,data.regs.num_regs);% division in this frame
    data.regs.age = zeros(1,data.regs.num_regs);% cell age. starts at 1.
    data.regs.divide = zeros(1,data.regs.num_regs);% succesful division in this frame.
    data.regs.ehist = zeros(1,data.regs.num_regs);% True if cell has an unresolved error before this time.
    data.regs.stat0 = zeros(1,data.regs.num_regs); %  Successful division.
    data.regs.sisterID = zeros(1,data.regs.num_regs);% sister cell ID
    data.regs.motherID = zeros(1,data.regs.num_regs);% mother cell ID
    data.regs.daughterID = cell(1,data.regs.num_regs);% daughter cell ID
    data.regs.ID  = zeros(1,data.regs.num_regs); % cell ID number
    data.regs.error.label = cell(1,data.regs.num_regs);% err
    if ~isfield (data.regs,'ignoreError') || (numel (data.regs.ignoreError) ~= data.regs.num_regs)
        % a flag for ignoring the error in a region.
        data.regs.ignoreError = zeros(1,data.regs.num_regs);
    end
    % Notes that a region was linked manually.
    data.regs.manual_link.f = zeros(1,data.regs.num_regs);
    data.regs.manual_link.r = zeros(1,data.regs.num_regs);
    % go through the regions and update info,L1,L2 and scoreRaw.
    for ii = 1:data.regs.num_regs
        [xx,yy] = getBB(data.regs.props(ii).BoundingBox);
        mask = data.regs.regs_label(yy,xx)==ii;
        data.regs.info(ii,:) = CONST.regionScoreFun.props(mask,data.regs.props(ii) );
        data.regs.L1(ii)= data.regs.info(ii,1);
        data.regs.L2(ii)= data.regs.info(ii,2);
        if CONST.trackOpti.NEIGHBOR_FLAG
            try
                data.regs.neighbors{ii} = trackOptiNeighbors(data,ii);
                data.regs.contact(ii)  = numel(data.regs.neighbors{ii});
            catch
                disp('Error in neighbor calculation in updateRegionFields.m');
            end
        end
    end
    
    data.regs.scoreRaw = CONST.regionScoreFun.fun(data.regs.info, CONST.regionScoreFun.E);
    data.regs.score = data.regs.scoreRaw > 0;
    data.regs.eccentricity = drill(data.regs.props,'.MinorAxisLength')'...
        ./drill(data.regs.props,'.MajorAxisLength')';
end
end
