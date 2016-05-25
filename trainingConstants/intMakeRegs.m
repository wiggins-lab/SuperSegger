function data = intMakeRegs( data, CONST, mask_bad_regs, good_regs )
% intMakeRegs : creates info for bad regions or makes new regions
%
% INPUT :
%       data : cell file (seg/err file)
%       CONST : segmentation constants
%       mask_bad_regs : mask of bad regions (their score is set to 0)
%       good_regs : if 1 all scores are set to 1
% OUTPUT : 
%       data : cell file with region fields
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

E = CONST.regionScoreFun.E;

%sets all scores to 1
if ~exist('good_regs','var') || isempty(good_regs)
    good_regs = false;
end

ss = size( data.mask_cell );
NUM_INFO = CONST.regionScoreFun.NUM_INFO;
data.regs.regs_label = bwlabel( data.mask_cell );
data.regs.num_regs = max( data.regs.regs_label(:) );
data.regs.props = regionprops( data.regs.regs_label, ...
    'BoundingBox','Orientation','Centroid','Area');
data.regs.score  = ones( data.regs.num_regs, 1 );
data.regs.scoreRaw = ones( data.regs.num_regs, 1 );
data.regs.info = zeros( data.regs.num_regs, NUM_INFO );


for ii = 1:data.regs.num_regs
    
    [xx,yy] = getBBpad( data.regs.props(ii).BoundingBox, ss, 1);
    mask = data.regs.regs_label(yy,xx)==ii;
    data.regs.info(ii,:) = CONST.regionScoreFun.props( mask, data.regs.props(ii) );
    
    if exist( 'mask_bad_regs', 'var' ) && ~isempty( mask_bad_regs )
        data.regs.scoreRaw(ii) = CONST.regionScoreFun.fun(data.regs.info(ii,:), E);
        data.regs.score(ii) = data.regs.scoreRaw(ii) > 0;
        mask_ = mask_bad_regs(yy,xx);
        if any( mask(mask_) )
            data.regs.score(ii) = 0;
        end
    end
    
end

if ~exist( 'mask_bad_regs', 'var' ) || isempty( mask_bad_regs )
    if good_regs
        data.regs.scoreRaw = CONST.regionScoreFun.fun(data.regs.info, E)';
        data.regs.score = ones( data.regs.num_regs, 1 );
    else
        data.regs.scoreRaw = CONST.regionScoreFun.fun(data.regs.info, E)';
        data.regs.score =   data.regs.scoreRaw>0;
    end
end


end
