function x = plotClist3D(clist, ind)
% gateHist : makes a plot for from the 3dclist for all cells with time.
% It uses the given clist index. It first gates the list if there is a
% gate field in clist.
%
% INPUT :
%   clist : list of cells with time-independent info
%   ind : indices of clist 3d definition used for x and y label [x,y]
%
% OUTPUT :
%   x : plot array
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


clist = gate(clist);
nind = numel(ind);

if ~isfield(clist,'data3D')
    disp('3D clist is not supported')
    return;
end

if nind == 1
    clf;
    x = squeeze(clist.data3D(:,ind,:))';
    plot(x);
    set( gca, 'YDir', 'normal' );
    if isfield (clist,'def3d')
        ylabel( clist.def3d{ind} );
    elseif isfield (clist,'def3D')
        ylabel( clist.def3D{ind} );
    end
    xlabel( 'Time (frame)' );
else
    disp('Error in plotClist3D: too many indices in ind');
end



end