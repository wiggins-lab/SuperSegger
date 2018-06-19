function [imTot] = makeFrameStripeMosaic( dirName, CONST, skip, disp_flag, clist, FLAGS )
% makeFrameStripeMosaic :  Creates a long stripe with all the cell towers.
%
% INPUT :
%       dirName : directory with cell files
%       CONST : segmentation parameters
%       skip : frames to be skipped
%       disp_flag : 1 to display image, 0 to not display iamge
% OUTPUT :
%       imTot : final image
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

if ~isfield( CONST.view, 'saveFiles' )
    CONST.view.saveFiles = false;
end


if ~isfield(CONST.view, 'falseColorFlag' )
    CONST.view.falseColorFlag = false;
end

if ~isfield(CONST.view, 'maxNumCell' )
    CONST.view.maxNumCell = 100;
end

if ~exist( 'skip', 'var' )
    skip = [];
end

if ~isfield( CONST, 'view') || CONST.view.showFullCellCycleOnly
    contents = dir([dirName,filesep,'Cell*.mat']);
else
    contents = dir([dirName,filesep,'*ell*.mat']);
end

numCells = numel(contents);
numCells = min( [numCells, CONST.view.maxNumCell] );
disp( ['Numer of files: ', num2str( numCells ), '.'] );

cellArray = cell(1,numCells);
cellArrayPos = cell(1,numCells);
cellArrayNum = cell(1,numCells);
ssTot = [0,0];

if disp_flag
    h = waitbar(0, 'Computation' );
    cleanup = onCleanup( @()( delete( h ) ) );
end

for ii = 1:numCells
    
    if disp_flag
        waitbar(ii/numCells,h);
    end
    
    loadname = [dirName,filesep,contents(ii).name];
    data = load( loadname );
    
    lpos =  find(contents(ii).name == 'l', 1, 'last' );
    ppos =  find(contents(ii).name == '.', 1 );
    
    if isempty( lpos ) || isempty( ppos )
        disp('Error in makeFrameStripeMosaic' );
        return;
    else
        cellArrayNum{ii} = floor(str2num(contents(ii).name(lpos+1:ppos-1)));
    end
    
    tmp_im = makeFrameMosaic(data,CONST,1,false, skip, FLAGS );
    
    if isfield( CONST.view, 'saveFiles' ) && CONST.view.saveFiles
        loadname(end-2:end)='png';
        imwrite( tmp_im, loadname, 'png' );
    else
        cellArray{ii} = tmp_im;
    end
    
    ss = size(cellArray{ii});
    ssTot = [ max([ssTot(1),ss(1)]), ssTot(2)+ss(2) ];
end

if disp_flag
    close(h);
end

if ~CONST.view.saveFiles

    
    tmptmp = ones( [ssTot(1), ssTot(2)] );

    if CONST.view.falseColorFlag
        
        if ~isfield( CONST.view, 'background' );
            CONST.view.background = [0,0,0];
        end
        
        imTot = comp( {tmptmp, CONST.view.background} ); 
        
    else
        del = 0.0;
        imTot = comp( {tmptmp, CONST.view.background} ); 

    end
    
    colPos = 1;
    
    for ii = 1:numCells
        ss = size(cellArray{ii});
        imTot(1:ss(1), colPos:(colPos+ss(2)-1), :) = cellArray{ii};
        cellArrayPos{ii} = colPos + ss(2)/2;
        colPos = colPos + ss(2);
    end
    
    clf;
    imshow( imTot );
    
    if CONST.view.falseColorFlag
        cc = 'w';
    else
        cc = 'b';
    end
    
    
    for ii = 1:numCells
        text( cellArrayPos{ii}, 0, num2str(cellArrayNum{ii}), 'Color', cc, 'HorizontalAlignment','center' );
    end
end
end
