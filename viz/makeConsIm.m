function [ imMosaic, imColor, imBW, imInv, kymo, kymoMask, I,...
    kymoMax, kymoMaskMax, imMosaic10, imBWunmasked, imBWmask, hotPix, ...
    AA, BB ] = makeConsIm( dirName, CONST, skip, mag, disp_flag )
% makeConsIm Computes consensus fluorescence localization from cells in a cell files
%
% INPUT:
%   dirName : (string) directory to load cell files from
%     CONST : (struct) Constants to use in calculation
%      skip : (integer) Use every skip images to make cons image
%       mag : (double) resize images by factor mag to generate cons image
% disp_flag : (flag) flag to show cells while they are processed
%
% OUPUT:
%  imMosaic : Image mosaic of cells that make up the consensus image
%   imColor : Color cons image (w/ black background)
%      imBW : Grayscale cons image
%     imInv : Color cons image (w/ white background)
%      kymo : Consensus Kymograph
%  kymoMask : Consensus Kymograph Cell mask
%         I : Fit of intensities to a model for polar localization
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.


del = 0.0;
imMosaic10 = [];
%disp_flag = 1;

if ~exist( 'skip', 'var' ) || isempty( skip )
    skip = 1;
end

if ~exist( 'mag', 'var' ) || isempty( mag )
    mag = 4;
end


% show images in false color
if ~isfield(CONST.view, 'falseColorFlag' )
    CONST.view.falseColorFlag = false;
end




% Get the number of cells in the cell directory
if ~isfield( CONST, 'view') || CONST.view.showFullCellCycleOnly
    contents = dir([dirName,filesep,'Cell*.mat']);
else
    contents = dir([dirName,filesep,'*ell*.mat']);
end
numCells = numel(contents);


% put in a max cell number to stop the code stalling
if ~isfield(CONST.view, 'maxNumCell' )
    CONST.view.maxNumCell = [];
end


% force to do only first 1000
CONST.view.maxNumCell = 1000;


if ~isempty( CONST.view.maxNumCell )
    numCells = min( [numCells, CONST.view.maxNumCell] );
end
% debug
% numCells = min([numCells,5]);
disp( ['Running consensus (max cell number ',...
    num2str(numCells),')'] );

%        ssTot : Keep track of the total size of the tower mosaic.
ssTot = [0,0];


% Manage the waitbar
%if disp_flag
h = waitbar(0, 'Computation' );
%end

% initialize the sum variables
dataImArray = intInit( numCells );
%         imSum : Summed up imBW
%       maskSum : Summed up maskCons
%     imCellSum : Summed up imCell
%   maskCellSum : Summed up maskCell
%    imCellSSum : Summed up imCellS
%  maskCellSSum : Summed up maskCellS
%     imNormSum : Summed up Normed Fluor (imBW)
% imCellNormSum : Summed up Normed Fluor (imCell)
%         ssTot : Im size of tower mosaic of cell contributing to cons


% loop through the cells to make the consensus image and the mosaic



imArray = cell(1,numCells);

ii_ = 0;


for ii = 1:numCells
    
    % update status bar
    %if disp_flag
    waitbar(ii/numCells,h);
    %end
    
    
    % load data and get file number
    [data, dataImArray.cellArrayNum{ii}] = intLoader( dirName, contents(ii).name );
    
    
    
    data.CellA = data.CellA(1:skip:end);
    
    %%
    
    % mag is used to resize the images of the cells to make them larger.
    % the image will be mag X larger in each dimension
    mag = 4;
    
    
    % Compute consensus images for cell in data
    
    if numel(data.CellA) > 4
        
        
        ii_ = ii_ + 1;
        
        
        dataIm = makeTowerCons(data,CONST,1,false, skip, mag );
        
        
        %     imshow([dataIm.towerNorm],[]);
        %     min(dataIm.intWeight)
        %     pause(.2)
        %
        %     if min(dataIm.intWeight) < 0
        %         keyboard;
        %     end
        %
        % Scale images down to the original size
        imArray{ii_} = imresize( dataIm.tower, 1/mag);
        
        % update the sums
        dataImArray = intUpdate( dataImArray, dataIm, ii_  );
        
    end
end

numCells = ii_;
imArray = imArray(1:numCells);

% close the status bar
if disp_flag
    close(h);
end

% Principal Component Analysis of Grayscale cell tower images
if numel( imArray ) > 0
    [AA,BB] = pcanal4( imArray, disp_flag );
end

%% normalize sums to convert sums to means.
dataImArray = intNormalize( dataImArray, numCells );

%% reform tower images here
% tmp = towerMergeImages( dataImArray.imCellNorm, dataImArray.maskCell, ssCell, xdim, skip, mag, CONST );
% Merge the images from the arrays into a single image
T0 = numel( dataImArray.imCell );

if  ~T0
    I = [];
    kymo = [];
    kymoMask = [];
    kymoMax = [];
    kymoMaskMax = [];
    imMosaic = [];
    imColor = [];
    imBW = [];
    imInv = []
    imBWunmasked = [];
    imBWmask = [];
    imMosaic10 = [];
    hotPix = [];
else
    
    for jj = 1:T0
        ssCell{jj} = size(  dataImArray.imCell{jj} );
    end
    
    [ bs_, bs_, dataImArray.tower, dataImArray.towerMask ] = ...
        towerMergeImages( dataImArray.imCell, dataImArray.maskCell, ssCell, 1, skip, mag, CONST );
    %dataImArray.tower = dataImArray.tower.*dataImArray.towerMask;
    
    % Merge the images from the arrays into a single image
    [ bs_, bs_, dataImArray.towerNorm, dataImArray.towerMask ] = ...
        towerMergeImages( dataImArray.imCellNorm, dataImArray.maskCell, ssCell, 1, skip, mag, CONST );
    %dataImArray.towerNorm = dataImArray.towerNorm.*dataImArray.towerMask;
    
    %%
    numIm = numel( dataImArray.tower );
    
    if numIm  > 0
        %% make the color map for the color image
        [ imMosaic, imColor, imBW, imInv, imMosaic10 ] = intDoMakeImage( dataImArray.towerNorm, ...
            dataImArray.towerMask, dataImArray.towerCArray, ...
            dataImArray.ssTot, dataImArray.cellArrayNum, CONST, disp_flag );
        %  imMosaic : Mosaic of towers of cells that make up the consensus image
        %   imColor : Color cons image (w/ black background)
        %      imBW : Grayscale cons image
        %     imInv : Color cons image (w/ white background)
        imBWunmasked = dataImArray.towerNorm;
        imBWmask     = dataImArray.towerMask;
        
        %% make the kymo
        % [ kymo, kymoMask, kymoMax, kymoMaskMax ] = ...
        %     intMakeKymo( dataImArray.imCellNormScale, dataImArray.maskCellScale, ...
        %     disp_flag );
        %      kymo : Consensus Kymograph
        %  kymoMask : Consensus Kymograph Cell mask
        
        %% make the kymo
        [ kymo, kymoMask, kymoMax, kymoMaskMax ] = ...
            intMakeKymo( dataImArray.imCellNorm, dataImArray.maskCell, ...
            disp_flag );
        %      kymo : Consensus Kymograph
        %  kymoMask : Consensus Kymograph Cell mask
        %% do the kymo fit
        [I] = fitKymo4( kymo, kymoMask, disp_flag );
        %         I : Fit of intensities to a model for polar localization
        
        %hotPix = getHotPixelsCons( dataImArray.imCell, dataImArray.maskCell  );
        hotPix = [] ;
        %% Make hot pixel
        
        
    else
        I = [];
        kymo = [];
        kymoMask = [];
        kymoMax = [];
        kymoMaskMax = [];
        imMosaic = [];
        imColor = [];
        imBW = [];
        imInv = []
    end
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% intDoMakeImage
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ imMosaic, imColor, imBW, imInv, imMosaic10] = ...
    intDoMakeImage( imSum, maskSum, cellArray, ssTot, cellArrayNum, ...
    CONST, disp_flag )




numCells = numel( cellArray );


% cellArrayPos: location in the image of each panel of the mosaic.
cellArrayPos = cell(1,numCells);

% make the color map for the color image
%persistent colormap_;
%if isempty( colormap_ )
colormap_ = jet(256);
%end


imTmp = 255*doColorMap( ag(imSum, min(imSum( maskSum>.95 )), max(imSum( maskSum>.95 )) ), colormap_ );
mask3 = cat( 3, maskSum, maskSum, maskSum );
imColor = uint8(uint8( double(imTmp).*mask3));
imBW  = uint8( double(ag(imSum, min(imSum( maskSum>.95 )), max(imSum( maskSum>.95 )) )) .* maskSum );

imTmp = 255*doColorMap( ag(imSum, min(imSum( maskSum>.95 )), max(imSum( maskSum>.95 )) ), 1-colormap_ );
mask3 = cat( 3, maskSum, maskSum, maskSum );
imInv = 255-uint8(uint8( double(imTmp).*mask3));

if disp_flag
    figure(5)
    clf;
    imshow( imColor);
    drawnow;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if disp_flag
    figure(1);
end

del = 1;

if CONST.view.falseColorFlag
    imMosaic = uint8(zeros( [ssTot(1), ssTot(2), 3] )) + del*255;
else
    imMosaic = uint8(zeros( [ssTot(1), ssTot(2), 3] ));
end


colPos = 1;

width10 = 0;
time10  = 0;

for ii = 1:numCells
    
    
    ss = size(cellArray{ii});
    
    
    if ii <= 10
        width10 = width10 + ss(2);
        time10  = max([ss(1),time10]);
    end
    
    imMosaic(1:ss(1), colPos:(colPos+ss(2)-1), :) = cellArray{ii};
    
    cellArrayPos{ii} = colPos + ss(2)/2;
    
    
    colPos = colPos + ss(2);
    
end

imMosaic10 = imMosaic( 1:time10, 1:width10, : );

if disp_flag
    clf;
    imshow( imMosaic );
    
    if CONST.view.falseColorFlag
        cc = 'w';
    else
        cc = 'b';
    end
    
    
    for ii = 1:numCells
        text( cellArrayPos{ii}, 0, num2str(cellArrayNum{ii}), 'Color', cc, ...
            'HorizontalAlignment','center' );
    end
end

%'hi'
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% intMakeKymo
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ kymo,kymoMask,kymoMax, kymoMaskMax ] = ...
    intMakeKymo( imCellS, maskCellS, disp_flag )

T0 = numel( imCellS );
mag = 4;

if T0 > 0
    
    ss    = size( imCellS{1} );
    ssMax = size( imresize(imCellS{1}, 1/mag) );
    
    kymo    = zeros( [ss(2), T0] );
    kymoMax = zeros( [ssMax(2), T0] );
    
    kymoMask    = kymo;
    kymoMaskMax = kymoMax;
    
    for ii = 1:T0
        maskCellS{ii}( isnan( maskCellS{ii} ) ) = 0;
        imCellS{ii}( isnan( imCellS{ii} ) )     = 0;
        
        %kymo(:,ii) = sum(maskCellS{ii}.*imCellS{ii},1)./sum(maskCellS{ii});
        kymo(:,ii) = sum(maskCellS{ii}.*imCellS{ii},1);
        kymoMask(:,ii) = sum(maskCellS{ii},1);
        
        kymoMax(:,ii)       = max(imresize( maskCellS{ii}.*imCellS{ii},...
            1/mag ), [], 1);
        kymoMaskMax(:,ii)   = max(imresize( maskCellS{ii}, 1/mag ),...
            [], 1);
        
    end
end

if disp_flag
    figure(7);
    clf;
    
    ss = size( kymo );
    tt = (0:(ss(2)-1))/(ss(2)-1);
    xx = (0:(ss(1)-1))/(ss(1)-1);
    
    
    imagesc( tt,xx, colorize(kymo,kymoMask,[],[0.33,0.33,0.33]) );
    set(gca, 'YDir', 'normal' );
    xlabel( 'Time (Cell Cycle)');
    ylabel( 'Relative Long Axis Position');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% intUpdate
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function dataArray = intUpdate( dataArray, data, jj )


T0 = numel( data.imCell );

if isempty( dataArray.sumWeight );
    dataArray.sumWeight    = zeros(1,T0);
    dataArray.sumWeightMin = 0;
    
    dataArray.sumWeightS    = zeros(1,T0);
    dataArray.sumWeightSMin = 0;
end


% update im and mask sum
if isempty( dataArray.tower )
    dataArray.tower        = double( data.towerRaw );
    dataArray.sumWeightMin = min(data.intWeight);
    
    dataArray.towerNorm    = dataArray.sumWeightMin *...
        double( data.towerNormRaw );
    
    dataArray.towerMask    = double( data.towerMask );
else
    dSumWeightMin = min(data.intWeight);
    
    dataArray.tower        = dataArray.tower     + double( data.towerRaw );
    dataArray.towerNorm    = dataArray.towerNorm + ...
        dSumWeightMin * double( data.towerNormRaw );
    
    dataArray.towerMask    = dataArray.towerMask + double( data.towerMask );
    
    dataArray.sumWeightMin = dataArray.sumWeightMin + dSumWeightMin;
end

ss = size(data.imCell{1});

dataArray.ssTot = [ max([dataArray.ssTot(1),ss(1)]),...
    dataArray.ssTot(2)+ss(2) ];

if isempty( dataArray.imCell )
    dataArray.imCell         = data.imCell;
    dataArray.imCellNorm     = data.imCellNorm;
    dataArray.maskCell       = data.maskCell;
    dataArray.imCellScale    = data.imCellScale;
    dataArray.maskCellScale  = data.maskCellScale;
    
    for ii = 1:T0
        dataArray.imCellNorm{ii} = data.imCellNorm{ii} ...
            * data.intWeight(ii);
        dataArray.imCellNormScale{ii} = data.imCellNormScale{ii} ...
            * data.intWeightS(ii);
    end
    
    dataArray.sumWeight = data.intWeight;
    dataArray.sumWeightS = data.intWeightS;
    
else
    for ii = 1:T0
        dataArray.imCell{        ii}  = dataArray.imCell{        ii} ...
            + data.imCell{    ii};
        dataArray.maskCell{      ii}  = dataArray.maskCell{      ii} ...
            + data.maskCell{  ii};
        dataArray.imCellScale{   ii}  = dataArray.imCellScale{   ii} ...
            + data.imCellScale{   ii};
        dataArray.maskCellScale{ ii}  = dataArray.maskCellScale{ ii} ...
            + data.maskCellScale{ ii};
        dataArray.imCellNorm{    ii}  = dataArray.imCellNorm{    ii} ...
            + data.imCellNorm{ii} * data.intWeight(ii);
        dataArray.imCellNormScale{    ii}  = dataArray.imCellNormScale{    ii} ...
            + data.imCellNormScale{ii} * data.intWeightS(ii);
    end
    
    dataArray.sumWeight = dataArray.sumWeight + data.intWeight;
    dataArray.sumWeightS = dataArray.sumWeightS + data.intWeightS;
    
end

dataArray.towerCArray{   jj} = data.towerC;
dataArray.towerArray{    jj} = data.tower;
dataArray.towerNormArray{jj} = data.towerNorm;

dataArray.intWeightMinArray(jj) = min(data.intWeight);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% intNormalize
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function dataArray = intNormalize( dataArray, numCells )

dataArray.numCells = numCells;


dataArray.towerCArray       = dataArray.towerCArray(1:numCells);
dataArray.towerArray        = dataArray.towerArray(1:numCells);
dataArray.towerNormArray    = dataArray.towerNormArray(1:numCells);
dataArray.intWeightMinArray = dataArray.intWeightMinArray(1:numCells);
dataArray.cellArrayNum      = dataArray.cellArrayNum(1:numCells);






T0 = numel( dataArray.imCell );

dataArray.tower     = dataArray.tower    /dataArray.numCells;
dataArray.towerMask = dataArray.towerMask/dataArray.numCells;
dataArray.towerNorm = dataArray.towerNorm/dataArray.sumWeightMin;

for ii = 1:T0
    dataArray.imCellSum{    ii}  = dataArray.imCell{        ii}...
        /dataArray.numCells;
    dataArray.maskCell{      ii}  = dataArray.maskCell{     ii}...
        /dataArray.numCells;
    dataArray.imCellScale{   ii}  = dataArray.imCellScale{  ii}...
        /dataArray.numCells;
    dataArray.maskCellScale{ ii}  = dataArray.maskCellScale{ii}...
        /dataArray.numCells;
    dataArray.imCellNorm{    ii}  = dataArray.imCellNorm{   ii}...
        /dataArray.sumWeight(ii);
    dataArray.imCellNormScale{    ii}  = dataArray.imCellNormScale{   ii}...
        /dataArray.sumWeightS(ii);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% intInit
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function data = intInit( numCells )

data = [];
% Initialize the arrays for the images.
% imColorArray : (im tower) Colorized cropped cons image of a single cell
data.towerCArray = cell(1,numCells); %

%      imArray : Cell Array stack of Grayscale tower images that are mag = 1.
data.towerArray      = cell(1,numCells);
data.towerNormArray      = cell(1,numCells);
data.intWeightMinArray      = zeros( 1,numCells);

% cellArrayNum : Cell file number cell array
data.cellArrayNum = cell(1,numCells);


data.tower           = [];
data.towerNorm       = [];
data.towerMask       = [];

data.imCell          = [];
data.imCellNorm      = [];
data.maskCell        = [];

data.imCellScale     = [];
data.imCellNormScale = [];
data.maskCellScale   = [];

data.sumWeight       = [];
data.sumWeightMin    = [];

data.sumWeightS      = [];
data.sumWeightSMin   = [];

data.numCells        = numCells;

data.ssTot           = [0, 0];

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% intLoader
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ data, num_filename ] = intLoader( dirName, filename )

data = load( [dirName, filename] );

lpos =  max(find(filename == 'l'));
ppos =  min(find(filename == '.'));

if isempty( lpos ) || isempty( ppos )
    disp('Error in makeFrameStripeMosaic' );
    return;
else
    num_filename = floor(str2num(filename(lpos+1:ppos-1)));
end

end
