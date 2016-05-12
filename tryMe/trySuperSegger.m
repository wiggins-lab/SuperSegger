% Script to display the different superSegger methods
%% Get tryMe-file's location
FulllocationOfFile = mfilename('fullpath');
fileSepPosition = find(FulllocationOfFile==filesep,1,'last');
filepath = FulllocationOfFile ( 1 :fileSepPosition);

dirname = [filepath,'60mrnaCropped'];

%% Sample phase and a fluorescence image
imageFolder = [dirname,filesep,'raw_im',filesep];

% finds all phase and fluorescence images
phaseIm = dir([imageFolder,'*c1.tif']);
fluorIm = dir([imageFolder,'*c2.tif']);

% reads the first one
phase = imread([imageFolder,phaseIm(1).name]);
fluor = imread([imageFolder,fluorIm(1).name]);

figure(1);
clf;
imshow(phase);

figure(2);
clf;
imshow(fluor,[])

%% Different segmentation parameters
% Try different constants to select the most appropriate one
tryDifferentConstants([dirname,'/raw_im/']);


%% Set constants
% Load the constants and set the desired values

CONST = loadConstantsNN ('60XEclb',0);

% fit up to 5 foci in each cell
CONST.trackLoci.numSpots = [5]; % Max number of foci to fit in each fluorescence channel (default = [0 0])

% find the neighbors
CONST.trackOpti.NEIGHBOR_FLAG = true;

% not verbose state
CONST.parallel.verbose = 0;

%% Segment the data 
% Setting clean flag to true to resgment data
clean_flag = 1;
close all; % close all figures
BatchSuperSeggerOpti (dirname,1,clean_flag,CONST);

%% Load an individual cell file
cell_dir = [dirname,filesep,'xy1',filesep,'cell',filesep];
cellData = dir([cell_dir,'Cell*.mat']);
data = load([cell_dir,cellData(1).name]);


%% Cell phase image
% Show the phase image for frame 1
timeFrame = 1;
figure;
clf;
imshow(data.CellA{timeFrame}.phase,[]);

%% Cell Mask
% Show the cell mask for frame 1
mask = data.CellA{timeFrame}.mask;
figure;
clf;
imshow(mask);

%% Fluorescence image
% Show the fluorescence image for frame 1
figure;
clf;
imshow(cat(3,mask*0,ag(data.CellA{timeFrame}.fluor1),mask*0),[]);

%% Cell tower
% create a cell tower for the loaded cell.
im_tmp = makeFrameMosaic(data, CONST,3,1,3);

%% Kymograph
% create a kymograph for the loaded cell.
makeKymographC(data,1,CONST,1);

%% Clist
% Load the clist
clist = load([dirname,'/xy1/clist.mat']);

%% Histogram
% Plot the long axis at birth
clf;
gateHist(clist,10);

%% Gate and re-plot the histogram
% Take only cells for which the birth was observed and display the long
% axis at birth.

% Gate on quantity (4) which is the birth frame 
% and take only values from 2 - 100, i.e. discard cells that were born 
% in the first frame.
clistGated = gateMake(clist,4,[2 100]);

% plotting for the gated clist the long axis at birth
gateHist(clistGated,10);
