function [clist0] = gate(clist)
% gate : used to gate the list of cells.
% This is done according to an already made gate field in clist
%
% INPUT :
%   clist : table of cells and variables with gate field
% OUTPUT :
%   clist0 : table of cells that passed the gate
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

clist0 = [];
clist0.def = clist.def;

ss = size(clist.data);
inflag = true(ss(1),1);

if isfield( clist, 'idExclude' )
    inflag = ~ismember(clist.data(:,1), clist.idExclude);
end

if isfield( clist, 'idInclude' )
    inflag = ismember(clist.data(:,1), clist.idInclude);
end

if isfield( clist, 'gate' ) && ~isempty ('gate.clist')
    for ii = 1:numel(clist.gate)
        if numel(clist.gate(ii).ind) == 2
            inflag = and(inflag, inpolygon( clist.data(:,clist.gate(ii).ind(1)), ...
                clist.data(:,clist.gate(ii).ind(2)), ...
                clist.gate(ii).xx(:,1), clist.gate(ii).xx(:,2) ));
        else
            x = clist.data(:,clist.gate(ii).ind);
            inflag = and( inflag, and( x > min(clist.gate(ii).x), x < max(clist.gate(ii).x)));
        end
    end
end


clist0.data = clist.data(inflag,:);
if isfield(clist,'data3D')
    clist0.def3d = clist.def3d;
    clist0.data3D = clist.data3D(inflag,:,:);
end
end