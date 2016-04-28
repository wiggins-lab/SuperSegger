function trackOptiGateCellFiles(dirname_cell, clist )
% trackOptiGateCellFiles : moves cells not passing the gate to separate directory
% the cells that pass the gate remain in the dirname_cell directory.
% For the clist passed, create a gate for the cells that you would like to move
% the notGated directory.
%
% INPUT :
%       dirname_cell : directory with cell files
%       clist : array with non time dependent information of cells
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


if ~exist( 'clist', 'var') || isempty( clist) || isempty(clist.data)
    ID_LIST = [];
else
    clist = gate(clist);
    ID_LIST = clist.data(:,1);
end

notGateddirname = [dirname_cell,'notGated',filesep];

if ~exist( notGateddirname, 'dir' ) % create notGated directory
    mkdir(notGateddirname(1:end-1));
end

contents = dir( [dirname_cell,'*ell*.mat'] );

if ~isempty( contents ) % move all cell files to notGated directory
    movefile( [dirname_cell,'*ell*.mat'], notGateddirname ) 
end

if isempty( contents ) % check gated directory - maybe it was gated already in the past
    contents = dir( [notGateddirname,'*ell*.mat'] );
end


if ~isempty( contents )
    numPad = sum( ismember(contents(1).name,'0123456789')); % how many numbers in cell id's name
    nCells = numel( ID_LIST );
    for ii = 1:nCells % go through every cell
        numStr = num2str(  ID_LIST(ii), ['%0',num2str(numPad),'d'] );     
        nameC = [notGateddirname,'Cell',numStr,'.mat'];
        namec = [notGateddirname,'cell',numStr,'.mat'];
        if exist( nameC, 'file' )
            movefile( nameC, dirname_cell );
        elseif exist( namec, 'file' )
            movefile( namec, dirname_cell );
        end

    end
end
end