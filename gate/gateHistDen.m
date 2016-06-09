function [y,xx] = gateHistDen(clist, ind, cc,xx)
% gateHistDen : makes a probability density plot for the list of cells
% in the clist table for the given clist index.
% It first gates the list if there is a gate field in clist.
%
% INPUT :
%   clist : list of cells with time-independent info
%   ind : indices of clist definition used for x and y label [x,y]
%   xx : array of two values, the subtraction of which is the size of each bin.
%   cc : color of plot
% OUTPUT :
%   y : probability density
%   xx : values of clist(ind)
%
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
ss = size( clist.data );
NUM_CELLS = ss(1);
NUM_BINS = round(sqrt(NUM_CELLS));

if ~exist( 'xx', 'var' )
    xx = [];
else
    dx = xx(2) - xx(1);
    start = min(clist.data(:,ind));
    stop = max(clist.data(:,ind));
    xx = start:dx:stop;
end

if ~exist( 'cc', 'var' ) || isempty(cc)
    cc = 'b';
end


nind = numel( ind );

if nind == 1
    if isempty( xx )
        [y,xx] = hist(clist.data(:,ind), NUM_BINS );
    else
        [y,xx] = hist(clist.data(:,ind), xx );
    end
    
    dx = xx(2)-xx(1);
    plot( xx, y/dx/NUM_CELLS, '.-', 'Color', cc );
    tmp = ishold;
    hold on
    plot( mean(clist.data(:,ind))+[0,0], [max(y),min(y(y>0))]/dx/NUM_CELLS, ':', 'Color', cc );
    
    if ~tmp
        hold off;
    end
    
    ylabel('Population Density');
    xlabel(clist.def{ind});
else
    disp('Error in getHist: too many indices in ind');
end



end