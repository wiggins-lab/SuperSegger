function ind  = trackOptiNeighbors(data,ii)
% trackOptiNeighbors : finds the neighbors for region ii
%
% INPUT : 
%       data : region (cell) data structure from file
%       ii : region id
% OUTPUT :
%       ind : indices of neighboring regions
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


persistent sdisk;

if isempty( sdisk )
    sdisk = strel( 'disk', 5 );
end

ss = size( data.regs.regs_label );
num_regs = data.regs.num_regs;
[xx,yy] = getBBpad( data.regs.props(ii).BoundingBox, ss, 6);
tmp_label = data.regs.regs_label(yy,xx);
mask = logical(imdilate( tmp_label==ii, sdisk));
ind = unique( tmp_label(mask ));
ind = ind(ind~=ii);
ind = ind(logical(ind));

end






