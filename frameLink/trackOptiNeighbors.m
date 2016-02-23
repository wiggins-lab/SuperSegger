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
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

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






