function [y,xx] = gateHist(clist, ind, xx, cc)
% gateHist : makes a histogram for the list of cells
% in the clist table for the given clist index.
% It first gates the list if there is a gate field in clist.
%
% INPUT :
%   clist : list of cells with time-independent info
%   ind : indices of clist definition used for x and y label [x,y]
%   xx : number of bins
%   cc : color of plot
%
% OUTPUT :
%   y : counts
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
NUM_BINS = round((sqrt(ss(1))));

if ~exist( 'xx', 'var' );
    xx = [];
end
if ~exist( 'cc', 'var' );
    cc = 'b';
end

nind = numel( ind );

if nind == 2
    if isempty( xx)
        [y,xx] =hist3( [clist.data(:,ind(2)),clist.data(:,ind(1))], round(([ NUM_BINS, NUM_BINS])/2) );
    else
        [y,xx] =hist3( [clist.data(:,ind(2)),clist.data(:,ind(1))], xx );
    end
    imagesc(xx{2},xx{1},y)
    set( gca, 'YDir', 'normal' );
    
    ylabel( clist.def{ind(2)} );
    xlabel( clist.def{ind(1)} );
    
elseif nind == 1
    if isempty( xx )
        [y,xx] = hist( clist.data(:,ind), NUM_BINS );
    else
        [y,xx] = hist( clist.data(:,ind), xx );
    end
    
    clf;
    
    if any(y==0)
        plot( xx, y, '.-', 'Color', cc );       
    else
        semilogy( xx, y, '.-', 'Color', cc );
    end
    
    tmp = ishold;
    hold on;
    
    if any(y==0)
        plot( mean(clist.data(:,ind))+[0,0], [max(y),min(y(y>0))], ':', 'Color', cc );
    else
        semilogy( mean(clist.data(:,ind))+[0,0], [max(y),min(y(y>0))], ':', 'Color', cc );       
    end
    
    if ~tmp
        hold off;
    end
    
    ylabel('Number of Cells');
    xlabel(clist.def{ind});
else
    disp('Error in getHist: too many indices in ind');
end



end