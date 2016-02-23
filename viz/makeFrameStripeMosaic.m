function [imTot] = makeFrameStripeMosaic( dirName, CONST, ll_, disp_flag )

if ~isfield( CONST.view, 'saveFiles' )

     CONST.view.saveFiles = false;
end


if ~isfield(CONST.view, 'falseColorFlag' )
    CONST.view.falseColorFlag = false;
end

if ~isfield(CONST.view, 'maxNumCell' )
    CONST.view.maxNumCell = [];
end

%CONST.view.maxNumCell

if ~exist( 'll_', 'var' )
    ll_ = [];
end



if ~isfield( CONST, 'view') || CONST.view.showFullCellCycleOnly
    contents = dir([dirName,filesep,'Cell*.mat']);
else
    contents = dir([dirName,filesep,'*ell*.mat']);
end


numCells = numel(contents);


% debug
if ~isempty( CONST.view.maxNumCell )
    numCells = min( [numCells, CONST.view.maxNumCell] );
end

disp( ['Numer of files: ', num2str( numCells ), '.'] );


cellArray = cell(1,numCells);
cellArrayPos = cell(1,numCells);
cellArrayNum = cell(1,numCells);


ssTot = [0,0];

if disp_flag
    h = waitbar(0, 'Computation' );
end
% debug
% numCells = 20;

for ii = 1:numCells
    
    if disp_flag
        waitbar(ii/numCells,h);
    end
    
    loadname = [dirName,filesep,contents(ii).name];
    
    data = load( loadname );
    
    lpos =  max(find(contents(ii).name == 'l'));
    ppos =  min(find(contents(ii).name == '.'));
    
    if isempty( lpos ) || isempty( ppos )
        disp('Error in makeFrameStripeMosaic' );
        return;
    else
        cellArrayNum{ii} = floor(str2num(contents(ii).name(lpos+1:ppos-1)));
    end
    
    %    cellArray{ii} = makeFrameStripe( data, CONST, 0, ll_ );
    tmp_im = makeFrameMosaic(data,CONST,1,false, ll_ );
    
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
    
    if CONST.view.falseColorFlag
        
        if ~isfield( CONST.view, 'background' );
            CONST.view.background = [0,0,0];
        end
        
        tmptmp = zeros( [ssTot(1), ssTot(2)] );
        
        imTot = uint8( cat( 3, tmptmp + CONST.view.background(1),...
            tmptmp + CONST.view.background(2),...
            tmptmp + CONST.view.background(3)));
        
    else
        del = 0.0;
        
        imTot = uint8(zeros( [ssTot(1), ssTot(2), 3] ));
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




