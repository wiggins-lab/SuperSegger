function gateDot(clist, ind, cc)
% gateDot : used to make a dot plot of the list of cells for the given indices.
% It first gates the list if there is a gate field in clist. 
%
% INPUT :
%   clist : list of cells with time-independent info
%   ind : indices of clist definition used for x and y label [x,y]
%   cc : color of plot
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

clist = gate(clist);

if ~exist( 'cc', 'var' )
    cc = 'b';
end


nind = numel( ind );

if nind == 2
    plot( clist.data(:,ind(1)), clist.data(:,ind(2)), '.', 'Color', cc );
    ylabel( clist.def{ind(2)} );
    xlabel( clist.def{ind(1)} );
else
    disp('Error in the number of indices' );
end


end