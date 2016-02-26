function trackOptiGateCellFiles(dirname_cell, clist )
% trackOptiGateCellFiles : moves cells not passing the gate to separate directory
% the cells that pass the gate remain in the dirname_cell directory.
% For the clist passed, create a gate for the cells that you would like to move
% the notGated directory.
%
% INPUT :
%       dirname: seg folder eg. maindirectory/xy1/seg % not used
%       dirname_cell : directory with cell files
%       CONST: are the segmentation constants. % not used
%       header : string displayed with information % not used
%       clist : array with non time dependent information of cells
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.


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