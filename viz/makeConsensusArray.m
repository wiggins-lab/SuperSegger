function [dataImArray] = makeConsensusArray( cellDir, CONST, skip, mag, fnum, clist )
% makeConsensusArray : Computes consensus dataImArray array used to make 
% consensus images and kymographs (average fluorescence localization).
%
% INPUT:
%   cellDir : (string) directory to load cell files from
%     CONST : (struct) Constants to use in calculation
%      skip : (integer) Use every skip images to make cons image
%       mag : (double) resize images by factor mag to generate cons image
% disp_flag : (flag) flag to show cells while they are processed
%
% OUPUT:
%   dataImArray =
%           towerCArray: cell array of tower of each single cell
%            towerArray: cell array of tower of each single cell
%        towerNormArray: cell array of tower of each single cell
%     intWeightMinArray: weight of each cell
%          cellArrayNum: number of each cell
%                imCell: {1x8 cell}
%            imCellNorm: {1x8 cell}
%              maskCell: {1x8 cell}
%           imCellScale: {1x8 cell}
%       imCellNormScale: {1x8 cell}
%         maskCellScale: {1x8 cell}
%             sumWeight: [1x8 double]
%          sumWeightMin: 368.8602
%            sumWeightS: [1x8 double]
%         sumWeightSMin: 0
%              numCells: 5
%                 ssTot: [40 1060]
%             imCellSum: {1x8 cell}

%  imMosaic : Image mosaic of cells that make up the consensus image
%   imColor : Color cons image (w/ black background)
%      imBW : Grayscale cons image
%     imInv : Color cons image (w/ white background)
%      kymo : Consensus Kymograph
%  kymoMask : Consensus Kymograph Cell mask
%         I : Fit of intensities to a model for polar localization
%
% Copyright (C) 2016 Wiggins Lab 
% Written by Stella Stylianidou, Paul Wiggins.
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

dataImArray = [];
if ~exist( 'skip', 'var' ) || isempty( skip )
    skip = 1;
end

% magnification : resizes the images of the cells to make them
% larger the image will be mag X larger in each dimension

if ~exist( 'mag', 'var' ) || isempty( mag )
    mag = 4;
end

if ~exist( 'fnum', 'var' ) || isempty( fnum )
    fnum = 1;
end

if exist( 'clist', 'var' ) && ~isempty( clist )
    clist = gate( clist );
else
    clist = [];
end

% show images in false color
if ~isfield(CONST.view, 'falseColorFlag' )
    CONST.view.falseColorFlag = false;
end

% Get the number of cells in the cell directory
cellNames = getCellFiles (cellDir,CONST);

numCells = numel(cellNames);

if numCells == 0
    disp ('No cells found')
    return
end

% put in a max cell number to stop the code stalling
if ~isfield(CONST.view, 'maxNumCell' ) || isempty(CONST.view.maxNumCell)
    CONST.view.maxNumCell = 100;
end

CONST.view.maxNumCell = min (CONST.view.maxNumCell ,numCells);
if ~isempty( CONST.view.maxNumCell )
    numCells = min([numCells, CONST.view.maxNumCell] );
end

disp( ['Computing consensus array (max cell number ',...
    num2str(numCells),')'] );

% Manage the waitbar
h = waitbar(0, 'Computation' );
cleanup = onCleanup( @()( delete( h ) ) );

% initialize the sum variables
dataImArray = intInit( numCells );
minimumLifetime = 4;
imArray = cell(1,numCells);
kk = 0;

firstCell = load([cellDir,cellNames{1}]);
if ~isfield(firstCell.CellA{1},'fluor1')
    disp ('no fluorescence found - exiting')
    return;
end

% loop through the cells to make the consensus image and the mosaic
for ii = 1:numCells
    
    % update status bar
    waitbar(ii/numCells,h);
    
    % load data and get file number
    cell_name = cellNames{ii};
    [data, dataImArray.cellArrayNum{ii}] = intLoader(cellDir, cell_name);
    data.CellA = data.CellA(1:skip:end);
    cur_cell_num = str2double(cell_name(isnum(cell_name)));
    aboveMinLifetime = numel(data.CellA) > minimumLifetime;
    inClist = isempty( clist ) || ismember( cur_cell_num, row(clist.data(:,1)));
        
    % Compute consensus images for cell in data
    if aboveMinLifetime && inClist
        kk = kk + 1;
        dataIm = makeTowerCons(data,CONST,1,false, skip, mag, fnum );
        
        % Scale images down to the original size
        imArray{kk} = imresize( dataIm.tower, 1/mag);
        
        % update the sums
        dataImArray = intUpdate( dataImArray, dataIm, kk );
    end
end

numCells = kk;

% close the status bar
close(h);

% normalize sums to convert sums to means.
dataImArray = intNormalize(dataImArray, numCells );

end

function dataArray = intUpdate( dataArray, data, jj )
% intUpdate : adds a new cell to the dataArray

T0 = numel( data.imCell );

if isempty( dataArray.sumWeight )
    dataArray.sumWeight    = zeros(1,T0);
    dataArray.sumWeightMin = 0;
end


% update im and mask sum
if isempty(dataArray.tower)
    dataArray.tower        = double( data.towerRaw );
    dSumWeightMin          = min(data.intWeight);
    dataArray.sumWeightMin = dSumWeightMin;
    dataArray.towerNormW    = dataArray.sumWeightMin *...
        double( data.towerNormRaw );
    dataArray.towerNorm    = double( data.towerNormRaw );
    dataArray.towerMask    = double( data.towerMask );
else
    dSumWeightMin = min(data.intWeight);
    dataArray.tower = dataArray.tower + double( data.towerRaw );
    dataArray.towerNormW = dataArray.towerNorm + ...
        dSumWeightMin * double( data.towerNormRaw );
    dataArray.towerNorm    = dataArray.towerNorm + ...
        double( data.towerNormRaw );
    dataArray.towerMask    = dataArray.towerMask + double( data.towerMask );
    dataArray.sumWeightMin = dataArray.sumWeightMin + dSumWeightMin;
end

ss = size(data.imCell{1});

dataArray.ssTot = [ max([dataArray.ssTot(1),ss(1)]),...
    dataArray.ssTot(2)+ss(2) ];

if isempty( dataArray.imCell )
    dataArray.imCell = data.imCell;
    dataArray.imCellNorm = data.imCellNorm;
    dataArray.maskCell = data.maskCell;
    dataArray.sumWeight = data.intWeight;
    for ii = 1:T0
        dataArray.imCellNorm{ii}  = data.imCellNorm{ii};
        dataArray.imCellNormW{ii} = data.imCellNorm{ii} ...
            * data.intWeight(ii);
    end
    
else
    for ii = 1:T0
        dataArray.imCell{ii} = dataArray.imCell{ii} + data.imCell{ii};
        dataArray.maskCell{ii} = dataArray.maskCell{ii} + data.maskCell{ii};
        dataArray.imCellNormW{ii} = dataArray.imCellNormW{ii} ...
            + data.imCellNorm{ii} * data.intWeight(ii);
        dataArray.imCellNorm{ii}  = dataArray.imCellNorm{ii} ...
            + data.imCellNorm{ii};
    end
    
    dataArray.sumWeight = dataArray.sumWeight + data.intWeight;
end

dataArray.towerCArray{jj} = data.towerC;
dataArray.towerArray{jj} = data.tower;
dataArray.towerNormArray{jj} = data.towerNorm;
dataArray.intWeightMinArray(jj) = min(data.intWeight);

end

function dataArray = intNormalize( dataArray, numCells )
% intNormalize : normalizes the quantities in the dataArray by the number
% of cells.

T0 = numel( dataArray.imCell );
dataArray.numCells = numCells;

dataArray.towerCArray = dataArray.towerCArray(1:numCells);
dataArray.towerArray = dataArray.towerArray(1:numCells);
dataArray.towerNormArray = dataArray.towerNormArray(1:numCells);
dataArray.intWeightMinArray = dataArray.intWeightMinArray(1:numCells);
dataArray.cellArrayNum = dataArray.cellArrayNum(1:numCells);

dataArray.tower = dataArray.tower/dataArray.numCells;
dataArray.towerMask = dataArray.towerMask/dataArray.numCells;
dataArray.towerNorm = dataArray.towerNorm/dataArray.numCells;
dataArray.towerNormW = dataArray.towerNormW/dataArray.sumWeightMin;

for ii = 1:T0
    dataArray.imCellSum{ii}  = dataArray.imCell{ii}/numCells;
    dataArray.maskCell{ii}  = dataArray.maskCell{ii}/numCells;
    weightNorm = sum( dataArray.imCellNorm{ii}(:).*dataArray.maskCell{ii}(:)/...
        sum(dataArray.maskCell{ii}(:)));
    weightNormW = sum(dataArray.imCellNormW{ii}(:).*dataArray.maskCell{ii}(:)/...
        sum(dataArray.maskCell{ii}(:)));
    dataArray.imCellNormW{ii} = dataArray.imCellNormW{ii}/weightNormW;
    dataArray.imCellNorm{ii}  = dataArray.imCellNorm{ii}/weightNorm;
end
end


function data = intInit( numCells )
% intInit : Initializes the arrays for the images.

data = [];
data.towerCArray = cell(1,numCells);
data.towerArray  = cell(1,numCells);
data.towerNormArray = cell(1,numCells);
data.intWeightMinArray  = zeros( 1,numCells);
data.cellArrayNum = cell(1,numCells);
data.tower           = [];
data.towerNorm       = [];
data.towerNormW      = [];
data.towerMask       = [];
data.imCell          = [];
data.imCellNorm      = [];
data.imCellNormW      = [];
data.maskCell        = [];
data.sumWeight       = [];
data.sumWeightMin    = [];
data.numCells        = numCells;
data.ssTot           = [0, 0];

end


function [ data, num_filename ] = intLoader( cellDir, filename )
% intLoader :loads the cell data and returns the cell's number

data = load( [cellDir, filename] );
lpos =  find(filename == 'l', 1, 'last' ); % finds last 'l'
ppos =  find(filename == '.', 1 ); % finds first '.'

if isempty( lpos ) || isempty( ppos )
    disp('Error in makeConsIm - could not find cell number' );
    return;
else
    num_filename = floor(str2num(filename(lpos+1:ppos-1)));
end

end