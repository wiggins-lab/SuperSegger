function trackOptiGateCellFiles( dirname, dirname_cell, CONST, header, clist )
% trackOptiGateCellFiles : moves gated cell to different directory
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

if ~exist( notGateddirname, 'dir' )
    mkdir(notGateddirname(1:end-1));
end

contents = dir( [dirname_cell,'*ell*.mat'] );

if ~isempty( contents )
    movefile( [dirname_cell,'*ell*.mat'], notGateddirname )
end

if isempty( contents )
    contents = dir( [notGateddirname,'*ell*.mat'] );
end


if ~isempty( contents )
    numPad = sum( ismember(contents(1).name,'0123456789'));
    nCells = numel( ID_LIST );
    for ii = 1:nCells
        numStr = num2str(  ID_LIST(ii), ['%0',num2str(numPad),'d'] );     
        name1 = [notGateddirname,'Cell',numStr,'.mat'];
        name2 = [notGateddirname,'cell',numStr,'.mat'];
        if exist( name1, 'file' )
            movefile( name1, dirname_cell );
        elseif exist( name2, 'file' )
            movefile( name2, dirname_cell );
        end

    end
end
end