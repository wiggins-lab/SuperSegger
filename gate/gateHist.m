function [y,xx] = getHist(clist, ind, xx, cc)
% gateDot : used to make a histogram of the list of cells for the given indices.
% it first gate the list if there is a gate field in clist. 
%
% INPUT :
%   clist : list of cells with time-independent info
%   ind : indices of clist definition used for x and y label [x,y]
%   xx : number of bins for histogram or centroids
%   cc : color of plot
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.


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
    
    semilogy( xx, y, '.-', 'Color', cc );
    
    tmp = ishold;
    hold on;
    
    semilogy( mean(clist.data(:,ind))+[0,0], [max(y),min(y(y>0))], ':', 'Color', cc );
    if ~tmp
        hold off;
    end
    
    ylabel('Number of Cells');
    xlabel(clist.def{ind});
else
    disp('Error in getHist: too many indices in ind');
end



end